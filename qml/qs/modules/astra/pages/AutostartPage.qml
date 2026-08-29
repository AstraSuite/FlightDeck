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
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Autostart Applications")

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Autostart Applications")
        }

        // Add Autostart Entry via DialogRowButton (always rounded with first: true, last: true)
        DialogRowButton {
            id: addEntryBtn
            rootParent: root.modalOverlay
            first: true
            last: true
            icon: "add_circle"
            label: qsTr("Add Autostart Entry")
            header: qsTr("Add Autostart Entry")
            acceptLabel: qsTr("Save Entry")

            openWidth: Math.min((rootParent ? rootParent.width : 540) * 0.9, 520)
            openHeight: Math.min((rootParent ? rootParent.height : 500) * 0.9, 470)

            property string targetCmd: ""
            property int targetDelay: 0
            property bool targetMinimize: false
            property string targetFlag: ""
            property bool targetOnReload: false

            acceptAllowed: targetCmd.trim() !== ""

            onOpenChanged: {
                if (open) {
                    targetCmd = "";
                    targetDelay = 0;
                    targetMinimize = false;
                    targetFlag = "";
                    targetOnReload = false;
                }
            }

            onAccepted: {
                if (targetCmd.trim() !== "") {
                    var finalCmd = AutostartManager.buildFinalCommand(targetCmd, targetDelay, targetMinimize, targetFlag);
                    AutostartManager.addCustomCommand(finalCmd, targetOnReload);
                    targetCmd = "";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.medium
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Command Line")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            id: cmdField
                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. waybar, nm-applet, solaar -w hide")
                            text: addEntryBtn.targetCmd
                            onTextEdited: {
                                addEntryBtn.targetCmd = text;
                                var info = AutostartManager.detectMinimizeFlags(text);
                                addEntryBtn.targetMinimize = info.hasFlag;
                                addEntryBtn.targetFlag = info.flag;
                            }
                        }

                        AppPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                            onAppSelected: (exec, name, icon) => {
                                addEntryBtn.targetCmd = exec;
                                var info = AutostartManager.detectMinimizeFlags(exec);
                                addEntryBtn.targetMinimize = info.hasFlag;
                                addEntryBtn.targetFlag = info.flag;
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Execution Options")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        Layout.topMargin: Tokens.spacing.extraSmall
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        StepperRow {
                            first: true
                            label: qsTr("Startup Delay")
                            subtext: qsTr("Wait seconds before executing command")
                            suffix: "s"
                            from: 0
                            to: 60
                            value: addEntryBtn.targetDelay
                            onMoved: val => addEntryBtn.targetDelay = Math.round(val)
                        }

                        ToggleRow {
                            text: qsTr("Minimize on Startup")
                            subtext: addEntryBtn.targetFlag ? qsTr("Applies flag: %1").arg(addEntryBtn.targetFlag) : qsTr("Starts application hidden or in system tray")
                            checked: addEntryBtn.targetMinimize
                            onToggled: {
                                addEntryBtn.targetMinimize = checked;
                                if (checked) {
                                    if (addEntryBtn.targetCmd.trim() !== "") {
                                        var info = AutostartManager.detectMinimizeFlags(addEntryBtn.targetCmd);
                                        var flag = addEntryBtn.targetFlag || info.flag || "--minimized";
                                        if (!info.hasFlag) {
                                            addEntryBtn.targetCmd = (info.cleanCmd || addEntryBtn.targetCmd.trim()) + " " + flag;
                                        }
                                    }
                                } else {
                                    if (addEntryBtn.targetCmd.trim() !== "") {
                                        var info2 = AutostartManager.detectMinimizeFlags(addEntryBtn.targetCmd);
                                        if (info2.hasFlag) {
                                            addEntryBtn.targetCmd = info2.cleanCmd;
                                        }
                                    }
                                }
                            }
                        }

                        ToggleRow {
                            last: true
                            text: qsTr("Run on Reload")
                            subtext: qsTr("Re-run every time Hyprland config reloads")
                            checked: addEntryBtn.targetOnReload
                            onToggled: addEntryBtn.targetOnReload = checked
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Startup Commands (%1)").arg(AutostartManager.activeCommands.length)
        }

        // Each Startup Command is its own DialogRowButton so editing morphs the entire button row!
        Repeater {
            model: AutostartManager.activeCommands

            delegate: DialogRowButton {
                id: editCmdRow
                required property var modelData
                required property int index

                readonly property bool isReadOnly: editCmdRow.modelData ? (editCmdRow.modelData.isReadOnly || false) : false

                rootParent: root.modalOverlay
                first: index === 0
                last: index === AutostartManager.activeCommands.length - 1
                icon: editCmdRow.isReadOnly ? "lock" : "play_arrow"
                openAllowed: !editCmdRow.isReadOnly
                rowDisabled: editCmdRow.isReadOnly

                label: editCmdRow.modelData ? (editCmdRow.modelData.cleanCmd || editCmdRow.modelData.command || editCmdRow.modelData.rawCommand || editCmdRow.modelData) : ""
                subtext: {
                    if (!editCmdRow.modelData) return qsTr("Runs once at session startup");
                    if (editCmdRow.isReadOnly) {
                        return qsTr("System autostart (read-only)");
                    }
                    var isReload = editCmdRow.modelData.onReload ?? false;
                    var delay = editCmdRow.modelData.delay ?? 0;
                    var isMinimized = editCmdRow.modelData.hasMinimizeFlag ?? false;

                    var baseText = isReload ? qsTr("Runs on startup and reload") : qsTr("Runs once at session startup");
                    if (delay > 0) {
                        baseText += qsTr(" (after %1s delay)").arg(delay);
                    }
                    if (isMinimized) {
                        baseText += " • " + qsTr("Starts hidden to tray");
                    }
                    return baseText;
                }

                header: qsTr("Edit Autostart Entry")
                acceptLabel: qsTr("Save Changes")

                openWidth: Math.min((rootParent ? rootParent.width : 540) * 0.9, 520)
                openHeight: Math.min((rootParent ? rootParent.height : 500) * 0.9, 470)

                property string targetCmd: editCmdRow.modelData ? (editCmdRow.modelData.command || editCmdRow.modelData.rawCommand || editCmdRow.modelData) : ""
                property int targetDelay: editCmdRow.modelData ? (editCmdRow.modelData.delay || 0) : 0
                property bool targetMinimize: editCmdRow.modelData ? (editCmdRow.modelData.hasMinimizeFlag || false) : false
                property string targetFlag: editCmdRow.modelData ? (editCmdRow.modelData.minimizeFlag || "") : ""
                property bool targetOnReload: editCmdRow.modelData ? (editCmdRow.modelData.onReload || false) : false

                acceptAllowed: targetCmd.trim() !== ""

                onOpenChanged: {
                    if (open && editCmdRow.modelData) {
                        var parsed = AutostartManager.parseCommand(editCmdRow.modelData.rawCommand || editCmdRow.modelData.command || editCmdRow.modelData, editCmdRow.modelData.onReload ?? false, editCmdRow.isReadOnly);
                        targetCmd = parsed.command;
                        targetDelay = parsed.delay;
                        targetMinimize = parsed.hasMinimizeFlag;
                        targetFlag = parsed.minimizeFlag;
                        targetOnReload = parsed.onReload;
                    }
                }

                onAccepted: {
                    if (targetCmd.trim() !== "") {
                        var finalCmd = AutostartManager.buildFinalCommand(targetCmd, targetDelay, targetMinimize, targetFlag);
                        AutostartManager.updateCommand(editCmdRow.index, finalCmd, targetOnReload);
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            visible: !editCmdRow.isReadOnly
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                AutostartManager.removeCommand(editCmdRow.index);
                            }
                        }
                    }
                }

                content: Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.medium
                        Layout.fillWidth: true

                        StyledText {
                            text: qsTr("Command Line")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Command line")
                                text: editCmdRow.targetCmd
                                onTextEdited: {
                                    editCmdRow.targetCmd = text;
                                    var info = AutostartManager.detectMinimizeFlags(text);
                                    editCmdRow.targetMinimize = info.hasFlag;
                                    editCmdRow.targetFlag = info.flag;
                                }
                            }

                            AppPickerPopup {
                                Layout.alignment: Qt.AlignVCenter
                                rootParent: root.modalOverlay
                                onAppSelected: (exec, name, icon) => {
                                    editCmdRow.targetCmd = exec;
                                    var info = AutostartManager.detectMinimizeFlags(exec);
                                    editCmdRow.targetMinimize = info.hasFlag;
                                    editCmdRow.targetFlag = info.flag;
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Execution Options")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.topMargin: Tokens.spacing.extraSmall
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            StepperRow {
                                first: true
                                label: qsTr("Startup Delay")
                                subtext: qsTr("Wait seconds before executing command")
                                suffix: "s"
                                from: 0
                                to: 60
                                value: editCmdRow.targetDelay
                                onMoved: val => editCmdRow.targetDelay = Math.round(val)
                            }

                            ToggleRow {
                                text: qsTr("Minimize on Startup")
                                subtext: editCmdRow.targetFlag ? qsTr("Applies flag: %1").arg(editCmdRow.targetFlag) : qsTr("Starts application hidden or in system tray")
                                checked: editCmdRow.targetMinimize
                                onToggled: {
                                    editCmdRow.targetMinimize = checked;
                                    if (checked) {
                                        if (editCmdRow.targetCmd.trim() !== "") {
                                            var info = AutostartManager.detectMinimizeFlags(editCmdRow.targetCmd);
                                            var flag = editCmdRow.targetFlag || info.flag || "--minimized";
                                            if (!info.hasFlag) {
                                                editCmdRow.targetCmd = (info.cleanCmd || editCmdRow.targetCmd.trim()) + " " + flag;
                                            }
                                        }
                                    } else {
                                        if (editCmdRow.targetCmd.trim() !== "") {
                                            var info2 = AutostartManager.detectMinimizeFlags(editCmdRow.targetCmd);
                                            if (info2.hasFlag) {
                                                editCmdRow.targetCmd = info2.cleanCmd;
                                            }
                                        }
                                    }
                                }
                            }

                            ToggleRow {
                                last: true
                                text: qsTr("Run on Reload")
                                subtext: qsTr("Re-run every time Hyprland config reloads")
                                checked: editCmdRow.targetOnReload
                                onToggled: editCmdRow.targetOnReload = checked
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: AutostartManager.activeCommands.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No autostart commands configured.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}

