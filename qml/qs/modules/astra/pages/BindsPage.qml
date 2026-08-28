import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0

PageBase {
    id: root

    title: qsTr("Keybindings")

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Custom Keybinds")
        }

        // Add Keybind via DialogRowButton (always rounded with first: true, last: true)
        DialogRowButton {
            id: addBindBtn
            rootParent: root.modalOverlay
            first: true
            last: true
            icon: "add_circle"
            label: qsTr("Add Keybind")
            header: qsTr("Add Custom Keybind")
            acceptLabel: qsTr("Save Keybind")

            property string shortcutKey: ""
            property string selectedCategory: "Launch Application"
            property string selectedAction: "Run command"
            property string paramInput: ""
            property bool recording: false

            acceptAllowed: shortcutKey.trim() !== ""

            onAccepted: {
                if (shortcutKey.trim() !== "") {
                    let dsp = "exec";
                    let finalArgs = paramInput.trim();
                    if (selectedCategory === "Window Management") {
                        if (selectedAction === "Close window") dsp = "killactive";
                        else if (selectedAction === "Toggle floating") dsp = "togglefloating";
                        else if (selectedAction === "Toggle fullscreen") dsp = "fullscreen";
                        else if (selectedAction === "Pin window") dsp = "pin";
                    } else if (selectedCategory === "Workspace Navigation") {
                        if (selectedAction === "Switch workspace") dsp = "workspace";
                        else if (selectedAction === "Move to workspace") dsp = "movetoworkspace";
                    } else if (selectedCategory === "Custom Dispatcher") {
                        dsp = selectedAction;
                    }

                    FlightDeckWriter.addCustomBind(shortcutKey.trim(), dsp, finalArgs, true);
                    FlightDeckWriter.save();
                    shortcutKey = "";
                    paramInput = "";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Key Combination")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. SUPER + Return or SUPER + SHIFT + W")
                            text: addBindBtn.shortcutKey
                            onTextEdited: addBindBtn.shortcutKey = text
                        }

                        Button {
                            text: addBindBtn.recording ? qsTr("Stop") : qsTr("Record")
                            onClicked: {
                                addBindBtn.recording = !addBindBtn.recording;
                                if (addBindBtn.recording) addKeyListener.forceActiveFocus();
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Action Category")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    OptionRow {
                        first: true
                        last: false
                        title: qsTr("Category")
                        options: [
                            { label: qsTr("Launch Application"), value: "Launch Application" },
                            { label: qsTr("Window Management"), value: "Window Management" },
                            { label: qsTr("Workspace Navigation"), value: "Workspace Navigation" },
                            { label: qsTr("Custom Dispatcher"), value: "Custom Dispatcher" }
                        ]
                        currentValue: addBindBtn.selectedCategory
                        onOptionSelected: (val, lbl) => addBindBtn.selectedCategory = val
                    }

                    OptionRow {
                        first: false
                        last: true
                        title: qsTr("Action")
                        options: {
                            if (addBindBtn.selectedCategory === "Launch Application") {
                                return [{ label: qsTr("Run command (exec)"), value: "Run command" }];
                            } else if (addBindBtn.selectedCategory === "Window Management") {
                                return [
                                    { label: qsTr("Close window (killactive)"), value: "Close window" },
                                    { label: qsTr("Toggle floating (togglefloating)"), value: "Toggle floating" },
                                    { label: qsTr("Toggle fullscreen (fullscreen)"), value: "Toggle fullscreen" },
                                    { label: qsTr("Pin window (pin)"), value: "Pin window" }
                                ];
                            } else if (addBindBtn.selectedCategory === "Workspace Navigation") {
                                return [
                                    { label: qsTr("Switch workspace (workspace)"), value: "Switch workspace" },
                                    { label: qsTr("Move to workspace (movetoworkspace)"), value: "Move to workspace" }
                                ];
                            }
                            return [{ label: qsTr("Custom Dispatcher"), value: "exec" }];
                        }
                        currentValue: addBindBtn.selectedAction
                        onOptionSelected: (val, lbl) => addBindBtn.selectedAction = val
                    }

                    StyledText {
                        text: qsTr("Command / Arguments")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. grim -g ... or kitty or flatpak run ...")
                            text: addBindBtn.paramInput
                            onTextEdited: addBindBtn.paramInput = text
                        }

                        AppPickerPopup {
                            rootParent: root.modalOverlay
                            onAppSelected: (exec, name, icon) => {
                                addBindBtn.paramInput = exec;
                            }
                        }
                    }

                    Item {
                        id: addKeyListener
                        focus: addBindBtn.recording
                        Keys.onPressed: (event) => {
                            if (!addBindBtn.recording) return;
                            let k = event.key;
                            if (k === Qt.Key_Escape) {
                                addBindBtn.recording = false;
                                event.accepted = true;
                                return;
                            }
                            let mods = [];
                            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

                            let keyStr = "";
                            if (k >= Qt.Key_A && k <= Qt.Key_Z) keyStr = String.fromCharCode(k);
                            else if (k >= Qt.Key_0 && k <= Qt.Key_9) keyStr = String.fromCharCode(k);
                            else if (k === Qt.Key_Return || k === Qt.Key_Enter) keyStr = "Return";
                            else if (k === Qt.Key_Space) keyStr = "Space";
                            else if (k === Qt.Key_Tab) keyStr = "Tab";
                            else if (k === Qt.Key_Print) keyStr = "Print";
                            else keyStr = event.text.toUpperCase();

                            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);
                            if (keyStr !== "" && !isModKey) {
                                mods.push(keyStr);
                                addBindBtn.shortcutKey = mods.join(" + ");
                                addBindBtn.recording = false;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        // Each Custom Bind is its own DialogRowButton so editing morphs the entire button row!
        Repeater {
            model: FlightDeckWriter.customBinds

            delegate: DialogRowButton {
                id: editBindRow
                required property var modelData
                required property int index

                rootParent: root.modalOverlay
                first: index === 0
                last: index === FlightDeckWriter.customBinds.length - 1
                icon: "keyboard"

                label: editBindRow.modelData.key || qsTr("Keybind")
                subtext: (editBindRow.modelData.dispatcher || "exec") + (editBindRow.modelData.args ? ": " + editBindRow.modelData.args : "")

                header: qsTr("Edit Keybind")
                acceptLabel: qsTr("Save Changes")

                property string shortcutKey: editBindRow.modelData.key || ""
                property string paramInput: editBindRow.modelData.args || ""
                property string selectedCategory: {
                    let dsp = editBindRow.modelData.dispatcher || "exec";
                    if (dsp === "exec" || dsp === "exec_cmd") return "Launch Application";
                    if (dsp === "killactive" || dsp === "togglefloating" || dsp === "fullscreen" || dsp === "pin") return "Window Management";
                    if (dsp === "workspace" || dsp === "movetoworkspace") return "Workspace Navigation";
                    return "Custom Dispatcher";
                }
                property string selectedAction: {
                    let dsp = editBindRow.modelData.dispatcher || "exec";
                    if (dsp === "exec" || dsp === "exec_cmd") return "Run command";
                    if (dsp === "killactive") return "Close window";
                    if (dsp === "togglefloating") return "Toggle floating";
                    if (dsp === "fullscreen") return "Toggle fullscreen";
                    if (dsp === "pin") return "Pin window";
                    if (dsp === "workspace") return "Switch workspace";
                    if (dsp === "movetoworkspace") return "Move to workspace";
                    return dsp;
                }
                property bool recording: false

                acceptAllowed: shortcutKey.trim() !== ""

                onAccepted: {
                    if (shortcutKey.trim() !== "") {
                        let dsp = "exec";
                        let finalArgs = paramInput.trim();
                        if (selectedCategory === "Window Management") {
                            if (selectedAction === "Close window") dsp = "killactive";
                            else if (selectedAction === "Toggle floating") dsp = "togglefloating";
                            else if (selectedAction === "Toggle fullscreen") dsp = "fullscreen";
                            else if (selectedAction === "Pin window") dsp = "pin";
                        } else if (selectedCategory === "Workspace Navigation") {
                            if (selectedAction === "Switch workspace") dsp = "workspace";
                            else if (selectedAction === "Move to workspace") dsp = "movetoworkspace";
                        } else if (selectedCategory === "Custom Dispatcher") {
                            dsp = selectedAction;
                        }

                        FlightDeckWriter.updateCustomBind(editBindRow.index, {
                            "key": shortcutKey.trim(),
                            "dispatcher": dsp,
                            "args": finalArgs,
                            "unbindFirst": true
                        });
                        FlightDeckWriter.save();
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: editBindRow.open = true
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                FlightDeckWriter.removeCustomBind(editBindRow.index);
                                FlightDeckWriter.save();
                            }
                        }
                    }
                }

                content: Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: qsTr("Key Combination")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("e.g. SUPER + Return or SUPER + SHIFT + W")
                                text: editBindRow.shortcutKey
                                onTextEdited: editBindRow.shortcutKey = text
                            }

                            Button {
                                text: editBindRow.recording ? qsTr("Stop") : qsTr("Record")
                                onClicked: {
                                    editBindRow.recording = !editBindRow.recording;
                                    if (editBindRow.recording) editKeyListener.forceActiveFocus();
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Action Category")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        OptionRow {
                            first: true
                            last: false
                            title: qsTr("Category")
                            options: [
                                { label: qsTr("Launch Application"), value: "Launch Application" },
                                { label: qsTr("Window Management"), value: "Window Management" },
                                { label: qsTr("Workspace Navigation"), value: "Workspace Navigation" },
                                { label: qsTr("Custom Dispatcher"), value: "Custom Dispatcher" }
                            ]
                            currentValue: editBindRow.selectedCategory
                            onOptionSelected: (val, lbl) => editBindRow.selectedCategory = val
                        }

                        OptionRow {
                            first: false
                            last: true
                            title: qsTr("Action")
                            options: {
                                if (editBindRow.selectedCategory === "Launch Application") {
                                    return [{ label: qsTr("Run command (exec)"), value: "Run command" }];
                                } else if (editBindRow.selectedCategory === "Window Management") {
                                    return [
                                        { label: qsTr("Close window (killactive)"), value: "Close window" },
                                        { label: qsTr("Toggle floating (togglefloating)"), value: "Toggle floating" },
                                        { label: qsTr("Toggle fullscreen (fullscreen)"), value: "Toggle fullscreen" },
                                        { label: qsTr("Pin window (pin)"), value: "Pin window" }
                                    ];
                                } else if (editBindRow.selectedCategory === "Workspace Navigation") {
                                    return [
                                        { label: qsTr("Switch workspace (workspace)"), value: "Switch workspace" },
                                        { label: qsTr("Move to workspace (movetoworkspace)"), value: "Move to workspace" }
                                    ];
                                }
                                return [{ label: qsTr("Custom Dispatcher"), value: "exec" }];
                            }
                            currentValue: editBindRow.selectedAction
                            onOptionSelected: (val, lbl) => editBindRow.selectedAction = val
                        }

                        StyledText {
                            text: qsTr("Command / Arguments")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("e.g. grim -g ... or kitty")
                                text: editBindRow.paramInput
                                onTextEdited: editBindRow.paramInput = text
                            }

                            AppPickerPopup {
                            rootParent: root.modalOverlay
                                onAppSelected: (exec, name, icon) => {
                                    editBindRow.paramInput = exec;
                                }
                            }
                        }

                        Item {
                            id: editKeyListener
                            focus: editBindRow.recording
                            Keys.onPressed: (event) => {
                                if (!editBindRow.recording) return;
                                let k = event.key;
                                if (k === Qt.Key_Escape) {
                                    editBindRow.recording = false;
                                    event.accepted = true;
                                    return;
                                }
                                let mods = [];
                                if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                                if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                                if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                                if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

                                let keyStr = "";
                                if (k >= Qt.Key_A && k <= Qt.Key_Z) keyStr = String.fromCharCode(k);
                                else if (k >= Qt.Key_0 && k <= Qt.Key_9) keyStr = String.fromCharCode(k);
                                else if (k === Qt.Key_Return || k === Qt.Key_Enter) keyStr = "Return";
                                else if (k === Qt.Key_Space) keyStr = "Space";
                                else if (k === Qt.Key_Tab) keyStr = "Tab";
                                else if (k === Qt.Key_Print) keyStr = "Print";
                                else keyStr = event.text.toUpperCase();

                                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);
                                if (keyStr !== "" && !isModKey) {
                                    mods.push(keyStr);
                                    editBindRow.shortcutKey = mods.join(" + ");
                                    editBindRow.recording = false;
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Workspace Navigation Modifiers")
        }

        KeybindRow { first: true; isModifier: true; label: qsTr("Go to workspace"); varKey: "kbGoToWs" }
        KeybindRow { isModifier: true; label: qsTr("Go to workspace group"); varKey: "kbGoToWsGroup" }
        KeybindRow { isModifier: true; label: qsTr("Move window to workspace"); varKey: "kbMoveWinToWs" }
        KeybindRow { isModifier: true; label: qsTr("Move window to workspace group"); varKey: "kbMoveWinToWsGroup" }
        KeybindRow { label: qsTr("Next workspace"); varKey: "kbNextWs" }
        KeybindRow { last: true; label: qsTr("Previous workspace"); varKey: "kbPrevWs" }

        SectionHeader {
            text: qsTr("Window Group")
        }

        KeybindRow { first: true; label: qsTr("Cycle next in group"); varKey: "kbWindowGroupCycleNext" }
        KeybindRow { label: qsTr("Cycle previous in group"); varKey: "kbWindowGroupCyclePrev" }
        KeybindRow { label: qsTr("Ungroup"); varKey: "kbUngroup" }
        KeybindRow { last: true; label: qsTr("Toggle group"); varKey: "kbToggleGroup" }

        SectionHeader {
            text: qsTr("Window Management")
        }

        KeybindRow { first: true; label: qsTr("Move window"); varKey: "kbMoveWindow" }
        KeybindRow { label: qsTr("Resize window"); varKey: "kbResizeWindow" }
        KeybindRow { label: qsTr("Picture-in-picture"); varKey: "kbWindowPip" }
        KeybindRow { label: qsTr("Pin window"); varKey: "kbPinWindow" }
        KeybindRow { label: qsTr("Center window"); varKey: "kbCenterWindow" }
        KeybindRow { label: qsTr("Fullscreen"); varKey: "kbWindowFullscreen" }
        KeybindRow { label: qsTr("Maximized / Bordered Fullscreen"); varKey: "kbWindowBorderedFullscreen" }
        KeybindRow { last: true; label: qsTr("Close active window"); varKey: "kbCloseWindow" }

        SectionHeader {
            text: qsTr("Applications")
        }

        KeybindRow { first: true; label: qsTr("Terminal"); varKey: "kbTerminal" }
        KeybindRow { label: qsTr("Web Browser"); varKey: "kbBrowser" }
        KeybindRow { label: qsTr("Code / Text Editor"); varKey: "kbEditor" }
        KeybindRow { label: qsTr("File Explorer"); varKey: "kbFileExplorer" }
        KeybindRow { last: true; label: qsTr("Audio Settings"); varKey: "kbAudioSettings" }

        SectionHeader {
            text: qsTr("Utilities")
        }

        KeybindRow { first: true; label: qsTr("Full Screenshot"); varKey: "kbScreenshot" }
        KeybindRow { label: qsTr("Screenshot Region"); varKey: "kbScreenshotRegion" }
        KeybindRow { label: qsTr("Screenshot Freeze"); varKey: "kbScreenshotFreeze" }
        KeybindRow { label: qsTr("Screen Record"); varKey: "kbRecord" }
        KeybindRow { label: qsTr("Screen Record Sound"); varKey: "kbRecordSound" }
        KeybindRow { label: qsTr("Screen Record Region"); varKey: "kbRecordRegion" }
        KeybindRow { last: true; label: qsTr("Color Picker"); varKey: "kbColorPicker" }

        SectionHeader {
            text: qsTr("Media & Volume")
        }

        KeybindRow { first: true; label: qsTr("Media Play / Pause"); varKey: "kbMediaToggle" }
        KeybindRow { label: qsTr("Next Track"); varKey: "kbMediaNext" }
        KeybindRow { label: qsTr("Previous Track"); varKey: "kbMediaPrev" }
        KeybindRow { label: qsTr("Stop Media"); varKey: "kbMediaStop" }
        KeybindRow { last: true; label: qsTr("Mute Volume"); varKey: "kbVolumeMute" }

        SectionHeader {
            text: qsTr("Special Workspaces")
        }

        KeybindRow { first: true; label: qsTr("Toggle Special Workspace"); varKey: "kbSpecialWs" }
        KeybindRow { label: qsTr("System Monitor"); varKey: "kbSystemMonitorWs" }
        KeybindRow { label: qsTr("Music Workspace"); varKey: "kbMusicWs" }
        KeybindRow { label: qsTr("Communication"); varKey: "kbCommunicationWs" }
        KeybindRow { last: true; label: qsTr("Todo Workspace"); varKey: "kbTodoWs" }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
