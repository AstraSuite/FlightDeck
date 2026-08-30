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
import FlightDeck.Hyprland 1.0

PageBase {
    id: root

    title: qsTr("Dynamic Cursors")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General Settings")
        }

        ToggleRow {
            first: true
            varKey: "plugin:dynamic-cursors:enabled"
            text: qsTr("Enable Dynamic Cursors")
            subtext: qsTr("Enable physics-based tilting, rotation, and shake-to-find magnification")
            checked: CaelestiaVars.pendingVars["plugin:dynamic-cursors:enabled"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:enabled"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:enabled", true)
            onToggled: CaelestiaVars.set("plugin:dynamic-cursors:enabled", checked)
        }

        DialogSelectButton {
            varKey: "plugin:dynamic-cursors:mode"
            label: qsTr("Simulation Mode")
            subtext: qsTr("Cursor shape simulation algorithm")
            header: qsTr("Select Cursor Simulation Mode")
            options: [
                { id: "tilt", label: qsTr("Tilt (Air Drag Simulation)") },
                { id: "rotate", label: qsTr("Rotate (Stick Dragging Simulation)") },
                { id: "stretch", label: qsTr("Stretch (Comic Motion Squish/Stretch)") },
                { id: "none", label: qsTr("None (Shake-to-find only)") }
            ]
            currentValue: CaelestiaVars.pendingVars["plugin:dynamic-cursors:mode"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:mode"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:mode", "tilt")
            onSelected: function(opt) {
                CaelestiaVars.set("plugin:dynamic-cursors:mode", opt.id);
            }
        }

        StepperRow {
            varKey: "plugin:dynamic-cursors:threshold"
            label: qsTr("Angle Threshold")
            subtext: qsTr("Minimum angle difference in degrees before the shape changes")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:threshold"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:threshold"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:threshold", 2)
            from: 1
            to: 45
            stepSize: 1
            suffix: "°"
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:threshold", v)
        }

        ToggleRow {
            last: true
            varKey: "plugin:dynamic-cursors:ignore_warps"
            text: qsTr("Ignore Cursor Warps")
            subtext: qsTr("Prevents abrupt rotation or tilt when the cursor is teleported between windows")
            checked: CaelestiaVars.pendingVars["plugin:dynamic-cursors:ignore_warps"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:ignore_warps"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:ignore_warps", true)
            onToggled: CaelestiaVars.set("plugin:dynamic-cursors:ignore_warps", checked)
        }

        SectionHeader {
            text: qsTr("Shake to Find")
        }

        ToggleRow {
            first: true
            varKey: "plugin:dynamic-cursors:shake:enabled"
            text: qsTr("Enable Shake to Find")
            subtext: qsTr("Magnifies cursor when shaken rapidly back and forth")
            checked: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:enabled"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:enabled"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:enabled", true)
            onToggled: CaelestiaVars.set("plugin:dynamic-cursors:shake:enabled", checked)
        }

        SliderRow {
            visible: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:enabled"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:enabled"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:enabled", true)
            varKey: "plugin:dynamic-cursors:shake:threshold"
            label: qsTr("Shake Detection Threshold")
            subtext: qsTr("Sensitivity of shake detection (lower values trigger sooner)")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:threshold"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:threshold"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:threshold", 6.0)
            valueLabel: value.toFixed(1)
            from: 1.0
            to: 20.0
            stepSize: 0.5
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:shake:threshold", Math.round(v * 10) / 10)
        }

        SliderRow {
            visible: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:enabled"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:enabled"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:enabled", true)
            varKey: "plugin:dynamic-cursors:shake:max_factor"
            label: qsTr("Maximum Shake Magnification")
            subtext: qsTr("Maximum magnification factor reached at peak shake speed")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:max_factor"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:max_factor"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:max_factor", 3.0)
            valueLabel: value.toFixed(1) + "x"
            from: 1.5
            to: 10.0
            stepSize: 0.5
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:shake:max_factor", Math.round(v * 10) / 10)
        }

        SliderRow {
            last: true
            visible: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:enabled"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:enabled"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:enabled", true)
            varKey: "plugin:dynamic-cursors:shake:speed"
            label: qsTr("Shake Growth Speed")
            subtext: qsTr("How quickly the cursor grows during rapid movement")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:shake:speed"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:shake:speed"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:shake:speed", 4.0)
            valueLabel: value.toFixed(1)
            from: 1.0
            to: 10.0
            stepSize: 0.5
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:shake:speed", Math.round(v * 10) / 10)
        }

        SectionHeader {
            text: qsTr("Tilt Mode Physics")
        }

        SliderRow {
            first: true
            varKey: "plugin:dynamic-cursors:tilt:limit"
            label: qsTr("Tilt Angle Limit")
            subtext: qsTr("Maximum tilt angle in degrees")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:tilt:limit"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:tilt:limit"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:tilt:limit", 5000)
            valueLabel: (value / 100).toFixed(0) + "°"
            from: 1000
            to: 8000
            stepSize: 500
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:tilt:limit", Math.round(v))
        }

        SliderRow {
            last: true
            varKey: "plugin:dynamic-cursors:tilt:multiplier"
            label: qsTr("Tilt Speed Multiplier")
            subtext: qsTr("Sensitivity of tilt to cursor acceleration")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:tilt:multiplier"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:tilt:multiplier"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:tilt:multiplier", 100)
            valueLabel: (value / 100).toFixed(1) + "x"
            from: 20
            to: 300
            stepSize: 10
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:tilt:multiplier", Math.round(v))
        }

        SectionHeader {
            text: qsTr("Rotate Mode Physics")
        }

        SliderRow {
            first: true
            varKey: "plugin:dynamic-cursors:rotate:length"
            label: qsTr("Stick Virtual Length")
            subtext: qsTr("Simulated distance from cursor tip to origin point in pixels")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:rotate:length"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:rotate:length"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:rotate:length", 20)
            valueLabel: value + "px"
            from: 5
            to: 80
            stepSize: 1
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:rotate:length", Math.round(v))
        }

        SliderRow {
            last: true
            varKey: "plugin:dynamic-cursors:rotate:offset"
            label: qsTr("Stick Base Offset Angle")
            subtext: qsTr("Base angle offset in degrees relative to the pointer tip")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:rotate:offset"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:rotate:offset"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:rotate:offset", 0.0)
            valueLabel: value.toFixed(0) + "°"
            from: -180.0
            to: 180.0
            stepSize: 5.0
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:rotate:offset", Math.round(v))
        }

        SectionHeader {
            text: qsTr("Stretch Mode Physics")
        }

        SliderRow {
            first: true
            varKey: "plugin:dynamic-cursors:stretch:limit"
            label: qsTr("Stretch Length Limit")
            subtext: qsTr("Maximum stretching multiplier along motion vector")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:stretch:limit"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:stretch:limit"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:stretch:limit", 3000)
            valueLabel: (value / 1000).toFixed(1) + "x"
            from: 1000
            to: 6000
            stepSize: 200
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:stretch:limit", Math.round(v))
        }

        SliderRow {
            last: true
            varKey: "plugin:dynamic-cursors:stretch:function"
            label: qsTr("Stretch Curve Factor")
            subtext: qsTr("Non-linear response curve for comic stretching")
            value: CaelestiaVars.pendingVars["plugin:dynamic-cursors:stretch:function"] ?? CaelestiaVars.currentVars["plugin:dynamic-cursors:stretch:function"] ?? HyprlandSchema.getDefault("plugin:dynamic-cursors:stretch:function", 1.0)
            valueLabel: value.toFixed(1)
            from: 0.5
            to: 3.0
            stepSize: 0.1
            onMoved: v => CaelestiaVars.set("plugin:dynamic-cursors:stretch:function", Math.round(v * 10) / 10)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
