pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Touchpad & gestures")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Touchpad Settings")
        }

        ToggleRow {
            first: true
            varKey: "touchpadDisableTyping"
            text: qsTr("Disable While Typing")
            subtext: qsTr("Ignore accidental palm and touch events during keyboard typing")
            checked: CaelestiaVars.pendingVars.touchpadDisableTyping ?? CaelestiaVars.currentVars.touchpadDisableTyping ?? CaelestiaVars.getDefault("touchpadDisableTyping", true)
            onToggled: CaelestiaVars.set("touchpadDisableTyping", checked)
        }

        ToggleRow {
            varKey: "touchpadTapToClick"
            text: qsTr("Tap to Click")
            subtext: qsTr("Single and multi-finger tap clicks (1=Left, 2=Right, 3=Middle)")
            checked: CaelestiaVars.pendingVars.touchpadTapToClick ?? CaelestiaVars.currentVars.touchpadTapToClick ?? CaelestiaVars.getDefault("touchpadTapToClick", true)
            onToggled: CaelestiaVars.set("touchpadTapToClick", checked)
        }

        ToggleRow {
            varKey: "touchpadClickfingerBehavior"
            text: qsTr("Clickfinger Behavior")
            subtext: qsTr("Use finger count instead of physical button zones for clicks")
            checked: CaelestiaVars.pendingVars.touchpadClickfingerBehavior ?? CaelestiaVars.currentVars.touchpadClickfingerBehavior ?? CaelestiaVars.getDefault("touchpadClickfingerBehavior", false)
            onToggled: CaelestiaVars.set("touchpadClickfingerBehavior", checked)
        }

        ToggleRow {
            varKey: "touchpadMiddleButtonEmulation"
            text: qsTr("Middle Button Emulation")
            subtext: qsTr("Press left and right buttons simultaneously for middle click")
            checked: CaelestiaVars.pendingVars.touchpadMiddleButtonEmulation ?? CaelestiaVars.currentVars.touchpadMiddleButtonEmulation ?? CaelestiaVars.getDefault("touchpadMiddleButtonEmulation", false)
            onToggled: CaelestiaVars.set("touchpadMiddleButtonEmulation", checked)
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
            onMoved: v => CaelestiaVars.set("touchpadScrollFactor", Math.round(v * 100) / 100)
        }

        SectionHeader {
            text: qsTr("Workspace Swipe & Multi-Touch Gestures")
        }

        ToggleRow {
            first: true
            varKey: "workspaceSwipeCreateNew"
            text: qsTr("Create New Workspace on Swipe")
            subtext: qsTr("Swiping past the last workspace creates a new one")
            checked: CaelestiaVars.pendingVars.workspaceSwipeCreateNew ?? CaelestiaVars.currentVars.workspaceSwipeCreateNew ?? CaelestiaVars.getDefault("workspaceSwipeCreateNew", true)
            onToggled: CaelestiaVars.set("workspaceSwipeCreateNew", checked)
        }

        ToggleRow {
            varKey: "workspaceSwipeForever"
            text: qsTr("Swipe Forever")
            subtext: qsTr("Keep swiping through workspaces without boundary limits")
            checked: CaelestiaVars.pendingVars.workspaceSwipeForever ?? CaelestiaVars.currentVars.workspaceSwipeForever ?? CaelestiaVars.getDefault("workspaceSwipeForever", false)
            onToggled: CaelestiaVars.set("workspaceSwipeForever", checked)
        }

        SliderRow {
            varKey: "workspaceSwipeCancelRatio"
            label: qsTr("Swipe Cancel Ratio")
            subtext: qsTr("Minimum distance to commit workspace swipe gesture")
            value: CaelestiaVars.pendingVars.workspaceSwipeCancelRatio ?? CaelestiaVars.currentVars.workspaceSwipeCancelRatio ?? CaelestiaVars.getDefault("workspaceSwipeCancelRatio", 0.5)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.1
            to: 0.9
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("workspaceSwipeCancelRatio", Math.round(v * 100) / 100)
        }

        StepperRow {
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
            varKey: "workspaceSwipeDistance"
            label: qsTr("Swipe Distance")
            subtext: qsTr("Distance in pixels for touchpad workspace swipe")
            value: CaelestiaVars.pendingVars.workspaceSwipeDistance ?? CaelestiaVars.currentVars.workspaceSwipeDistance ?? CaelestiaVars.getDefault("workspaceSwipeDistance", 300)
            from: 100
            to: 1000
            stepSize: 50
            suffix: "px"
            onMoved: v => CaelestiaVars.set("workspaceSwipeDistance", v)
        }

        ToggleRow {
            varKey: "workspaceSwipeInvert"
            text: qsTr("Invert Swipe Direction")
            subtext: qsTr("Invert touchpad swipe movement direction")
            checked: CaelestiaVars.pendingVars.workspaceSwipeInvert ?? CaelestiaVars.currentVars.workspaceSwipeInvert ?? CaelestiaVars.getDefault("workspaceSwipeInvert", false)
            onToggled: CaelestiaVars.set("workspaceSwipeInvert", checked)
        }

        StepperRow {
            varKey: "gestureFingers"
            label: qsTr("General Gesture Fingers")
            subtext: qsTr("Number of fingers for standard desktop gestures")
            value: CaelestiaVars.pendingVars.gestureFingers ?? CaelestiaVars.currentVars.gestureFingers ?? CaelestiaVars.getDefault("gestureFingers", 3)
            from: 3
            to: 5
            stepSize: 1
            onMoved: v => CaelestiaVars.set("gestureFingers", v)
        }

        StepperRow {
            varKey: "gestureFingersMore"
            label: qsTr("Extended Gesture Fingers")
            subtext: qsTr("Number of fingers for secondary multi-touch gestures")
            value: CaelestiaVars.pendingVars.gestureFingersMore ?? CaelestiaVars.currentVars.gestureFingersMore ?? CaelestiaVars.getDefault("gestureFingersMore", 4)
            from: 3
            to: 5
            stepSize: 1
            onMoved: v => CaelestiaVars.set("gestureFingersMore", v)
        }

        TextFieldRow {
            last: true
            varKey: "sleepGestureCmd"
            label: qsTr("Sleep Gesture Command")
            subtext: qsTr("Command to execute when sleep gesture is triggered")
            placeholderText: "systemctl suspend-then-hibernate"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
