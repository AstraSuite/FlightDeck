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
import Helm.Managers 1.0

PageBase {
    id: root

    title: qsTr("Autostart Applications")

    property int editingIndex: -1
    property string editingCmd: ""
    property bool editingOnReload: false

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
                text: qsTr("Autostart Applications")
            }

            // Add Autostart Entry button
            RowButton {
                first: true
                last: (AutostartManager.activeCommands || []).length === 0
                icon: "add_circle"
                label: qsTr("Add Autostart Entry")
                onClicked: {
                    root.editingIndex = -1;
                    root.editingCmd = "";
                    root.editingOnReload = false;
                    entryModal.open();
                }
            }

            SectionHeader {
                text: qsTr("Once at startup (%1)").arg(AutostartManager.activeCommands.length)
            }

            Repeater {
                model: AutostartManager.activeCommands

                delegate: ConnectedRect {
                    id: cmdRow
                    required property string modelData
                    required property int index

                    first: index === 0
                    last: index === AutostartManager.activeCommands.length - 1
                    Layout.fillWidth: true
                    implicitHeight: 54

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "play_arrow"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: cmdRow.modelData
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: qsTr("Once at startup")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                root.editingIndex = cmdRow.index;
                                root.editingCmd = cmdRow.modelData;
                                root.editingOnReload = false;
                                entryModal.open();
                            }
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                AutostartManager.removeCommand(cmdRow.index);
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

        // Add / Edit Modal Overlay
        Item {
            id: entryModal
            anchors.fill: parent
            z: 9999
            visible: false

            property string cmdText: ""
            property bool onReload: false

            function open() {
                if (root.editingIndex >= 0) {
                    cmdText = root.editingCmd;
                    onReload = root.editingOnReload;
                } else {
                    cmdText = "";
                    onReload = false;
                }
                visible = true;
                cmdInput.forceActiveFocus();
            }

            function close() {
                visible = false;
            }

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                opacity: entryModal.visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: entryModal.close()
                }
            }

            // Card
            StyledRect {
                id: modalContent
                width: Math.min(500, root.width - 32)
                height: Math.min(460, root.height - 32)
                anchors.centerIn: parent

                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                scale: entryModal.visible ? 1.0 : 0.9
                opacity: entryModal.visible ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    // Header Bar
                    RowLayout {
                        Layout.fillWidth: true

                        TextButton {
                            text: qsTr("Cancel")
                            type: TextButton.Outlined
                            onClicked: entryModal.close()
                        }

                        StyledText {
                            text: root.editingIndex >= 0 ? qsTr("Edit Autostart Entry") : qsTr("Add Autostart Entry")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Button {
                            id: applyBtn
                            text: qsTr("Apply")
                            enabled: entryModal.cmdText.trim() !== ""

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
                                if (entryModal.cmdText.trim() !== "") {
                                    if (root.editingIndex >= 0) {
                                        AutostartManager.updateCommand(root.editingIndex, entryModal.cmdText.trim());
                                    } else {
                                        AutostartManager.addCustomCommand(entryModal.cmdText.trim());
                                    }
                                    entryModal.close();
                                }
                            }
                        }

                        IconButton {
                            icon: "close"
                            type: IconButton.Text
                            onClicked: entryModal.close()
                        }
                    }

                    // Command Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Command")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            text: qsTr("Pick an installed app or type any shell command. Hyprland passes this to /bin/sh -c, so quoting and meta characters work as in a shell.")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3outline
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                id: cmdInput
                                Layout.fillWidth: true
                                placeholderText: qsTr("Command line")
                                text: entryModal.cmdText
                                onTextEdited: entryModal.cmdText = text
                            }

                            IconButton {
                                icon: "search"
                                type: IconButton.Filled
                                onClicked: appPicker.open()
                            }
                        }
                    }

                    // Behaviour Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Behaviour")
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
                                spacing: Tokens.spacing.medium

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: qsTr("Re-run on every config reload")
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3onSurface
                                    }

                                    StyledText {
                                        text: qsTr("Off: run once at startup. On: re-run every time config is reloaded.")
                                        font: Tokens.font.label.small
                                        color: Colours.palette.m3outline
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }

                                Switch {
                                    checked: entryModal.onReload
                                    onToggled: entryModal.onReload = checked
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        AppPickerDialog {
            id: appPicker
            onAppSelected: (exec, name, icon) => {
                if (entryModal.visible) {
                    entryModal.cmdText = exec;
                }
            }
        }
    }
}
