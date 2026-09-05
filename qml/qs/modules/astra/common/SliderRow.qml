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

    readonly property bool isOverridden: (CaelestiaVars.revision >= 0 && root.varKey !== "") ? CaelestiaVars.isOverridden(root.varKey) : false

    Connections {
        target: CaelestiaVars
        function onVarsChanged() {
            if (root.varKey !== "" && !slider.dragging) {
                root.value = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, root.from));
            }
        }
        function onPendingChanged() {
            if (root.varKey !== "" && !slider.dragging) {
                root.value = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, root.from));
            }
        }
    }

    Component.onCompleted: {
        if (root.varKey !== "") {
            root.value = CaelestiaVars.get(root.varKey, CaelestiaVars.getDefault(root.varKey, root.from));
        }
    }

    property alias icon: icon.text
    property alias label: label.text
    property alias text: label.text
    property string subtext: ""
    property alias valueLabel: valueLabel.text
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.05

    signal moved(value: real)
    signal interaction(value: real)
    signal released(value: real)

    function quantize(val) {
        var clamped = Math.max(root.from, Math.min(root.to, val));
        if (root.stepSize <= 0) return clamped;
        var steps = Math.round((clamped - root.from) / root.stepSize);
        var stepped = root.from + steps * root.stepSize;
        var stepStr = root.stepSize.toString();
        var decimals = 0;
        if (stepStr.indexOf('.') !== -1) {
            decimals = stepStr.split('.')[1].length;
        }
        return parseFloat(stepped.toFixed(Math.min(decimals + 2, 6)));
    }

    onMoved: (v) => {
        if (root.varKey !== "") {
            CaelestiaVars.set(root.varKey, v);
        }
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.large * 2

    RowLayout {
        id: rowLayout

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
            spacing: Tokens.spacing.small

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
                    visible: root.showReset || root.isOverridden
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                        }
                        root.reset();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    id: valueLabel
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.medium
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

            MouseArea {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.medium * 2

                onWheel: (event) => {
                    var delta = event.angleDelta.y > 0 ? root.stepSize : -root.stepSize;
                    var newVal = root.quantize(root.value + delta);
                    if (newVal !== root.value) {
                        root.value = newVal;
                        root.moved(newVal);
                        root.released(newVal);
                    }
                }

                StyledSlider {
                    id: slider
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.implicitHeight

                    radius: Tokens.rounding.small
                    value: (root.value - root.from) / (root.to - root.from)
                    enabled: root.enabled
                    onInteraction: v => {
                        var realVal = root.from + v * (root.to - root.from);
                        realVal = root.quantize(realVal);
                        root.value = realVal;
                        root.interaction(realVal);
                    }
                    onReleased: v => {
                        var realVal = root.from + v * (root.to - root.from);
                        realVal = root.quantize(realVal);
                        root.value = realVal;
                        root.moved(realVal);
                        root.released(realVal);
                    }
                }
            }
        }
    }
}
