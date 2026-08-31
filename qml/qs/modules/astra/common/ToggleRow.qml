import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import FlightDeck.Caelestia 1.0

StyledSwitch {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    readonly property bool isOverridden: (CaelestiaVars.revision >= 0 && root.varKey !== "") ? CaelestiaVars.isOverridden(root.varKey) : false

    Connections {
        target: CaelestiaVars
        function onVarsChanged() {
            if (root.varKey !== "") {
                root.checked = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, false));
            }
        }
        function onPendingChanged() {
            if (root.varKey !== "") {
                root.checked = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, false));
            }
        }
    }

    Component.onCompleted: {
        if (root.varKey !== "") {
            root.checked = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, false));
        }
    }

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

    onToggled: {
        if (root.varKey !== "") {
            CaelestiaVars.set(root.varKey, root.checked);
        }
    }

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
        implicitWidth: col.implicitWidth
        implicitHeight: col.implicitHeight

        ColumnLayout {
            id: col
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
                    visible: root.showReset || root.isOverridden
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
                visible: root.subtext !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
