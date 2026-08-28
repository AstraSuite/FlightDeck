import QtQuick
import QtQuick.Layouts
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

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Add Application")
        }

        DialogRowButton {
            id: addAppBtn
            rootParent: root
            first: true
            last: true
            icon: "add_circle"
            label: qsTr("Add Startup App")
            header: qsTr("Add Autostart Application")
            acceptLabel: qsTr("Add Entry")

            property string searchQuery: ""
            property string selectedExec: ""
            property string customCmd: ""

            acceptAllowed: selectedExec !== "" || customCmd.trim() !== ""

            onAccepted: {
                if (customCmd.trim() !== "") {
                    AutostartManager.addCustomCommand(customCmd.trim());
                    customCmd = "";
                    searchQuery = "";
                } else if (selectedExec !== "") {
                    AutostartManager.toggleApp(selectedExec, true);
                    selectedExec = "";
                    searchQuery = "";
                }
            }

            onCancelled: {
                searchQuery = "";
                selectedExec = "";
                customCmd = "";
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Search installed apps or enter custom command...")
                        text: addAppBtn.searchQuery
                        onTextEdited: {
                            addAppBtn.searchQuery = text;
                            addAppBtn.customCmd = text;
                        }
                    }

                    VerticalFadeListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 240
                        clip: true

                        model: {
                            var q = addAppBtn.searchQuery.toLowerCase().trim();
                            var all = AutostartManager.availableApps || [];
                            if (!q) return all;
                            return all.filter(a => {
                                return (a.name && a.name.toLowerCase().includes(q)) ||
                                       (a.exec && a.exec.toLowerCase().includes(q)) ||
                                       (a.comment && a.comment.toLowerCase().includes(q));
                            });
                        }

                        delegate: StateLayer {
                            id: itemLayer
                            required property var modelData
                            required property int index

                            width: parent ? parent.width : 320
                            implicitHeight: 52
                            radius: Tokens.rounding.small

                            readonly property bool selected: addAppBtn.selectedExec === (itemLayer.modelData ? itemLayer.modelData.exec : "")

                            onClicked: {
                                if (itemLayer.modelData) {
                                    addAppBtn.selectedExec = itemLayer.modelData.exec;
                                    addAppBtn.customCmd = "";
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.medium

                                Image {
                                    source: (itemLayer.modelData && itemLayer.modelData.icon) ? "image://icon/" + itemLayer.modelData.icon : ""
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    asynchronous: true
                                    visible: itemLayer.modelData && itemLayer.modelData.icon !== ""
                                }

                                MaterialIcon {
                                    visible: !itemLayer.modelData || !itemLayer.modelData.icon
                                    text: "apps"
                                    fontStyle: Tokens.font.icon.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        text: itemLayer.modelData ? itemLayer.modelData.name : ""
                                        font: Tokens.font.body.small
                                        color: itemLayer.selected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    StyledText {
                                        text: itemLayer.modelData ? (itemLayer.modelData.comment ? itemLayer.modelData.comment : itemLayer.modelData.exec) : ""
                                        font: Tokens.font.label.small
                                        color: Colours.palette.m3outline
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MaterialIcon {
                                    visible: itemLayer.selected || (itemLayer.modelData && AutostartManager.activeCommands.indexOf(itemLayer.modelData.exec) >= 0)
                                    text: "check"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configured Startup Commands (%1)").arg(AutostartManager.activeCommands.length)
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
                        text: "rocket_launch"
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
                            text: qsTr("Runs via hl.on(\"hyprland.start\") in astra-helm.lua")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: AutostartManager.removeCommand(cmdRow.index)
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
