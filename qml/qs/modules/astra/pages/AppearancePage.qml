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

    title: qsTr("Appearance & Styling")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Styling")
        }

        SliderRow {
            first: true
            varKey: "windowOpacity"
            label: qsTr("Window Opacity")
            subtext: qsTr("Active window background opacity")
            value: CaelestiaVars.pendingVars.windowOpacity ?? CaelestiaVars.currentVars.windowOpacity ?? CaelestiaVars.getDefault("windowOpacity", 0.95)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.2
            to: 1.0
            stepSize: 0.05
            onInteraction: v => CaelestiaVars.set("windowOpacity", Math.round(v * 100) / 100)
            onMoved: v => CaelestiaVars.set("windowOpacity", Math.round(v * 100) / 100)
        }

        StepperRow {
            varKey: "windowRounding"
            label: qsTr("Window Rounding")
            subtext: qsTr("Corner radius in pixels")
            value: CaelestiaVars.pendingVars.windowRounding ?? CaelestiaVars.currentVars.windowRounding ?? CaelestiaVars.getDefault("windowRounding", 15)
            from: 0
            to: 40
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowRounding", v)
        }

        StepperRow {
            last: true
            varKey: "windowBorderSize"
            label: qsTr("Border Size")
            subtext: qsTr("Active and inactive window border width in pixels")
            value: CaelestiaVars.pendingVars.windowBorderSize ?? CaelestiaVars.currentVars.windowBorderSize ?? CaelestiaVars.getDefault("windowBorderSize", 1)
            from: 0
            to: 10
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowBorderSize", v)
        }

        SectionHeader {
            text: qsTr("Gaps & Spacing")
        }

        StepperRow {
            first: true
            varKey: "windowGapsIn"
            label: qsTr("Inner Window Gaps")
            subtext: qsTr("Space between tiled windows in pixels")
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
            subtext: qsTr("Space between windows and monitor screen edges")
            value: CaelestiaVars.pendingVars.windowGapsOut ?? CaelestiaVars.currentVars.windowGapsOut ?? CaelestiaVars.getDefault("windowGapsOut", 10)
            from: 0
            to: 100
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowGapsOut", v)
        }

        StepperRow {
            last: true
            varKey: "workspaceGaps"
            label: qsTr("Workspace Gaps")
            subtext: qsTr("Padding around special workspace overview")
            value: CaelestiaVars.pendingVars.workspaceGaps ?? CaelestiaVars.currentVars.workspaceGaps ?? CaelestiaVars.getDefault("workspaceGaps", 20)
            from: 0
            to: 100
            stepSize: 5
            suffix: "px"
            onMoved: v => CaelestiaVars.set("workspaceGaps", v)
        }

        SectionHeader {
            text: qsTr("Blur Effects")
        }

        ToggleRow {
            first: true
            varKey: "blurEnabled"
            text: qsTr("Enable Blur")
            subtext: qsTr("Hardware-accelerated dual Kawase blur on transparent windows and surfaces")
            checked: CaelestiaVars.pendingVars.blurEnabled ?? CaelestiaVars.currentVars.blurEnabled ?? CaelestiaVars.getDefault("blurEnabled", true)
            onToggled: CaelestiaVars.set("blurEnabled", checked)
        }

        ToggleRow {
            varKey: "blurPopups"
            text: qsTr("Blur Popups")
            subtext: qsTr("Apply blur filter to context menus and popups")
            checked: CaelestiaVars.pendingVars.blurPopups ?? CaelestiaVars.currentVars.blurPopups ?? CaelestiaVars.getDefault("blurPopups", true)
            onToggled: CaelestiaVars.set("blurPopups", checked)
        }

        ToggleRow {
            varKey: "blurXray"
            text: qsTr("Blur X-Ray")
            subtext: qsTr("High-speed transparent pass-through blur")
            checked: CaelestiaVars.pendingVars.blurXray ?? CaelestiaVars.currentVars.blurXray ?? CaelestiaVars.getDefault("blurXray", false)
            onToggled: CaelestiaVars.set("blurXray", checked)
        }

        StepperRow {
            varKey: "blurSize"
            label: qsTr("Blur Size")
            subtext: qsTr("Blur radius / kernel size")
            value: CaelestiaVars.pendingVars.blurSize ?? CaelestiaVars.currentVars.blurSize ?? CaelestiaVars.getDefault("blurSize", 8)
            from: 1
            to: 30
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("blurSize", v)
        }

        StepperRow {
            last: true
            varKey: "blurPasses"
            label: qsTr("Blur Passes")
            subtext: qsTr("Number of blur iterations (higher = smoother, heavier GPU load)")
            value: CaelestiaVars.pendingVars.blurPasses ?? CaelestiaVars.currentVars.blurPasses ?? CaelestiaVars.getDefault("blurPasses", 2)
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => CaelestiaVars.set("blurPasses", v)
        }

        SectionHeader {
            text: qsTr("Shadows")
        }

        ToggleRow {
            first: true
            varKey: "shadowEnabled"
            text: qsTr("Enable Shadows")
            subtext: qsTr("Drop shadows behind windows")
            checked: CaelestiaVars.pendingVars.shadowEnabled ?? CaelestiaVars.currentVars.shadowEnabled ?? CaelestiaVars.getDefault("shadowEnabled", true)
            onToggled: CaelestiaVars.set("shadowEnabled", checked)
        }

        StepperRow {
            varKey: "shadowRange"
            label: qsTr("Shadow Range")
            subtext: qsTr("Shadow spread radius in pixels")
            value: CaelestiaVars.pendingVars.shadowRange ?? CaelestiaVars.currentVars.shadowRange ?? CaelestiaVars.getDefault("shadowRange", 15)
            from: 1
            to: 60
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("shadowRange", v)
        }

        StepperRow {
            last: true
            varKey: "shadowRenderPower"
            label: qsTr("Shadow Render Power")
            subtext: qsTr("Shadow falloff power (1 - 4)")
            value: CaelestiaVars.pendingVars.shadowRenderPower ?? CaelestiaVars.currentVars.shadowRenderPower ?? CaelestiaVars.getDefault("shadowRenderPower", 4)
            from: 1
            to: 4
            stepSize: 1
            onMoved: v => CaelestiaVars.set("shadowRenderPower", v)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
