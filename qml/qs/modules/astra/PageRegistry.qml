pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var pages: [
        // Look & Feel
        {
            label: qsTr("Appearance & windows"),
            icon: "palette",
            description: qsTr("Window styling, gaps, opacity, rounding, blur, shadows, and snapping"),
            category: "look_and_feel"
        },
        {
            label: qsTr("Animations"),
            icon: "motion_photos_on",
            description: qsTr("Bezier curves, durations, and animation presets"),
            category: "look_and_feel"
        },
        {
            label: qsTr("Cursor & pointer"),
            icon: "mouse",
            description: qsTr("Cursor themes, hardware rendering, warps, and visibility"),
            category: "look_and_feel"
        },

        // Input
        {
            label: qsTr("Keyboard shortcuts"),
            icon: "keyboard",
            description: qsTr("System bindings, application launchers, and custom keybinds"),
            category: "input"
        },
        {
            label: qsTr("Input devices"),
            icon: "touchpad_mouse",
            description: qsTr("Keyboard, mouse, touchpad, and workspace swipe gestures"),
            category: "input"
        },

        // Display
        {
            label: qsTr("Displays & monitors"),
            icon: "desktop_windows",
            description: qsTr("Display arrangement, resolution, scale, and VRR settings"),
            category: "display"
        },

        // Rules
        {
            label: qsTr("Window rules"),
            icon: "web_asset",
            description: qsTr("Match window criteria, float, pin, and opacity"),
            category: "rules"
        },
        {
            label: qsTr("Layer rules"),
            icon: "layers",
            description: qsTr("Blur and animation rules for desktop layers"),
            category: "rules"
        },

        // Extensions
        {
            label: qsTr("Plugins & extensions"),
            icon: "extension",
            description: qsTr("Hyprland plugins, dynamic cursors, and physics"),
            category: "plugins"
        },

        // Startup
        {
            label: qsTr("Autostart"),
            icon: "rocket_launch",
            description: qsTr("Launch apps and scripts on compositor startup"),
            category: "startup"
        },

        // System
        {
            label: qsTr("Profiles & backup"),
            icon: "folder_zip",
            description: qsTr("Create and restore config snapshots"),
            category: "system"
        },
        {
            label: qsTr("Pending changes"),
            icon: "difference",
            description: qsTr("Review diffs and apply live to Hyprland"),
            category: "system"
        },
        {
            label: qsTr("System & compositor"),
            icon: "settings",
            description: qsTr("XWayland, default apps, compositor behavior, and theme sync"),
            category: "system"
        },
        {
            label: qsTr("About"),
            icon: "info",
            description: qsTr("Compositor status and credits"),
            category: "system"
        }
    ]
}
