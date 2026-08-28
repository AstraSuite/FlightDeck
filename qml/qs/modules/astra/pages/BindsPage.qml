pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Caelestia 1.0
import Helm.Hyprland 1.0

PageBase {
    id: root

    title: qsTr("Keybindings")

    property int editingIndex: -1
    property string editingKey: ""
    property string editingDispatcher: "exec"
    property string editingArgs: ""
    property string editingCategory: "Launch Application"
    property string editingBindType: "Normal"
    property string editingTriggerType: "key"

    Item {
        id: container
        anchors.fill: parent

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.cappedWidth
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: true
                text: qsTr("Custom Keybinds")
            }

            RowButton {
                first: true
                last: (AstraHelmWriter.customBinds || []).length === 0
                icon: "add_circle"
                label: qsTr("Add Keybind")
                onClicked: {
                    root.editingIndex = -1;
                    root.editingKey = "";
                    root.editingDispatcher = "exec";
                    root.editingArgs = "";
                    bindModal.open();
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
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                root.editingIndex = customRow.index;
                                root.editingKey = customRow.modelData.key || "";
                                root.editingDispatcher = customRow.modelData.dispatcher || "exec";
                                root.editingArgs = customRow.modelData.args || "";
                                bindModal.open();
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
            KeybindRow { label: qsTr("Center window"); varKey: "kbCenterWindow" }
            KeybindRow { last: true; label: qsTr("Toggle fullscreen"); varKey: "kbToggleFullscreen" }

            Item {
                Layout.preferredHeight: Tokens.padding.large
                Layout.fillWidth: true
            }
        }

        // Modal Overlay for Add / Edit Keybind
        Item {
            id: bindModal
            anchors.fill: parent
            z: 9999
            visible: false

            property string triggerType: "key"
            property string shortcutKey: ""
            property bool isManualEdit: false
            property string selectedCategory: "Launch Application"
            property string selectedAction: "Run command"
            property string paramInput: ""
            property string bindType: "Normal"
            property bool recording: false

            function open() {
                if (root.editingIndex >= 0) {
                    shortcutKey = root.editingKey;
                    paramInput = root.editingArgs;
                    let dsp = root.editingDispatcher;
                    if (dsp === "exec") {
                        selectedCategory = "Launch Application";
                        selectedAction = "Run command";
                    } else if (dsp === "killactive") {
                        selectedCategory = "Window Management";
                        selectedAction = "Close window";
                    } else if (dsp === "togglefloating") {
                        selectedCategory = "Window Management";
                        selectedAction = "Toggle floating";
                    } else if (dsp === "fullscreen") {
                        selectedCategory = "Window Management";
                        selectedAction = "Toggle fullscreen";
                    } else if (dsp === "pin") {
                        selectedCategory = "Window Management";
                        selectedAction = "Pin window";
                    } else if (dsp === "workspace") {
                        selectedCategory = "Workspace Navigation";
                        selectedAction = "Switch workspace";
                    } else if (dsp === "movetoworkspace") {
                        selectedCategory = "Workspace Navigation";
                        selectedAction = "Move to workspace";
                    } else {
                        selectedCategory = "Custom Dispatcher";
                        selectedAction = dsp;
                    }
                } else {
                    shortcutKey = "";
                    paramInput = "";
                    selectedCategory = "Launch Application";
                    selectedAction = "Run command";
                    bindType = "Normal";
                    triggerType = "key";
                }
                recording = false;
                isManualEdit = false;
                visible = true;
            }

            function close() {
                recording = false;
                visible = false;
            }

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                opacity: bindModal.visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: bindModal.close()
                }
            }

            // Modal Card
            StyledRect {
                id: card
                width: Math.min(520, root.width - 32)
                height: Math.min(620, root.height - 32)
                anchors.centerIn: parent

                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                scale: bindModal.visible ? 1.0 : 0.9
                opacity: bindModal.visible ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                }

                VerticalFadeFlickable {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    contentWidth: width
                    contentHeight: modalCol.implicitHeight

                    ColumnLayout {
                        id: modalCol
                        width: parent.width
                        spacing: Tokens.spacing.medium

                        // Top Header Bar
                        RowLayout {
                            Layout.fillWidth: true

                            TextButton {
                                text: qsTr("Cancel")
                                type: TextButton.Outlined
                                onClicked: bindModal.close()
                            }

                            StyledText {
                                text: root.editingIndex >= 0 ? qsTr("Edit Keybind") : qsTr("Add Keybind")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Button {
                                id: applyBtn
                                text: qsTr("Apply")
                                enabled: bindModal.shortcutKey.trim() !== ""

                                background: StyledRect {
                                    radius: Tokens.rounding.medium
                                    color: applyBtn.enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.12)
                                }

                                contentItem: StyledText {
                                    text: applyBtn.text
                                    font: Tokens.font.label.large
                                    color: applyBtn.enabled ? Colours.palette.m3onPrimary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    if (bindModal.shortcutKey.trim() !== "") {
                                        let dsp = "exec";
                                        let finalArgs = bindModal.paramInput.trim();
                                        if (bindModal.selectedCategory === "Window Management") {
                                            if (bindModal.selectedAction === "Close window") dsp = "killactive";
                                            else if (bindModal.selectedAction === "Toggle floating") dsp = "togglefloating";
                                            else if (bindModal.selectedAction === "Toggle fullscreen") dsp = "fullscreen";
                                            else if (bindModal.selectedAction === "Pin window") dsp = "pin";
                                        } else if (bindModal.selectedCategory === "Workspace Navigation") {
                                            if (bindModal.selectedAction === "Switch workspace") dsp = "workspace";
                                            else if (bindModal.selectedAction === "Move to workspace") dsp = "movetoworkspace";
                                        } else if (bindModal.selectedCategory === "Custom Dispatcher") {
                                            dsp = bindModal.selectedAction;
                                        }

                                        if (root.editingIndex >= 0) {
                                            AstraHelmWriter.updateCustomBind(root.editingIndex, {
                                                "key": bindModal.shortcutKey.trim(),
                                                "dispatcher": dsp,
                                                "args": finalArgs,
                                                "unbindFirst": true
                                            });
                                        } else {
                                            AstraHelmWriter.addCustomBind(bindModal.shortcutKey.trim(), dsp, finalArgs, true);
                                        }
                                        AstraHelmWriter.save();
                                        bindModal.close();
                                    }
                                }
                            }

                            IconButton {
                                icon: "close"
                                type: IconButton.Text
                                onClicked: bindModal.close()
                            }
                        }

                        // Trigger Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Trigger")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ConnectedRect {
                                first: true
                                last: true
                                Layout.fillWidth: true
                                implicitHeight: 56

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.medium

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            text: qsTr("Trigger")
                                            font: Tokens.font.body.small
                                            color: Colours.palette.m3onSurface
                                        }

                                        StyledText {
                                            text: qsTr("How this binding is activated")
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3outline
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4

                                        StyledRect {
                                            implicitWidth: 120
                                            implicitHeight: 36
                                            radius: Tokens.rounding.medium
                                            color: bindModal.triggerType === "key" ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

                                            StateLayer {
                                                anchors.fill: parent
                                                onClicked: bindModal.triggerType = "key"
                                            }

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: qsTr("Key combination")
                                                font: Tokens.font.label.small
                                                color: bindModal.triggerType === "key" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                            }
                                        }

                                        StyledRect {
                                            implicitWidth: 100
                                            implicitHeight: 36
                                            radius: Tokens.rounding.medium
                                            color: bindModal.triggerType === "mouse" ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh

                                            StateLayer {
                                                anchors.fill: parent
                                                onClicked: bindModal.triggerType = "mouse"
                                            }

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: qsTr("Mouse button")
                                                font: Tokens.font.label.small
                                                color: bindModal.triggerType === "mouse" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Key Combination Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Key Combination")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ConnectedRect {
                                first: true
                                last: false
                                Layout.fillWidth: true
                                implicitHeight: 56

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.medium

                                    StyledText {
                                        text: qsTr("Shortcut")
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3onSurface
                                        Layout.fillWidth: true
                                    }

                                    StyledText {
                                        text: bindModal.recording ? qsTr("Press keys now...") : (bindModal.shortcutKey || qsTr("(none)"))
                                        font: Tokens.font.body.small
                                        color: bindModal.recording ? Colours.palette.m3primary : Colours.palette.m3outline
                                    }

                                    Button {
                                        text: bindModal.recording ? qsTr("Stop") : qsTr("Record")
                                        onClicked: {
                                            bindModal.recording = !bindModal.recording;
                                            if (bindModal.recording) keyListener.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            ConnectedRect {
                                first: false
                                last: true
                                Layout.fillWidth: true
                                implicitHeight: bindModal.isManualEdit ? 96 : 50

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.small

                                    RowLayout {
                                        Layout.fillWidth: true

                                        StyledText {
                                            text: qsTr("Manual Edit")
                                            font: Tokens.font.body.small
                                            color: Colours.palette.m3onSurface
                                            Layout.fillWidth: true
                                        }

                                        IconButton {
                                            icon: bindModal.isManualEdit ? "expand_less" : "expand_more"
                                            type: IconButton.Text
                                            onClicked: bindModal.isManualEdit = !bindModal.isManualEdit
                                        }
                                    }

                                    StyledTextField {
                                        visible: bindModal.isManualEdit
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("e.g. SUPER, Return or CTRL_ALT, R")
                                        text: bindModal.shortcutKey
                                        onTextEdited: bindModal.shortcutKey = text
                                    }
                                }
                            }
                        }

                        // Action Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Action")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
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
                                currentValue: bindModal.selectedCategory
                                onOptionSelected: (val, lbl) => bindModal.selectedCategory = val
                            }

                            OptionRow {
                                first: false
                                last: true
                                title: qsTr("Action")
                                options: {
                                    if (bindModal.selectedCategory === "Launch Application") {
                                        return [
                                            { label: qsTr("Run command"), value: "Run command" }
                                        ];
                                    } else if (bindModal.selectedCategory === "Window Management") {
                                        return [
                                            { label: qsTr("Close window (killactive)"), value: "Close window" },
                                            { label: qsTr("Toggle floating (togglefloating)"), value: "Toggle floating" },
                                            { label: qsTr("Toggle fullscreen (fullscreen)"), value: "Toggle fullscreen" },
                                            { label: qsTr("Pin window (pin)"), value: "Pin window" }
                                        ];
                                    } else if (bindModal.selectedCategory === "Workspace Navigation") {
                                        return [
                                            { label: qsTr("Switch workspace (workspace)"), value: "Switch workspace" },
                                            { label: qsTr("Move to workspace (movetoworkspace)"), value: "Move to workspace" }
                                        ];
                                    }
                                    return [{ label: qsTr("Custom Dispatcher"), value: "exec" }];
                                }
                                currentValue: bindModal.selectedAction
                                onOptionSelected: (val, lbl) => bindModal.selectedAction = val
                            }
                        }

                        // Parameters Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Parameters")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ConnectedRect {
                                first: true
                                last: true
                                Layout.fillWidth: true
                                implicitHeight: 64

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.small

                                    StyledTextField {
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("Command or parameter argument...")
                                        text: bindModal.paramInput
                                        onTextEdited: bindModal.paramInput = text
                                    }

                                    IconButton {
                                        icon: "search"
                                        type: IconButton.Filled
                                        onClicked: appPicker.open()
                                    }
                                }
                            }
                        }

                        // Advanced Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Advanced")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            OptionRow {
                                first: true
                                last: true
                                title: qsTr("Bind type")
                                subtext: qsTr("Normal for most keybinds")
                                options: [
                                    { label: qsTr("Normal (bind)"), value: "Normal" },
                                    { label: qsTr("Locked (bindl - works when screen is locked)"), value: "Locked" },
                                    { label: qsTr("Repeat (binde - repeats on hold)"), value: "Repeat" },
                                    { label: qsTr("Non-consuming (bindn - passes through)"), value: "Non-consuming" }
                                ]
                                currentValue: bindModal.bindType
                                onOptionSelected: (val, lbl) => bindModal.bindType = val
                            }
                        }

                        // Keyboard capture item
                        Item {
                            id: keyListener
                            focus: bindModal.recording

                            Keys.onPressed: (event) => {
                                if (!bindModal.recording) return;
                                let k = event.key;
                                if (k === Qt.Key_Escape) {
                                    bindModal.recording = false;
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
                                    mods.push(keyStr);
                                    bindModal.shortcutKey = mods.join(" + ");
                                    bindModal.recording = false;
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        AppPickerDialog {
            id: appPicker
            onAppSelected: (exec, name, icon) => {
                if (bindModal.visible) {
                    bindModal.paramInput = exec;
                }
            }
        }
    }
}
