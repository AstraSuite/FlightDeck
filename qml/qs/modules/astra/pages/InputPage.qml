import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Touchpad & Gestures")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Touchpad Options")
        }

        ToggleRow {
            first: true
            varKey: "touchpadDisableTyping"
            text: qsTr("Disable While Typing")
            subtext: qsTr("Ignore accidental palm and touch events during keyboard typing")
            checked: CaelestiaVars.pendingVars.touchpadDisableTyping ?? CaelestiaVars.currentVars.touchpadDisableTyping ?? CaelestiaVars.getDefault("touchpadDisableTyping", true)
            onToggled: CaelestiaVars.set("touchpadDisableTyping", checked)
        }

        SliderRow {
            last: true
            varKey: "touchpadScrollFactor"
            label: qsTr("Touchpad Scroll Factor")
            subtext: qsTr("Two-finger scroll sensitivity multiplier")
            value: CaelestiaVars.pendingVars.touchpadScrollFactor ?? CaelestiaVars.currentVars.touchpadScrollFactor ?? CaelestiaVars.getDefault("touchpadScrollFactor", 0.3)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.1
            to: 1.5
            stepSize: 0.05
            onInteraction: v => CaelestiaVars.set("touchpadScrollFactor", Math.round(v * 100) / 100)
            onMoved: v => CaelestiaVars.set("touchpadScrollFactor", Math.round(v * 100) / 100)
        }

        SectionHeader {
            text: qsTr("Swipe Gestures")
        }

        StepperRow {
            first: true
            varKey: "workspaceSwipeFingers"
            label: qsTr("Workspace Swipe Fingers")
            subtext: qsTr("Number of fingers for workspace swipe transition")
            value: CaelestiaVars.pendingVars.workspaceSwipeFingers ?? CaelestiaVars.currentVars.workspaceSwipeFingers ?? CaelestiaVars.getDefault("workspaceSwipeFingers", 4)
            from: 3
            to: 5
            stepSize: 1
            onMoved: v => CaelestiaVars.set("workspaceSwipeFingers", v)
        }

        StepperRow {
            last: true
            varKey: "gestureFingers"
            label: qsTr("General Gesture Fingers")
            subtext: qsTr("Number of fingers for standard desktop gestures")
            value: CaelestiaVars.pendingVars.gestureFingers ?? CaelestiaVars.currentVars.gestureFingers ?? CaelestiaVars.getDefault("gestureFingers", 3)
            from: 3
            to: 5
            stepSize: 1
            onMoved: v => CaelestiaVars.set("gestureFingers", v)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
