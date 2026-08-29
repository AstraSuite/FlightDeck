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

    title: qsTr("Window styling & layout")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Opacity")
        }

        SliderRow {
            first: true
            varKey: "activeWindowOpacity"
            label: qsTr("Active Window Opacity")
            subtext: qsTr("Opacity of currently focused active window")
            value: CaelestiaVars.pendingVars.activeWindowOpacity ?? CaelestiaVars.currentVars.activeWindowOpacity ?? CaelestiaVars.getDefault("activeWindowOpacity", 0.95)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.1
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("activeWindowOpacity", Math.round(v * 100) / 100)
        }

        SliderRow {
            varKey: "inactiveWindowOpacity"
            label: qsTr("Inactive Window Opacity")
            subtext: qsTr("Opacity of background and unfocused windows")
            value: CaelestiaVars.pendingVars.inactiveWindowOpacity ?? CaelestiaVars.currentVars.inactiveWindowOpacity ?? CaelestiaVars.getDefault("inactiveWindowOpacity", 0.95)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.1
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("inactiveWindowOpacity", Math.round(v * 100) / 100)
        }

        SliderRow {
            last: true
            varKey: "fullscreenOpacity"
            label: qsTr("Fullscreen Opacity")
            subtext: qsTr("Opacity applied when a window enters fullscreen mode")
            value: CaelestiaVars.pendingVars.fullscreenOpacity ?? CaelestiaVars.currentVars.fullscreenOpacity ?? CaelestiaVars.getDefault("fullscreenOpacity", 1.0)
            valueLabel: Math.round(value * 100) + "%"
            from: 0.1
            to: 1.0
            stepSize: 0.05
            onMoved: v => CaelestiaVars.set("fullscreenOpacity", Math.round(v * 100) / 100)
        }

        SectionHeader {
            text: qsTr("Window Borders")
        }

        StepperRow {
            first: true
            varKey: "windowBorderSize"
            label: qsTr("Border Width")
            subtext: qsTr("Width of client window border lines in pixels")
            value: CaelestiaVars.pendingVars.windowBorderSize ?? CaelestiaVars.currentVars.windowBorderSize ?? CaelestiaVars.getDefault("windowBorderSize", 1)
            from: 0
            to: 20
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("windowBorderSize", v)
        }

        ToggleRow {
            varKey: "resizeOnBorder"
            text: qsTr("Resize on Border")
            subtext: qsTr("Click and drag on window borders to resize")
            checked: CaelestiaVars.pendingVars.resizeOnBorder ?? CaelestiaVars.currentVars.resizeOnBorder ?? CaelestiaVars.getDefault("resizeOnBorder", true)
            onToggled: CaelestiaVars.set("resizeOnBorder", checked)
        }

        StepperRow {
            visible: CaelestiaVars.pendingVars.resizeOnBorder ?? CaelestiaVars.currentVars.resizeOnBorder ?? CaelestiaVars.getDefault("resizeOnBorder", true)
            varKey: "extendBorderGrabArea"
            label: qsTr("Extend Border Grab Area")
            subtext: qsTr("Area around border for click and drag resizing")
            value: CaelestiaVars.pendingVars.extendBorderGrabArea ?? CaelestiaVars.currentVars.extendBorderGrabArea ?? CaelestiaVars.getDefault("extendBorderGrabArea", 15)
            from: 0
            to: 50
            stepSize: 1
            suffix: "px"
            onMoved: v => CaelestiaVars.set("extendBorderGrabArea", v)
        }

        ToggleRow {
            visible: CaelestiaVars.pendingVars.resizeOnBorder ?? CaelestiaVars.currentVars.resizeOnBorder ?? CaelestiaVars.getDefault("resizeOnBorder", true)
            varKey: "hoverIconOnBorder"
            text: qsTr("Hover Icon on Border")
            subtext: qsTr("Show resize cursor icon when hovering window borders")
            checked: CaelestiaVars.pendingVars.hoverIconOnBorder ?? CaelestiaVars.currentVars.hoverIconOnBorder ?? CaelestiaVars.getDefault("hoverIconOnBorder", true)
            onToggled: CaelestiaVars.set("hoverIconOnBorder", checked)
        }

        OptionRow {
            varKey: "layout"
            text: qsTr("Tiling Layout")
            subtext: qsTr("Primary tiling layout algorithm")
            options: [
                { value: "dwindle", label: "Dwindle" },
                { value: "master", label: "Master" },
                { value: "scrolling", label: "Scrolling" },
                { value: "monocle", label: "Monocle" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.layout ?? CaelestiaVars.currentVars.layout ?? CaelestiaVars.getDefault("layout", "dwindle");
                var match = options.find(o => o.value === cur);
                return match ? match.label : cur;
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("layout", val)
        }

        ToggleRow {
            varKey: "allowTearing"
            text: qsTr("Allow Screen Tearing")
            subtext: qsTr("Allow tearing for reduced input latency in fullscreen games")
            checked: CaelestiaVars.pendingVars.allowTearing ?? CaelestiaVars.currentVars.allowTearing ?? CaelestiaVars.getDefault("allowTearing", false)
            onToggled: CaelestiaVars.set("allowTearing", checked)
        }

        ColorPickerDialogRow {
            rootParent: root.modalOverlay
            varKey: "activeWindowBorderColour"
            label: qsTr("Active Border Color")
        }

        ColorPickerDialogRow {
            rootParent: root.modalOverlay
            last: true
            varKey: "inactiveWindowBorderColour"
            label: qsTr("Inactive Border Color")
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
