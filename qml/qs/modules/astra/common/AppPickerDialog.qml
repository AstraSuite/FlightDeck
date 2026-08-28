pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Helm.Managers 1.0

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

    // Modal Card
    StyledRect {
        id: card
        width: Math.min(480, root.width - 32)
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
            // Swallow clicks to prevent backdrop dismissal
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Select Application")
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
                placeholderText: qsTr("Search installed applications...")
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
                    var all = AutostartManager.availableApps || [];
                    if (!q) return all;
                    return all.filter(a => {
                        return (a.name && a.name.toLowerCase().includes(q)) ||
                               (a.exec && a.exec.toLowerCase().includes(q)) ||
                               (a.comment && a.comment.toLowerCase().includes(q));
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
                                root.appSelected(itemRow.modelData.exec || "", itemRow.modelData.name || "", itemRow.modelData.icon || "");
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
                    }
                }
            }
        }
    }
}
