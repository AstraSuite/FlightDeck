pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var pages: [
        // Look & Feel
        {
            label: qsTr("Appearance"),
            icon: "palette",
            description: qsTr("Window styling, gaps, opacity, rounding, blur, shadows"),
            category: "look_and_feel"
        },
        {
            label: qsTr("Animations"),
            icon: "motion_photos_on",
            description: qsTr("Bezier curves, durations, and animation presets"),
            category: "look_and_feel"
        },
        {
            label: qsTr("Cursor Theme"),
            icon: "mouse",
            description: qsTr("Hyprcursor and XCursor theme and size options"),
            category: "look_and_feel"
        },

        // Input
        {
            label: qsTr("Keybinds"),
            icon: "keyboard",
            description: qsTr("Configure system and application shortcuts"),
            category: "input"
        },
        {
            label: qsTr("Touchpad & Gestures"),
            icon: "touchpad_mouse",
            description: qsTr("Touchpad settings and workspace swipe gestures"),
            category: "input"
        },

        // Display
        {
            label: qsTr("Monitors"),
            icon: "desktop_windows",
            description: qsTr("Arrange displays, set resolution, scale, and VRR"),
            category: "display"
        },

        // Rules
        {
            label: qsTr("Window Rules"),
            icon: "web_asset",
            description: qsTr("Match window criteria, float, pin, and opacity"),
            category: "rules"
        },
        {
            label: qsTr("Layer Rules"),
            icon: "layers",
            description: qsTr("Blur and animation rules for desktop layers"),
            category: "rules"
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
            label: qsTr("Profiles & Backup"),
            icon: "folder_zip",
            description: qsTr("Create and restore config snapshots"),
            category: "system"
        },
        {
            label: qsTr("Pending Changes"),
            icon: "difference",
            description: qsTr("Review diffs and apply live to Hyprland"),
            category: "system"
        },
        {
            label: qsTr("Settings"),
            icon: "settings",
            description: qsTr("App settings, window behavior, and theme syncing"),
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
