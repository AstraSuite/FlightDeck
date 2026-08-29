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

    title: qsTr("Mouse & pointer")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Pointer Sensitivity & Acceleration")
        }

        SliderRow {
            first: true
            varKey: "mouseSensitivity"
            label: qsTr("Mouse Sensitivity")
            subtext: qsTr("Pointer speed multiplier (-1.0 to 1.0, 0 is standard)")
            value: CaelestiaVars.pendingVars.mouseSensitivity ?? CaelestiaVars.currentVars.mouseSensitivity ?? CaelestiaVars.getDefault("mouseSensitivity", 0.0)
            valueLabel: (value > 0 ? "+" : "") + value.toFixed(2)
            from: -1.0
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("mouseSensitivity", Math.round(v * 100) / 100)
        }

        OptionRow {
            last: true
            varKey: "mouseAccelProfile"
            text: qsTr("Acceleration Profile")
            subtext: qsTr("Pointer acceleration curve behavior")
            options: [
                { value: "", label: "Default" },
                { value: "flat", label: "Flat (No acceleration)" },
                { value: "adaptive", label: "Adaptive" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.mouseAccelProfile ?? CaelestiaVars.currentVars.mouseAccelProfile ?? CaelestiaVars.getDefault("mouseAccelProfile", "");
                var match = options.find(o => o.value === cur);
                return match ? match.label : (cur || "Default");
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("mouseAccelProfile", val)
        }

        SectionHeader {
            text: qsTr("Scrolling & Buttons")
        }

        ToggleRow {
            first: true
            varKey: "mouseNaturalScroll"
            text: qsTr("Natural Scrolling")
            subtext: qsTr("Invert mouse wheel scroll direction")
            checked: CaelestiaVars.pendingVars.mouseNaturalScroll ?? CaelestiaVars.currentVars.mouseNaturalScroll ?? CaelestiaVars.getDefault("mouseNaturalScroll", false)
            onToggled: CaelestiaVars.set("mouseNaturalScroll", checked)
        }

        SliderRow {
            varKey: "mouseScrollFactor"
            label: qsTr("Scroll Factor")
            subtext: qsTr("Multiplier for mouse wheel scroll speed")
            value: CaelestiaVars.pendingVars.mouseScrollFactor ?? CaelestiaVars.currentVars.mouseScrollFactor ?? CaelestiaVars.getDefault("mouseScrollFactor", 1.0)
            valueLabel: value.toFixed(1) + "x"
            from: 0.1
            to: 5.0
            stepSize: 0.1
            onMoved: v => CaelestiaVars.set("mouseScrollFactor", Math.round(v * 10) / 10)
        }

        ToggleRow {
            last: true
            varKey: "leftHandedMode"
            text: qsTr("Left-Handed Mode")
            subtext: qsTr("Swap left and right mouse buttons")
            checked: CaelestiaVars.pendingVars.leftHandedMode ?? CaelestiaVars.currentVars.leftHandedMode ?? CaelestiaVars.getDefault("leftHandedMode", false)
            onToggled: CaelestiaVars.set("leftHandedMode", checked)
        }

        SectionHeader {
            text: qsTr("Focus & Cursor Behavior")
        }

        OptionRow {
            first: true
            varKey: "followMouse"
            text: qsTr("Window Focus Follows Mouse")
            subtext: qsTr("Focus windows on pointer hover")
            options: [
                { value: 0, label: "Disabled (Click to focus)" },
                { value: 1, label: "Full (Instant focus on hover)" },
                { value: 2, label: "Loose (Focus on hover, cursor retained)" },
                { value: 3, label: "Loose without mouse focus" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.followMouse ?? CaelestiaVars.currentVars.followMouse ?? CaelestiaVars.getDefault("followMouse", 1);
                var match = options.find(o => o.value === cur);
                return match ? match.label : "Full";
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("followMouse", val)
        }

        ToggleRow {
            varKey: "mouseRefocus"
            text: qsTr("Mouse Refocus")
            subtext: qsTr("Re-focus the window under cursor when switching workspaces")
            checked: CaelestiaVars.pendingVars.mouseRefocus ?? CaelestiaVars.currentVars.mouseRefocus ?? CaelestiaVars.getDefault("mouseRefocus", false)
            onToggled: CaelestiaVars.set("mouseRefocus", checked)
        }

        OptionRow {
            last: true
            varKey: "floatSwitchOverrideFocus"
            text: qsTr("Float Switch Focus Override")
            subtext: qsTr("Focus window under cursor when toggling tiled and floating")
            options: [
                { value: 0, label: "Disabled" },
                { value: 1, label: "Enabled" },
                { value: 2, label: "Enabled (also unfocuses)" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.floatSwitchOverrideFocus ?? CaelestiaVars.currentVars.floatSwitchOverrideFocus ?? CaelestiaVars.getDefault("floatSwitchOverrideFocus", 1);
                var match = options.find(o => o.value === cur);
                return match ? match.label : "Enabled";
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("floatSwitchOverrideFocus", val)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
