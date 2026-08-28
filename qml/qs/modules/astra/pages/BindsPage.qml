import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Keybindings")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Custom Shortcuts")
        }

        DialogRowButton {
            id: addBindBtn
            rootParent: root
            first: true
            last: (AstraHelmWriter.customBinds || []).length === 0
            icon: "add_circle"
            label: qsTr("Add Custom Shortcut")
            header: qsTr("Add New Keybind")
            acceptLabel: qsTr("Add Shortcut")

            property string bindKey: ""
            property string dispatcher: "exec"
            property string args: ""
            property bool recording: false

            acceptAllowed: bindKey.trim() !== ""

            onAccepted: {
                if (bindKey.trim() !== "") {
                    AstraHelmWriter.addCustomBind(bindKey.trim(), dispatcher, args.trim(), true);
                    AstraHelmWriter.save();
                    bindKey = "";
                    args = "";
                    dispatcher = "exec";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.small

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
                            placeholderText: qsTr("e.g. SUPER + Shift + D")
                            text: addBindBtn.bindKey
                            onTextEdited: addBindBtn.bindKey = text
                        }

                        StyledRect {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: Tokens.rounding.medium
                            color: addBindBtn.recording ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                            StateLayer {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addBindBtn.recording = !addBindBtn.recording;
                                    if (addBindBtn.recording) {
                                        bindFocus.forceActiveFocus();
                                    }
                                }
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: addBindBtn.recording ? "stop_circle" : "fiber_manual_record"
                                color: addBindBtn.recording ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Action Type (Dispatcher)")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    OptionRow {
                        first: true
                        last: true
                        title: qsTr("Dispatcher")
                        subtext: qsTr("Hyprland action to execute")
                        options: [
                            { label: qsTr("Launch Command (exec)"), value: "exec" },
                            { label: qsTr("Switch Workspace (workspace)"), value: "workspace" },
                            { label: qsTr("Move to Workspace (movetoworkspace)"), value: "movetoworkspace" },
                            { label: qsTr("Close Window (killactive)"), value: "killactive" },
                            { label: qsTr("Toggle Fullscreen (fullscreen)"), value: "fullscreen" },
                            { label: qsTr("Toggle Floating (togglefloating)"), value: "togglefloating" }
                        ]
                        currentValue: {
                            if (addBindBtn.dispatcher === "exec") return qsTr("Launch Command (exec)");
                            if (addBindBtn.dispatcher === "workspace") return qsTr("Switch Workspace (workspace)");
                            if (addBindBtn.dispatcher === "movetoworkspace") return qsTr("Move to Workspace (movetoworkspace)");
                            if (addBindBtn.dispatcher === "killactive") return qsTr("Close Window (killactive)");
                            if (addBindBtn.dispatcher === "fullscreen") return qsTr("Toggle Fullscreen (fullscreen)");
                            if (addBindBtn.dispatcher === "togglefloating") return qsTr("Toggle Floating (togglefloating)");
                            return addBindBtn.dispatcher;
                        }
                        onOptionSelected: (val, lbl) => {
                            addBindBtn.dispatcher = val;
                        }
                    }

                    StyledText {
                        text: addBindBtn.dispatcher === "exec" ? qsTr("Command to Execute") : qsTr("Dispatcher Argument (Optional)")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: addBindBtn.dispatcher === "exec" ? qsTr("e.g. kitty or flatpak run ...") : qsTr("e.g. 1 or special:magic")
                        text: addBindBtn.args
                        onTextEdited: addBindBtn.args = text
                    }

                    Item {
                        id: bindFocus
                        focus: addBindBtn.recording
                        property bool modifierOnly: false
                        property var lastMods: []

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
                            if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                                keyStr = String.fromCharCode(k);
                            } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                                keyStr = String.fromCharCode(k);
                            } else {
                                let map = {
                                    [Qt.Key_Return]: "Return",
                                    [Qt.Key_Enter]: "Return",
                                    [Qt.Key_Space]: "Space",
                                    [Qt.Key_Tab]: "Tab",
                                    [Qt.Key_Backtab]: "Tab",
                                    [Qt.Key_Backspace]: "Backspace",
                                    [Qt.Key_Minus]: "minus",
                                    [Qt.Key_Equal]: "equal",
                                    [Qt.Key_BracketLeft]: "bracketleft",
                                    [Qt.Key_BracketRight]: "bracketright",
                                    [Qt.Key_Semicolon]: "semicolon",
                                    [Qt.Key_Apostrophe]: "apostrophe",
                                    [Qt.Key_Grave]: "grave",
                                    [Qt.Key_Slash]: "slash",
                                    [Qt.Key_Period]: "period",
                                    [Qt.Key_Backslash]: "backslash",
                                    [Qt.Key_Comma]: "comma",
                                    [Qt.Key_Right]: "Right",
                                    [Qt.Key_Left]: "Left",
                                    [Qt.Key_Up]: "Up",
                                    [Qt.Key_Down]: "Down",
                                    [Qt.Key_Delete]: "Delete"
                                };
                                if (map[k] !== undefined) keyStr = map[k];
                                else keyStr = event.text.toUpperCase();
                            }

                            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                            if (keyStr !== "" && !isModKey) {
                                modifierOnly = false;
                                mods.push(keyStr);
                                addBindBtn.bindKey = mods.join(" + ");
                                addBindBtn.recording = false;
                                event.accepted = true;
                            } else if (isModKey) {
                                modifierOnly = true;
                                let modStr = "";
                                if (k === Qt.Key_Control) modStr = "CTRL";
                                else if (k === Qt.Key_Shift) modStr = "SHIFT";
                                else if (k === Qt.Key_Alt) modStr = "ALT";
                                else if (k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R) modStr = "SUPER";

                                if (!mods.includes(modStr) && modStr !== "") mods.push(modStr);
                                lastMods = mods;
                                event.accepted = true;
                            }
                        }

                        Keys.onReleased: (event) => {
                            if (!addBindBtn.recording) return;
                            let k = event.key;
                            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                            if (isModKey && modifierOnly && lastMods.length > 0) {
                                addBindBtn.bindKey = lastMods.join(" + ");
                                addBindBtn.recording = false;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: AstraHelmWriter.customBinds

            delegate: ConnectedRect {
                id: customRow
                required property var modelData
                required property int index

                Layout.fillWidth: true
                last: customRow.index === (AstraHelmWriter.customBinds.length - 1)
                implicitHeight: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    anchors.topMargin: Tokens.padding.medium
                    anchors.bottomMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: customRow.modelData.key || ""
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: (customRow.modelData.dispatcher || "exec") + (customRow.modelData.args ? ": " + customRow.modelData.args : "")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3primary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: {
                            AstraHelmWriter.removeCustomBind(customRow.index);
                            AstraHelmWriter.save();
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
        KeybindRow { label: qsTr("Fullscreen"); varKey: "kbWindowFullscreen" }
        KeybindRow { label: qsTr("Bordered fullscreen"); varKey: "kbWindowBorderedFullscreen" }
        KeybindRow { label: qsTr("Toggle floating"); varKey: "kbToggleWindowFloating" }
        KeybindRow { last: true; label: qsTr("Close window"); varKey: "kbCloseWindow" }

        SectionHeader {
            text: qsTr("Special Workspaces")
        }

        KeybindRow { first: true; label: qsTr("Special workspace toggle"); varKey: "kbSpecialWs" }
        KeybindRow { label: qsTr("System monitor"); varKey: "kbSystemMonitorWs" }
        KeybindRow { label: qsTr("Music"); varKey: "kbMusicWs" }
        KeybindRow { label: qsTr("Communication"); varKey: "kbCommunicationWs" }
        KeybindRow { last: true; label: qsTr("To-do"); varKey: "kbTodoWs" }

        SectionHeader {
            text: qsTr("Applications")
        }

        KeybindRow { first: true; label: qsTr("Terminal"); varKey: "kbTerminal" }
        KeybindRow { label: qsTr("Web Browser"); varKey: "kbBrowser" }
        KeybindRow { label: qsTr("Code Editor"); varKey: "kbEditor" }
        KeybindRow { label: qsTr("File Explorer"); varKey: "kbFileExplorer" }
        KeybindRow { last: true; label: qsTr("Audio Settings"); varKey: "kbAudioSettings" }

        SectionHeader {
            text: qsTr("Utilities & Session")
        }

        KeybindRow { first: true; label: qsTr("Screenshot Region"); varKey: "kbScreenshotRegion" }
        KeybindRow { label: qsTr("Screen Record"); varKey: "kbRecord" }
        KeybindRow { label: qsTr("Color Picker"); varKey: "kbColorPicker" }
        KeybindRow { label: qsTr("Clipboard History"); varKey: "kbClipboard" }
        KeybindRow { label: qsTr("Emoji Picker"); varKey: "kbEmoji" }
        KeybindRow { label: qsTr("App Launcher"); varKey: "kbLauncher" }
        KeybindRow { label: qsTr("Lock Screen"); varKey: "kbLock" }
        KeybindRow { last: true; label: qsTr("Session Menu"); varKey: "kbSession" }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
