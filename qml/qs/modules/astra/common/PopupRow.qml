import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.services
import qs.modules.astra.common
import qs.components.controls
import Helm.Caelestia 1.0

ConnectedRect {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property bool showDelete: false
    signal deleted()

    property alias icon: icon.text
    property alias label: label.text
    property alias text: label.text
    property alias status: status.text
    property alias popup: popup
    default property Item content

    Layout.fillWidth: true
    implicitHeight: navLayout.implicitHeight + Tokens.padding.medium * 2

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        onClicked: popup.open = !popup.open
    }

    RowLayout {
        id: navLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon
            visible: text !== ""
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showReset || (root.varKey !== "" && CaelestiaVars.isOverridden(root.varKey))
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                        }
                        root.reset();
                    }
                }

                IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showDelete
                    onClicked: root.deleted()
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                id: status
                Layout.fillWidth: true
                visible: text !== ""
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        BlobPopup {
            id: popup
            content: root.content
            pressOverride: stateLayer.pressed
            hoverOverride: stateLayer.containsMouse
            color: open || hovered || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
        }
    }
}
