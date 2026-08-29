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

    title: qsTr("Dimming & snapping")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Dimming")
        }

        ToggleRow {
            first: true
            varKey: "dimInactive"
            text: qsTr("Dim Inactive Windows")
            subtext: qsTr("Dim background / inactive windows to emphasize active window")
            checked: CaelestiaVars.pendingVars.dimInactive ?? CaelestiaVars.currentVars.dimInactive ?? CaelestiaVars.getDefault("dimInactive", false)
            onToggled: CaelestiaVars.set("dimInactive", checked)
        }

        SliderRow {
            varKey: "dimAround"
            label: qsTr("Dim Around Floating Windows")
            subtext: qsTr("Darken screen area around active floating dialogs and windows")
            value: CaelestiaVars.pendingVars.dimAround ?? CaelestiaVars.currentVars.dimAround ?? CaelestiaVars.getDefault("dimAround", 0.0)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.0
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("dimAround", Math.round(v * 100) / 100)
        }

        SliderRow {
            last: true
            varKey: "dimSpecial"
            label: qsTr("Dim Special Workspace")
            subtext: qsTr("Dim background screen when special scratchpad workspace is open")
            value: CaelestiaVars.pendingVars.dimSpecial ?? CaelestiaVars.currentVars.dimSpecial ?? CaelestiaVars.getDefault("dimSpecial", 0.2)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.0
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("dimSpecial", Math.round(v * 100) / 100)
        }

        SectionHeader {
            text: qsTr("Floating Window Snapping")
        }

        ToggleRow {
            first: true
            last: !(CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false))
            varKey: "snapEnabled"
            text: qsTr("Enable Snapping")
            subtext: qsTr("Snap floating windows to other windows and screen edges")
            checked: CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false)
            onToggled: CaelestiaVars.set("snapEnabled", checked)
        }

        StepperRow {
            visible: CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false)
            varKey: "snapWindowGap"
            label: qsTr("Window Snap Gap")
            subtext: qsTr("Minimum distance to snap to neighboring windows")
            value: CaelestiaVars.pendingVars.snapWindowGap ?? CaelestiaVars.currentVars.snapWindowGap ?? CaelestiaVars.getDefault("snapWindowGap", 10)
            from: 1
            to: 50
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("snapWindowGap", v)
        }

        StepperRow {
            visible: CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false)
            varKey: "snapMonitorGap"
            label: qsTr("Monitor Edge Snap Gap")
            subtext: qsTr("Minimum distance to snap to display edges")
            value: CaelestiaVars.pendingVars.snapMonitorGap ?? CaelestiaVars.currentVars.snapMonitorGap ?? CaelestiaVars.getDefault("snapMonitorGap", 10)
            from: 1
            to: 50
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("snapMonitorGap", v)
        }

        ToggleRow {
            visible: CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false)
            varKey: "snapBorderOverlap"
            text: qsTr("Border Overlap")
            subtext: qsTr("Snap windows with overlapping borders")
            checked: CaelestiaVars.pendingVars.snapBorderOverlap ?? CaelestiaVars.currentVars.snapBorderOverlap ?? CaelestiaVars.getDefault("snapBorderOverlap", false)
            onToggled: CaelestiaVars.set("snapBorderOverlap", checked)
        }

        ToggleRow {
            last: true
            visible: CaelestiaVars.pendingVars.snapEnabled ?? CaelestiaVars.currentVars.snapEnabled ?? CaelestiaVars.getDefault("snapEnabled", false)
            varKey: "snapRespectGaps"
            text: qsTr("Respect Gaps")
            subtext: qsTr("Offset snapping by configured outer gaps")
            checked: CaelestiaVars.pendingVars.snapRespectGaps ?? CaelestiaVars.currentVars.snapRespectGaps ?? CaelestiaVars.getDefault("snapRespectGaps", false)
            onToggled: CaelestiaVars.set("snapRespectGaps", checked)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
