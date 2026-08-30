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

    title: qsTr("Compositor behavior")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Activation & Focus")
        }

        ToggleRow {
            first: true
            varKey: "focusOnActivate"
            text: qsTr("Focus on Activate")
            subtext: qsTr("Automatically focus windows requesting user activation")
            checked: CaelestiaVars.pendingVars.focusOnActivate ?? CaelestiaVars.currentVars.focusOnActivate ?? CaelestiaVars.getDefault("focusOnActivate", false)
            onToggled: CaelestiaVars.set("focusOnActivate", checked)
        }

        ToggleRow {
            last: true
            varKey: "disableAutoreload"
            text: qsTr("Disable Config Autoreload")
            subtext: qsTr("Require manual config reload (hyprctl reload)")
            checked: CaelestiaVars.pendingVars.disableAutoreload ?? CaelestiaVars.currentVars.disableAutoreload ?? CaelestiaVars.getDefault("disableAutoreload", false)
            onToggled: CaelestiaVars.set("disableAutoreload", checked)
        }

        SectionHeader {
            text: qsTr("Animations & Motion Rendering")
        }

        ToggleRow {
            first: true
            varKey: "animateManualResizes"
            text: qsTr("Animate Manual Resizes")
            subtext: qsTr("Smooth animation when manually resizing windows")
            checked: CaelestiaVars.pendingVars.animateManualResizes ?? CaelestiaVars.currentVars.animateManualResizes ?? CaelestiaVars.getDefault("animateManualResizes", false)
            onToggled: CaelestiaVars.set("animateManualResizes", checked)
        }

        ToggleRow {
            last: true
            varKey: "animateMouseWindowDragging"
            text: qsTr("Animate Mouse Dragging")
            subtext: qsTr("Smooth animation when dragging windows with mouse")
            checked: CaelestiaVars.pendingVars.animateMouseWindowDragging ?? CaelestiaVars.currentVars.animateMouseWindowDragging ?? CaelestiaVars.getDefault("animateMouseWindowDragging", false)
            onToggled: CaelestiaVars.set("animateMouseWindowDragging", checked)
        }

        SectionHeader {
            text: qsTr("Refresh Rates & Power Management")
        }

        ToggleRow {
            first: true
            varKey: "vfr"
            text: qsTr("Variable Frame Rate (VFR)")
            subtext: qsTr("Lower power consumption when screen is idle")
            checked: CaelestiaVars.pendingVars.vfr ?? CaelestiaVars.currentVars.vfr ?? CaelestiaVars.getDefault("vfr", true)
            onToggled: CaelestiaVars.set("vfr", checked)
        }

        OptionRow {
            varKey: "vrr"
            text: qsTr("Variable Refresh Rate (VRR / Adaptive Sync)")
            subtext: qsTr("Adaptive sync mode for compatible displays")
            options: [
                { value: 0, label: "Off" },
                { value: 1, label: "On" },
                { value: 2, label: "Fullscreen Only" },
                { value: 3, label: "Fullscreen (Game Content)" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.vrr ?? CaelestiaVars.currentVars.vrr ?? CaelestiaVars.getDefault("vrr", 0);
                var match = options.find(o => o.value === cur);
                return match ? match.label : "Off";
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("vrr", val)
        }

        ToggleRow {
            varKey: "mouseMoveEnablesDpms"
            text: qsTr("Mouse Move Wakes Display")
            subtext: qsTr("Wake display from sleep when moving the mouse")
            checked: CaelestiaVars.pendingVars.mouseMoveEnablesDpms ?? CaelestiaVars.currentVars.mouseMoveEnablesDpms ?? CaelestiaVars.getDefault("mouseMoveEnablesDpms", false)
            onToggled: CaelestiaVars.set("mouseMoveEnablesDpms", checked)
        }

        ToggleRow {
            last: true
            varKey: "keyPressEnablesDpms"
            text: qsTr("Key Press Wakes Display")
            subtext: qsTr("Wake display from sleep when pressing any keyboard key")
            checked: CaelestiaVars.pendingVars.keyPressEnablesDpms ?? CaelestiaVars.currentVars.keyPressEnablesDpms ?? CaelestiaVars.getDefault("keyPressEnablesDpms", false)
            onToggled: CaelestiaVars.set("keyPressEnablesDpms", checked)
        }

        SectionHeader {
            text: qsTr("Wallpaper & Logo Rendering")
        }

        ToggleRow {
            first: true
            varKey: "disableHyprlandLogo"
            text: qsTr("Disable Hyprland Logo")
            subtext: qsTr("Hide Hyprland logo on default wallpaper")
            checked: CaelestiaVars.pendingVars.disableHyprlandLogo ?? CaelestiaVars.currentVars.disableHyprlandLogo ?? CaelestiaVars.getDefault("disableHyprlandLogo", false)
            onToggled: CaelestiaVars.set("disableHyprlandLogo", checked)
        }

        ToggleRow {
            varKey: "disableSplashRendering"
            text: qsTr("Disable Splash Text")
            subtext: qsTr("Hide splash quotes text on default wallpaper")
            checked: CaelestiaVars.pendingVars.disableSplashRendering ?? CaelestiaVars.currentVars.disableSplashRendering ?? CaelestiaVars.getDefault("disableSplashRendering", false)
            onToggled: CaelestiaVars.set("disableSplashRendering", checked)
        }

        OptionRow {
            last: true
            varKey: "forceDefaultWallpaper"
            text: qsTr("Force Default Wallpaper")
            subtext: qsTr("Default anime wallpaper selection")
            options: [
                { value: -1, label: "Random Wallpaper" },
                { value: 0, label: "Anime Girl (Dark)" },
                { value: 1, label: "Anime Girl (Light)" },
                { value: 2, label: "Anime Girl (Blue)" }
            ]
            currentValue: {
                var cur = CaelestiaVars.pendingVars.forceDefaultWallpaper ?? CaelestiaVars.currentVars.forceDefaultWallpaper ?? CaelestiaVars.getDefault("forceDefaultWallpaper", -1);
                var match = options.find(o => o.value === cur);
                return match ? match.label : "Random Wallpaper";
            }
            onOptionSelected: (val, label) => CaelestiaVars.set("forceDefaultWallpaper", val)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
