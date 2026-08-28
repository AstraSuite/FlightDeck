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

            property string targetCmd: ""

            acceptAllowed: targetCmd.trim() !== ""

            onAccepted: {
                if (targetCmd.trim() !== "") {
                    AutostartManager.addCustomCommand(targetCmd.trim());
                    targetCmd = "";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Command Line")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: qsTr("Pick an installed app or type any shell command. Hyprland passes this to /bin/sh -c.")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. waybar, nm-applet, solaar -w hide")
                            text: addEntryBtn.targetCmd
                            onTextEdited: addEntryBtn.targetCmd = text
                        }

                        AppPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                            onAppSelected: (exec, name, icon) => {
                                addEntryBtn.targetCmd = exec;
                            }
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
                required property string modelData
                required property int index

                rootParent: root.modalOverlay
                first: index === 0
                last: index === AutostartManager.activeCommands.length - 1
                icon: "play_arrow"

                label: editCmdRow.modelData
                subtext: qsTr("Runs once at session startup")

                header: qsTr("Edit Autostart Entry")
                acceptLabel: qsTr("Save Changes")

                property string targetCmd: editCmdRow.modelData

                acceptAllowed: targetCmd.trim() !== ""

                onAccepted: {
                    if (targetCmd.trim() !== "") {
                        AutostartManager.updateCommand(editCmdRow.index, targetCmd.trim());
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: editCmdRow.open = true
                        }

                        IconButton {
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

                        StyledText {
                            text: qsTr("Command Line")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: qsTr("Shell command executed during Hyprland desktop startup.")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Command line")
                                text: editCmdRow.targetCmd
                                onTextEdited: editCmdRow.targetCmd = text
                            }

                            AppPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                                onAppSelected: (exec, name, icon) => {
                                    editCmdRow.targetCmd = exec;
                                }
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
