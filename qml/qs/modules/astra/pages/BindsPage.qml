pragma ComponentBehavior: Bound

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

    title: qsTr("Keybinds")

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Custom Keybinds")
        }

        // Add Keybind via DialogRowButton (connected to custom keybinds list below)
        DialogRowButton {
            id: addBindBtn
            rootParent: root.modalOverlay
            first: true
            last: FlightDeckWriter.customBinds.length === 0
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

            onOpenChanged: {
                if (!open) {
                    recording = false;
                    HyprlandState.stopCapture();
                }
            }

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

                        ButtonBase {
                            id: addRecBtn
                            implicitHeight: 40
                            implicitWidth: 96
                            radius: Tokens.rounding.medium
                            color: addBindBtn.recording ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                            StateLayer {
                                anchors.fill: parent
                                onClicked: {
                                    addBindBtn.recording = !addBindBtn.recording;
                                    if (addBindBtn.recording) {
                                        addKeyListener.forceActiveFocus();
                                        HyprlandState.startCapture();
                                    } else {
                                        HyprlandState.stopCapture();
                                    }
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.extraSmall

                                MaterialIcon {
                                    text: addBindBtn.recording ? "stop" : "fiber_manual_record"
                                    color: addBindBtn.recording ? Colours.palette.m3onPrimary : Colours.palette.m3error
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    text: addBindBtn.recording ? qsTr("Stop") : qsTr("Record")
                                    font: Tokens.font.label.medium
                                    color: addBindBtn.recording ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                }
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Action Category")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        SelectRow {
                            first: true
                            last: false
                            label: qsTr("Category")
                            subtext: qsTr("Action type classification")
                            menuItems: [
                                MenuItem { text: qsTr("Launch Application"); onClicked: { addBindBtn.selectedCategory = "Launch Application"; addBindBtn.selectedAction = "Run command"; } },
                                MenuItem { text: qsTr("Window Management"); onClicked: { addBindBtn.selectedCategory = "Window Management"; addBindBtn.selectedAction = "Close window"; } },
                                MenuItem { text: qsTr("Workspace Navigation"); onClicked: { addBindBtn.selectedCategory = "Workspace Navigation"; addBindBtn.selectedAction = "Switch workspace"; } },
                                MenuItem { text: qsTr("Custom Dispatcher"); onClicked: { addBindBtn.selectedCategory = "Custom Dispatcher"; addBindBtn.selectedAction = "exec"; } }
                            ]
                            active: {
                                for (var i = 0; i < menuItems.length; i++) {
                                    if (menuItems[i].text === addBindBtn.selectedCategory) return menuItems[i];
                                }
                                return menuItems[0] || null;
                            }
                        }

                        SelectRow {
                            first: false
                            last: true
                            label: qsTr("Action")
                            subtext: qsTr("Specific dispatcher to trigger")
                            menuItems: {
                                var items = [];
                                var cat = addBindBtn.selectedCategory;
                                if (cat === "Launch Application") {
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Run command") + '"; onClicked: addBindBtn.selectedAction = "Run command" }', addBindBtn));
                                } else if (cat === "Window Management") {
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Close window") + '"; onClicked: addBindBtn.selectedAction = "Close window" }', addBindBtn));
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Toggle floating") + '"; onClicked: addBindBtn.selectedAction = "Toggle floating" }', addBindBtn));
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Toggle fullscreen") + '"; onClicked: addBindBtn.selectedAction = "Toggle fullscreen" }', addBindBtn));
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Pin window") + '"; onClicked: addBindBtn.selectedAction = "Pin window" }', addBindBtn));
                                } else if (cat === "Workspace Navigation") {
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Switch workspace") + '"; onClicked: addBindBtn.selectedAction = "Switch workspace" }', addBindBtn));
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Move to workspace") + '"; onClicked: addBindBtn.selectedAction = "Move to workspace" }', addBindBtn));
                                } else {
                                    items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + addBindBtn.selectedAction + '"; onClicked: {} }', addBindBtn));
                                }
                                return items;
                            }
                            active: {
                                for (var i = 0; i < menuItems.length; i++) {
                                    if (menuItems[i].text === addBindBtn.selectedAction) return menuItems[i];
                                }
                                return menuItems[0] || null;
                            }
                        }
                    }

                    StyledText {
                        visible: addBindBtn.selectedCategory === "Launch Application" || addBindBtn.selectedCategory === "Custom Dispatcher"
                        text: addBindBtn.selectedCategory === "Launch Application" ? qsTr("Command to Run") : qsTr("Dispatcher Arguments")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: addBindBtn.selectedCategory === "Launch Application" || addBindBtn.selectedCategory === "Custom Dispatcher"
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: addBindBtn.selectedCategory === "Launch Application" ? qsTr("e.g. firefox, alacritty, or custom script") : qsTr("Optional arguments for dispatcher")
                            text: addBindBtn.paramInput
                            onTextEdited: addBindBtn.paramInput = text
                        }

                        AppPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                            visible: addBindBtn.selectedCategory === "Launch Application"
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
                            let mods = [];
                            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

                            if (k === Qt.Key_Escape) {
                                if (mods.length === 0) {
                                    addBindBtn.recording = false;
                                    HyprlandState.stopCapture();
                                    event.accepted = true;
                                    return;
                                }
                            }

                            let keyStr = "";
                            if (k >= Qt.Key_A && k <= Qt.Key_Z) keyStr = String.fromCharCode(k);
                            else if (k >= Qt.Key_0 && k <= Qt.Key_9) keyStr = String.fromCharCode(k);
                            else {
                                let map = {
                                    [Qt.Key_Escape]: "escape",
                                    [Qt.Key_Return]: "Return",
                                    [Qt.Key_Enter]: "Return",
                                    [Qt.Key_Space]: "Space",
                                    [Qt.Key_Tab]: "Tab",
                                    [Qt.Key_Backtab]: "Tab",
                                    [Qt.Key_Backspace]: "Backspace",
                                    [Qt.Key_Minus]: "Minus",
                                    [Qt.Key_Equal]: "Equal",
                                    [Qt.Key_BracketLeft]: "bracketleft",
                                    [Qt.Key_BracketRight]: "bracketright",
                                    [Qt.Key_Semicolon]: "semicolon",
                                    [Qt.Key_Apostrophe]: "apostrophe",
                                    [Qt.Key_Grave]: "grave",
                                    [Qt.Key_Slash]: "slash",
                                    [Qt.Key_Period]: "Period",
                                    [Qt.Key_Comma]: "Comma",
                                    [Qt.Key_Backslash]: "Backslash",
                                    [Qt.Key_Right]: "Right",
                                    [Qt.Key_Left]: "Left",
                                    [Qt.Key_Up]: "Up",
                                    [Qt.Key_Down]: "Down",
                                    [Qt.Key_PageUp]: "Page_Up",
                                    [Qt.Key_PageDown]: "Page_Down",
                                    [Qt.Key_Print]: "Print",
                                    [Qt.Key_Delete]: "Delete"
                                };
                                if (map[k] !== undefined) keyStr = map[k];
                                else keyStr = event.text.toUpperCase();
                            }

                            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);
                            if (keyStr !== "" && !isModKey) {
                                mods.push(keyStr);
                                addBindBtn.shortcutKey = mods.join(" + ");
                                addBindBtn.recording = false;
                                HyprlandState.stopCapture();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        // Each Custom Bind is its own DialogRowButton
        Repeater {
            model: FlightDeckWriter.customBinds

            delegate: DialogRowButton {
                id: editBindRow
                required property var modelData
                required property int index

                rootParent: root.modalOverlay
                first: false
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

                onOpenChanged: {
                    if (open) {
                        recording = false;
                        shortcutKey = editBindRow.modelData.key || "";
                        paramInput = editBindRow.modelData.args || "";
                    } else {
                        recording = false;
                        HyprlandState.stopCapture();
                    }
                }

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
                        id: editBindCol
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

                            ButtonBase {
                                id: editRecBtn
                                implicitHeight: 40
                                implicitWidth: 96
                                radius: Tokens.rounding.medium
                                color: editBindRow.recording ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                                StateLayer {
                                    anchors.fill: parent
                                    onClicked: {
                                        editBindRow.recording = !editBindRow.recording;
                                        if (editBindRow.recording) {
                                            editKeyListener.forceActiveFocus();
                                            HyprlandState.startCapture();
                                        } else {
                                            HyprlandState.stopCapture();
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: Tokens.spacing.extraSmall

                                    MaterialIcon {
                                        text: editBindRow.recording ? "stop" : "fiber_manual_record"
                                        color: editBindRow.recording ? Colours.palette.m3onPrimary : Colours.palette.m3error
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    StyledText {
                                        text: editBindRow.recording ? qsTr("Stop") : qsTr("Record")
                                        font: Tokens.font.label.medium
                                        color: editBindRow.recording ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                    }
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Action Category")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            SelectRow {
                                first: true
                                last: false
                                label: qsTr("Category")
                                subtext: qsTr("Action type classification")
                                menuItems: [
                                    MenuItem { text: qsTr("Launch Application"); onClicked: { editBindRow.selectedCategory = "Launch Application"; editBindRow.selectedAction = "Run command"; } },
                                    MenuItem { text: qsTr("Window Management"); onClicked: { editBindRow.selectedCategory = "Window Management"; editBindRow.selectedAction = "Close window"; } },
                                    MenuItem { text: qsTr("Workspace Navigation"); onClicked: { editBindRow.selectedCategory = "Workspace Navigation"; editBindRow.selectedAction = "Switch workspace"; } },
                                    MenuItem { text: qsTr("Custom Dispatcher"); onClicked: { editBindRow.selectedCategory = "Custom Dispatcher"; editBindRow.selectedAction = "exec"; } }
                                ]
                                active: {
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].text === editBindRow.selectedCategory) return menuItems[i];
                                    }
                                    return menuItems[0] || null;
                                }
                            }

                            SelectRow {
                                first: false
                                last: true
                                label: qsTr("Action")
                                subtext: qsTr("Specific dispatcher to trigger")
                                menuItems: {
                                    var items = [];
                                    var cat = editBindRow.selectedCategory;
                                    if (cat === "Launch Application") {
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Run command") + '"; onClicked: editBindRow.selectedAction = "Run command" }', editBindRow));
                                    } else if (cat === "Window Management") {
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Close window") + '"; onClicked: editBindRow.selectedAction = "Close window" }', editBindRow));
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Toggle floating") + '"; onClicked: editBindRow.selectedAction = "Toggle floating" }', editBindRow));
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Toggle fullscreen") + '"; onClicked: editBindRow.selectedAction = "Toggle fullscreen" }', editBindRow));
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Pin window") + '"; onClicked: editBindRow.selectedAction = "Pin window" }', editBindRow));
                                    } else if (cat === "Workspace Navigation") {
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Switch workspace") + '"; onClicked: editBindRow.selectedAction = "Switch workspace" }', editBindRow));
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + qsTr("Move to workspace") + '"; onClicked: editBindRow.selectedAction = "Move to workspace" }', editBindRow));
                                    } else {
                                        items.push(Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + editBindRow.selectedAction + '"; onClicked: {} }', editBindRow));
                                    }
                                    return items;
                                }
                                active: {
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].text === editBindRow.selectedAction) return menuItems[i];
                                    }
                                    return menuItems[0] || null;
                                }
                            }
                        }

                        StyledText {
                            visible: editBindRow.selectedCategory === "Launch Application" || editBindRow.selectedCategory === "Custom Dispatcher"
                            text: editBindRow.selectedCategory === "Launch Application" ? qsTr("Command to Run") : qsTr("Dispatcher Arguments")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: editBindRow.selectedCategory === "Launch Application" || editBindRow.selectedCategory === "Custom Dispatcher"
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: editBindRow.selectedCategory === "Launch Application" ? qsTr("e.g. firefox, alacritty, or custom script") : qsTr("Optional arguments for dispatcher")
                                text: editBindRow.paramInput
                                onTextEdited: editBindRow.paramInput = text
                            }

                            AppPickerPopup {
                                Layout.alignment: Qt.AlignVCenter
                                rootParent: root.modalOverlay
                                visible: editBindRow.selectedCategory === "Launch Application"
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
                                let mods = [];
                                if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
                                if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
                                if (event.modifiers & Qt.AltModifier) mods.push("ALT");
                                if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

                                if (k === Qt.Key_Escape) {
                                    if (mods.length === 0) {
                                        editBindRow.recording = false;
                                        HyprlandState.stopCapture();
                                        event.accepted = true;
                                        return;
                                    }
                                }

                                let keyStr = "";
                                if (k >= Qt.Key_A && k <= Qt.Key_Z) keyStr = String.fromCharCode(k);
                                else if (k >= Qt.Key_0 && k <= Qt.Key_9) keyStr = String.fromCharCode(k);
                                else {
                                    let map = {
                                        [Qt.Key_Escape]: "escape",
                                        [Qt.Key_Return]: "Return",
                                        [Qt.Key_Enter]: "Return",
                                        [Qt.Key_Space]: "Space",
                                        [Qt.Key_Tab]: "Tab",
                                        [Qt.Key_Backtab]: "Tab",
                                        [Qt.Key_Backspace]: "Backspace",
                                        [Qt.Key_Minus]: "Minus",
                                        [Qt.Key_Equal]: "Equal",
                                        [Qt.Key_BracketLeft]: "bracketleft",
                                        [Qt.Key_BracketRight]: "bracketright",
                                        [Qt.Key_Semicolon]: "semicolon",
                                        [Qt.Key_Apostrophe]: "apostrophe",
                                        [Qt.Key_Grave]: "grave",
                                        [Qt.Key_Slash]: "slash",
                                        [Qt.Key_Period]: "Period",
                                        [Qt.Key_Comma]: "Comma",
                                        [Qt.Key_Backslash]: "Backslash",
                                        [Qt.Key_Right]: "Right",
                                        [Qt.Key_Left]: "Left",
                                        [Qt.Key_Up]: "Up",
                                        [Qt.Key_Down]: "Down",
                                        [Qt.Key_PageUp]: "Page_Up",
                                        [Qt.Key_PageDown]: "Page_Down",
                                        [Qt.Key_Print]: "Print",
                                        [Qt.Key_Delete]: "Delete"
                                    };
                                    if (map[k] !== undefined) keyStr = map[k];
                                    else keyStr = event.text.toUpperCase();
                                }

                                let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);
                                if (keyStr !== "" && !isModKey) {
                                    mods.push(keyStr);
                                    editBindRow.shortcutKey = mods.join(" + ");
                                    editBindRow.recording = false;
                                    HyprlandState.stopCapture();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: (CaelestiaVars.keybindSections && CaelestiaVars.keybindSections.length > 0) ? CaelestiaVars.keybindSections : HyprlandSchema.keybindSections

            delegate: ColumnLayout {
                id: secCol
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: secCol.modelData.label || ""
                }

                Repeater {
                    id: optRepeater
                    model: secCol.modelData.options

                    delegate: KeybindRow {
                        id: kbRow
                        required property var modelData
                        required property int index

                        rootParent: root.modalOverlay
                        first: kbRow.index === 0
                        last: kbRow.index === (secCol.modelData.options ? secCol.modelData.options.length - 1 : -1)
                        isModifier: kbRow.modelData.type === "keybind_modifier" || kbRow.modelData.type === "modifier"
                        label: kbRow.modelData.label || kbRow.modelData.key
                        varKey: kbRow.modelData.key
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
