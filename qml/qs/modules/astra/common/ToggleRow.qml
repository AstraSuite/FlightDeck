import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.services
import Helm.Caelestia 1.0

StyledSwitch {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property bool showDelete: false
    signal deleted()

    property var configNode
    property string propertyName: ""

    property string subtext
    property alias first: bg.first
    property alias last: bg.last
    readonly property alias bg: bg
    readonly property alias stateLayer: stateLayer

    Layout.fillWidth: true

    horizontalPadding: Tokens.padding.largeIncreased
    verticalPadding: Tokens.padding.medium
    font: Tokens.font.body.small

    implicitWidth: implicitContentWidth + implicitIndicatorWidth + horizontalPadding * 2
    implicitHeight: Math.max(implicitContentHeight, implicitIndicatorHeight) + verticalPadding * 2
    cLayer: 2

    indicator.anchors.verticalCenter: verticalCenter
    indicator.anchors.right: right
    indicator.anchors.rightMargin: root.horizontalPadding

    onPressed: stateLayer.press(stateLayer.mouseX, stateLayer.mouseY)

    background: ConnectedRect {
        id: bg

        StateLayer {
            id: stateLayer

            disabled: root.disabled
            manualPressOverride: root.pressed
        }
    }

    contentItem: Item {
        anchors.left: parent.left
        anchors.right: root.indicator.left
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: Tokens.spacing.medium

        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            RowLayout {
                width: parent.width
                spacing: Tokens.spacing.small

                StyledText {
                    id: label
                    text: root.text
                    font: root.font
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
                    id: delBtn
                    icon: "delete"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showDelete
                    onClicked: root.deleted()
                }

                PerMonitorStatusChip {
                    configNode: root.configNode
                    propertyName: root.propertyName
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right

                visible: root.subtext !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
