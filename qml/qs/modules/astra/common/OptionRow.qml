pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

ConnectedRect {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property alias title: root.text
    property string text
    property string subtext
    property string currentValue
    property var options: []
    property int currentIndex: 0
    readonly property alias stateLayer: stateLayer
    signal optionSelected(var value, string label)
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.options && root.options.length > 0) {
                const nextIdx = (root.currentIndex + 1) % root.options.length;
                root.currentIndex = nextIdx;
                root.optionSelected(root.options[nextIdx].value, root.options[nextIdx].label);
            }
            root.clicked();
        }
    }

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.text
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showReset || (root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars))
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                            var defVal = CaelestiaVars.getDefault(root.varKey, "");
                            root.currentValue = defVal;
                        }
                        root.reset();
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: Tokens.spacing.small

            StyledText {
                text: root.currentValue
                color: Colours.palette.m3primary
                font: Tokens.font.label.medium
            }

            MaterialIcon {
                text: "swap_horiz"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }
        }
    }
}
