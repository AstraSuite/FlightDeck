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
import FlightDeck.Caelestia 1.0

Item {
    id: root

    signal clientSelected(string winClass, string winTitle, string initialClass, string initialTitle)

    property string searchQuery: ""
    property var clientsList: []
    property bool opened: visible

    function open() {
        searchQuery = "";
        clientsList = FlightDeckWriter.activeHyprlandClients();
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
                        text: qsTr("Select Open Window")
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
                    placeholderText: qsTr("Search open windows by class or title...")
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
                        var all = root.clientsList || [];
                        if (!q) return all;
                        return all.filter(c => {
                            return (c.class && c.class.toLowerCase().includes(q)) ||
                                   (c.title && c.title.toLowerCase().includes(q)) ||
                                   (c.initialClass && c.initialClass.toLowerCase().includes(q));
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
                                    var winClass = itemRow.modelData.class || "";
                                    var winTitle = itemRow.modelData.title || "";
                                    var initClass = itemRow.modelData.initialClass || winClass;
                                    var initTitle = itemRow.modelData.initialTitle || winTitle;
                                    root.clientSelected(winClass, winTitle, initClass, initTitle);
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
                                id: dialogAppIconImg
                                source: {
                                    var c = itemRow.modelData;
                                    if (!c) return "";
                                    var iconName = c.initialClass || c.class || "";
                                    return iconName ? ("image://icon/" + iconName) : "";
                                }
                                sourceSize.width: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                sourceSize.height: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                Layout.preferredWidth: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                Layout.preferredHeight: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            MaterialIcon {
                                visible: !dialogAppIconImg.visible
                                text: "web_asset"
                                fontStyle: Tokens.font.icon.medium
                                color: Colours.palette.m3primary
                            }

                            ColumnLayout {
                                id: col
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: itemRow.modelData ? (itemRow.modelData.class || qsTr("Unknown")) : ""
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: itemRow.modelData ? (itemRow.modelData.title || "") : ""
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
