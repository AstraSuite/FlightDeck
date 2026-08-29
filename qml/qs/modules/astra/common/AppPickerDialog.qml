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
import FlightDeck.Managers 1.0

Item {
    id: root

    signal appSelected(string exec, string name, string icon)

    property string searchQuery: ""
    property bool opened: visible

    function open() {
        searchQuery = "";
        visible = true;
        searchField.forceActiveFocus();
    }

    function close() {
        visible = false;
    }

    anchors.fill: parent
    z: 10000
    visible: false

    // Dimming backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Item {
        width: Math.min(560, root.width - 32)
        height: Math.min(580, root.height - 32)
        anchors.centerIn: parent

        Elevation {
            anchors.fill: parent
            radius: Tokens.rounding.extraLargeIncreased
            level: 4
            opacity: root.visible ? 1 : 0
        }

        StyledRect {
            id: card
            anchors.fill: parent
            radius: Tokens.rounding.extraLargeIncreased
            color: Colours.palette.m3surfaceContainerHighest

            scale: root.visible ? 1.0 : 0.9
            opacity: root.visible ? 1 : 0

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
                anchors.margins: Tokens.padding.extraLarge
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Select Application")
                        font: Tokens.font.title.builders.large.weight(Font.Normal).build()
                        color: Colours.palette.m3onSurface
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.close()
                    }
                }

                StyledTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search installed applications...")
                    text: root.searchQuery
                    onTextEdited: root.searchQuery = text
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }

                VerticalFadeListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    topMargin: Tokens.padding.small
                    bottomMargin: Tokens.padding.small
                    spacing: Tokens.spacing.extraSmall / 2

                    model: {
                        var q = root.searchQuery.toLowerCase().trim();
                        var all = AutostartManager.availableApps || [];
                        if (!q) return all;
                        return all.filter(a => {
                            return (a.name && a.name.toLowerCase().includes(q)) ||
                                   (a.exec && a.exec.toLowerCase().includes(q)) ||
                                   (a.comment && a.comment.toLowerCase().includes(q));
                        });
                    }

                    delegate: ConnectedRect {
                        id: itemRow
                        required property var modelData
                        required property int index

                        first: index === 0
                        last: index === (ListView.view ? ListView.view.count - 1 : 0)
                        Layout.fillWidth: true
                        implicitHeight: Math.max(54, col.implicitHeight + Tokens.padding.medium * 2)

                        StateLayer {
                            id: stateLayer
                            anchors.fill: parent
                            onClicked: {
                                if (itemRow.modelData) {
                                    root.appSelected(itemRow.modelData.exec || "", itemRow.modelData.name || "", itemRow.modelData.icon || "");
                                    root.close();
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.medium

                            Image {
                                source: (itemRow.modelData && itemRow.modelData.icon) ? "image://icon/" + itemRow.modelData.icon : ""
                                sourceSize.width: 32
                                sourceSize.height: 32
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: itemRow.modelData && itemRow.modelData.icon !== ""
                            }

                            MaterialIcon {
                                visible: !itemRow.modelData || !itemRow.modelData.icon
                                text: "apps"
                                fontStyle: Tokens.font.icon.medium
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            ColumnLayout {
                                id: col
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: itemRow.modelData ? itemRow.modelData.name : ""
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: itemRow.modelData ? (itemRow.modelData.comment || itemRow.modelData.exec) : ""
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MaterialIcon {
                                text: "chevron_right"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.medium
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }
            }
        }
    }
}
