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

    title: qsTr("Drop shadows")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Shadow Master Control")
        }

        ToggleRow {
            first: true
            last: true
            varKey: "shadowEnabled"
            text: qsTr("Enable Shadows")
            subtext: qsTr("Drop dynamic shadows behind floating and tiled windows")
            checked: CaelestiaVars.pendingVars.shadowEnabled ?? CaelestiaVars.currentVars.shadowEnabled ?? CaelestiaVars.getDefault("shadowEnabled", true)
            onToggled: CaelestiaVars.set("shadowEnabled", checked)
        }

        SectionHeader {
            text: qsTr("Shadow Colors")
        }

        ColorPickerDialogRow {
            rootParent: root.modalOverlay
            first: true
            varKey: "shadowColour"
            label: qsTr("Active Shadow Color")
        }

        ColorPickerDialogRow {
            rootParent: root.modalOverlay
            last: true
            varKey: "inactiveShadowColour"
            label: qsTr("Inactive Shadow Color")
        }

        SectionHeader {
            text: qsTr("Shadow Geometry & Scale")
        }

        StepperRow {
            first: true
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
            varKey: "shadowRenderPower"
            label: qsTr("Shadow Render Power")
            subtext: qsTr("Shadow falloff power exponent (1 - 4)")
            value: CaelestiaVars.pendingVars.shadowRenderPower ?? CaelestiaVars.currentVars.shadowRenderPower ?? CaelestiaVars.getDefault("shadowRenderPower", 4)
            from: 1
            to: 4
            stepSize: 1
            onMoved: v => CaelestiaVars.set("shadowRenderPower", v)
        }

        SliderRow {
            varKey: "shadowScale"
            label: qsTr("Shadow Scale")
            subtext: qsTr("Scale factor for shadow relative to window size")
            value: CaelestiaVars.pendingVars.shadowScale ?? CaelestiaVars.currentVars.shadowScale ?? CaelestiaVars.getDefault("shadowScale", 1.0)
            valueLabel: value.toFixed(2)
            from: 0.5
            to: 2.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("shadowScale", Math.round(v * 100) / 100)
        }

        TextFieldRow {
            last: true
            varKey: "shadowOffset"
            label: qsTr("Shadow Offset")
            subtext: qsTr("Shadow position offset in pixels (\"x y\", e.g. \"0 0\" or \"5 5\")")
            text: CaelestiaVars.pendingVars.shadowOffset ?? CaelestiaVars.currentVars.shadowOffset ?? CaelestiaVars.getDefault("shadowOffset", "0 0")
            placeholderText: "0 0"
            onEditingFinished: CaelestiaVars.set("shadowOffset", text.trim())
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
