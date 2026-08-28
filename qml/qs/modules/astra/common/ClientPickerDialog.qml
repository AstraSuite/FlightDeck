pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Helm.Caelestia 1.0

Item {
    id: root

    signal clientSelected(string winClass, string winTitle, string initialClass, string initialTitle)

    property string searchQuery: ""
    property var clientsList: []
    property bool opened: visible

    function open() {
        searchQuery = "";
        clientsList = AstraHelmWriter.activeHyprlandClients();
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

    // Modal Card
    StyledRect {
        id: card
        width: Math.min(500, root.width - 32)
        height: Math.min(520, root.height - 32)
        anchors.centerIn: parent

        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

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
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Pick Open Window")
                    font: Tokens.font.title.medium
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

            VerticalFadeListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 0
                topMargin: Tokens.padding.small
                bottomMargin: Tokens.padding.small

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

                delegate: StyledRect {
                    id: itemRow
                    required property var modelData
                    required property int index

                    anchors.left: ListView.view.contentItem.left
                    anchors.right: ListView.view.contentItem.right
                    anchors.margins: 1
                    implicitHeight: Math.max(52, col.implicitHeight + Tokens.padding.medium * 2)

                    radius: stateLayer.pressed ? Tokens.rounding.extraSmall : (stateLayer.containsMouse ? Tokens.rounding.large : Tokens.rounding.medium)
                    color: stateLayer.pressed ? Colours.palette.m3surfaceContainerHighest : (stateLayer.containsMouse ? Colours.palette.m3surfaceContainerHigh : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.4))

                    Behavior on radius {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    StateLayer {
                        id: stateLayer
                        anchors.fill: parent
                        onClicked: {
                            if (itemRow.modelData) {
                                root.clientSelected(
                                    itemRow.modelData.class || "",
                                    itemRow.modelData.title || "",
                                    itemRow.modelData.initialClass || "",
                                    itemRow.modelData.initialTitle || ""
                                );
                                root.close();
                            }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
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
                    }
                }
            }
        }
    }
}
