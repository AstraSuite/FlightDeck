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

    title: qsTr("Blur effects")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Blur Filter")
        }

        ToggleRow {
            first: true
            varKey: "blurEnabled"
            text: qsTr("Enable Background Blur")
            subtext: qsTr("Apply dual kawase blur to semi-transparent windows")
            checked: CaelestiaVars.pendingVars.blurEnabled ?? CaelestiaVars.currentVars.blurEnabled ?? CaelestiaVars.getDefault("blurEnabled", true)
            onToggled: CaelestiaVars.set("blurEnabled", checked)
        }

        StepperRow {
            varKey: "blurSize"
            label: qsTr("Blur Size")
            subtext: qsTr("Blur sampling kernel radius in pixels")
            value: CaelestiaVars.pendingVars.blurSize ?? CaelestiaVars.currentVars.blurSize ?? CaelestiaVars.getDefault("blurSize", 8)
            from: 1
            to: 30
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("blurSize", v)
        }

        StepperRow {
            varKey: "blurPasses"
            label: qsTr("Blur Passes")
            subtext: qsTr("Number of blur iterations (higher = smoother, heavier GPU load)")
            value: CaelestiaVars.pendingVars.blurPasses ?? CaelestiaVars.currentVars.blurPasses ?? CaelestiaVars.getDefault("blurPasses", 2)
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => CaelestiaVars.set("blurPasses", v)
        }

        ToggleRow {
            varKey: "blurIgnoreOpacity"
            text: qsTr("Ignore Opacity")
            subtext: qsTr("Make blur ignore window opacity and blur transparent areas behind window")
            checked: CaelestiaVars.pendingVars.blurIgnoreOpacity ?? CaelestiaVars.currentVars.blurIgnoreOpacity ?? CaelestiaVars.getDefault("blurIgnoreOpacity", false)
            onToggled: CaelestiaVars.set("blurIgnoreOpacity", checked)
        }

        ToggleRow {
            last: true
            varKey: "blurXray"
            text: qsTr("Blur X-Ray")
            subtext: qsTr("Floating windows ignore tiled windows in their blur")
            checked: CaelestiaVars.pendingVars.blurXray ?? CaelestiaVars.currentVars.blurXray ?? CaelestiaVars.getDefault("blurXray", false)
            onToggled: CaelestiaVars.set("blurXray", checked)
        }

        SectionHeader {
            text: qsTr("Texture & Color Modulation")
        }

        SliderRow {
            first: true
            varKey: "blurNoise"
            label: qsTr("Blur Noise")
            subtext: qsTr("Noise texture applied to blur surface")
            value: CaelestiaVars.pendingVars.blurNoise ?? CaelestiaVars.currentVars.blurNoise ?? CaelestiaVars.getDefault("blurNoise", 0.0117)
            valueLabel: value.toFixed(4)
            from: 0.0
            to: 0.2
            stepSize: 0.005
            onMoved: v => CaelestiaVars.set("blurNoise", Math.round(v * 10000) / 10000)
        }

        SliderRow {
            varKey: "blurContrast"
            label: qsTr("Blur Contrast")
            subtext: qsTr("Contrast modulation for blur")
            value: CaelestiaVars.pendingVars.blurContrast ?? CaelestiaVars.currentVars.blurContrast ?? CaelestiaVars.getDefault("blurContrast", 0.8916)
            valueLabel: value.toFixed(2)
            from: 0.0
            to: 2.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("blurContrast", Math.round(v * 100) / 100)
        }

        SliderRow {
            varKey: "blurBrightness"
            label: qsTr("Blur Brightness")
            subtext: qsTr("Brightness modulation for blur")
            value: CaelestiaVars.pendingVars.blurBrightness ?? CaelestiaVars.currentVars.blurBrightness ?? CaelestiaVars.getDefault("blurBrightness", 0.8172)
            valueLabel: value.toFixed(2)
            from: 0.0
            to: 2.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("blurBrightness", Math.round(v * 100) / 100)
        }

        SliderRow {
            varKey: "blurVibrancy"
            label: qsTr("Blur Vibrancy")
            subtext: qsTr("Saturation boost of blurred colors")
            value: CaelestiaVars.pendingVars.blurVibrancy ?? CaelestiaVars.currentVars.blurVibrancy ?? CaelestiaVars.getDefault("blurVibrancy", 0.1696)
            valueLabel: value.toFixed(2)
            from: 0.0
            to: 2.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("blurVibrancy", Math.round(v * 100) / 100)
        }

        SliderRow {
            last: true
            varKey: "blurVibrancyDarkness"
            label: qsTr("Blur Vibrancy Darkness")
            subtext: qsTr("Saturation boost for dark colors")
            value: CaelestiaVars.pendingVars.blurVibrancyDarkness ?? CaelestiaVars.currentVars.blurVibrancyDarkness ?? CaelestiaVars.getDefault("blurVibrancyDarkness", 0.0)
            valueLabel: value.toFixed(2)
            from: 0.0
            to: 2.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("blurVibrancyDarkness", Math.round(v * 100) / 100)
        }

        SectionHeader {
            text: qsTr("Special Elements")
        }

        ToggleRow {
            first: true
            varKey: "blurSpecialWs"
            text: qsTr("Blur Special Workspace")
            subtext: qsTr("Apply blur filter to special workspace background")
            checked: CaelestiaVars.pendingVars.blurSpecialWs ?? CaelestiaVars.currentVars.blurSpecialWs ?? CaelestiaVars.getDefault("blurSpecialWs", false)
            onToggled: CaelestiaVars.set("blurSpecialWs", checked)
        }

        ToggleRow {
            varKey: "blurPopups"
            text: qsTr("Blur Popups")
            subtext: qsTr("Apply blur filter to context menus and popups")
            checked: CaelestiaVars.pendingVars.blurPopups ?? CaelestiaVars.currentVars.blurPopups ?? CaelestiaVars.getDefault("blurPopups", true)
            onToggled: CaelestiaVars.set("blurPopups", checked)
        }

        ToggleRow {
            last: true
            varKey: "blurInputMethods"
            text: qsTr("Blur Input Methods")
            subtext: qsTr("Apply blur filter to on-screen keyboard and IME popups")
            checked: CaelestiaVars.pendingVars.blurInputMethods ?? CaelestiaVars.currentVars.blurInputMethods ?? CaelestiaVars.getDefault("blurInputMethods", true)
            onToggled: CaelestiaVars.set("blurInputMethods", checked)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
