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

    title: qsTr("Gaps & rounding")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Corner Rounding")
        }

        StepperRow {
            first: true
            varKey: "windowRounding"
            label: qsTr("Window Corner Rounding")
            subtext: qsTr("Corner radius curvature for all tiled and floating windows")
            value: CaelestiaVars.pendingVars.windowRounding ?? CaelestiaVars.currentVars.windowRounding ?? CaelestiaVars.getDefault("windowRounding", 15)
            from: 0
            to: 50
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowRounding", v)
        }

        StepperRow {
            last: true
            varKey: "windowRoundingPower"
            label: qsTr("Rounding Power")
            subtext: qsTr("Exponent curve power for rounding corners (2.0 = circle, higher = squircle)")
            value: CaelestiaVars.pendingVars.windowRoundingPower ?? CaelestiaVars.currentVars.windowRoundingPower ?? CaelestiaVars.getDefault("windowRoundingPower", 2.0)
            from: 1.0
            to: 10.0
            stepSize: 0.5
            onMoved: v => CaelestiaVars.set("windowRoundingPower", v)
        }

        SectionHeader {
            text: qsTr("Gaps & Spacing")
        }

        StepperRow {
            first: true
            varKey: "windowGapsIn"
            label: qsTr("Inner Window Gaps")
            subtext: qsTr("Gap spacing between adjacent tiled windows")
            value: CaelestiaVars.pendingVars.windowGapsIn ?? CaelestiaVars.currentVars.windowGapsIn ?? CaelestiaVars.getDefault("windowGapsIn", 5)
            from: 0
            to: 50
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowGapsIn", v)
        }

        StepperRow {
            varKey: "windowGapsOut"
            label: qsTr("Outer Window Gaps")
            subtext: qsTr("Gap spacing between tiled windows and screen edge")
            value: CaelestiaVars.pendingVars.windowGapsOut ?? CaelestiaVars.currentVars.windowGapsOut ?? CaelestiaVars.getDefault("windowGapsOut", 10)
            from: 0
            to: 60
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowGapsOut", v)
        }

        StepperRow {
            varKey: "singleWindowGapsOut"
            label: qsTr("Single Window Gaps")
            subtext: qsTr("Outer gap when only a single window is open on a workspace")
            value: CaelestiaVars.pendingVars.singleWindowGapsOut ?? CaelestiaVars.currentVars.singleWindowGapsOut ?? CaelestiaVars.getDefault("singleWindowGapsOut", 20)
            from: 0
            to: 60
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("singleWindowGapsOut", v)
        }

        StepperRow {
            last: true
            varKey: "workspaceGaps"
            label: qsTr("Workspace Gaps")
            subtext: qsTr("Spacing around workspaces overview and special workspaces")
            value: CaelestiaVars.pendingVars.workspaceGaps ?? CaelestiaVars.currentVars.workspaceGaps ?? CaelestiaVars.getDefault("workspaceGaps", 20)
            from: 0
            to: 60
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("workspaceGaps", v)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
