pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var items: [
        // Appearance
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Active Window Border Color",
            breadcrumb: "Appearance › Window Borders",
            subtext: "Primary active window outline color",
            icon: "border_style",
            type: "option",
            varKey: "activeBorderColor"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Inactive Window Border Color",
            breadcrumb: "Appearance › Window Borders",
            subtext: "Inactive unfocused window border color",
            icon: "border_style",
            type: "option",
            varKey: "inactiveBorderColor"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Window Border Width",
            breadcrumb: "Appearance › Window Borders",
            subtext: "Thickness of window borders in pixels",
            icon: "line_weight",
            type: "stepper",
            varKey: "borderSize"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Window Rounding",
            breadcrumb: "Appearance › Gaps & Rounding",
            subtext: "Corner radius rounding for all client windows",
            icon: "rounded_corner",
            type: "stepper",
            varKey: "windowRounding"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Window Gaps (Inner)",
            breadcrumb: "Appearance › Gaps & Rounding",
            subtext: "Spacing between adjacent tiled windows",
            icon: "space_dashboard",
            type: "stepper",
            varKey: "windowGapInner"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Window Gaps (Outer)",
            breadcrumb: "Appearance › Gaps & Rounding",
            subtext: "Spacing between windows and screen edges",
            icon: "fullscreen_exit",
            type: "stepper",
            varKey: "windowGapOuter"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Active Window Opacity",
            breadcrumb: "Appearance › Window Opacity",
            subtext: "Transparency level of active focused window",
            icon: "opacity",
            type: "slider",
            varKey: "activeWindowOpacity"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Inactive Window Opacity",
            breadcrumb: "Appearance › Window Opacity",
            subtext: "Transparency level of background unfocused windows",
            icon: "opacity",
            type: "slider",
            varKey: "inactiveWindowOpacity"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Window Blur",
            breadcrumb: "Appearance › Blur & Shadows",
            subtext: "Enable or disable GPU background blur effect",
            icon: "blur_on",
            type: "toggle",
            varKey: "blurEnabled"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Blur Size",
            breadcrumb: "Appearance › Blur & Shadows",
            subtext: "Radius of the dual Kawase blur sampling pass",
            icon: "blur_circular",
            type: "stepper",
            varKey: "blurSize"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Blur Passes",
            breadcrumb: "Appearance › Blur & Shadows",
            subtext: "Number of blur sampling iterations",
            icon: "blur_linear",
            type: "stepper",
            varKey: "blurPasses"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Drop Shadows",
            breadcrumb: "Appearance › Blur & Shadows",
            subtext: "Render drop shadow effects under floating windows",
            icon: "filter_drama",
            type: "toggle",
            varKey: "shadowEnabled"
        },
        {
            pageIdx: 0,
            category: "Appearance",
            title: "Shadow Range",
            breadcrumb: "Appearance › Blur & Shadows",
            subtext: "Shadow spread size in pixels",
            icon: "blur_medium",
            type: "stepper",
            varKey: "shadowRange"
        },

        // Animations
        {
            pageIdx: 1,
            category: "Animations",
            title: "Bezier Curve Graphical Editor",
            breadcrumb: "Animations › Bezier Curves",
            subtext: "Interactive draggable cubic-bezier easing curve designer",
            icon: "draw",
            type: "action"
        },
        {
            pageIdx: 1,
            category: "Animations",
            title: "Caelestia Animation Preset",
            breadcrumb: "Animations › Presets",
            subtext: "Active Caelestia animation profile lua configuration",
            icon: "motion_photos_on",
            type: "option"
        },
        {
            pageIdx: 1,
            category: "Animations",
            title: "Window Animations",
            breadcrumb: "Animations › Animation Targets",
            subtext: "Window open, close, and transition animations",
            icon: "animation",
            type: "toggle"
        },
        {
            pageIdx: 1,
            category: "Animations",
            title: "Workspace Animations",
            breadcrumb: "Animations › Animation Targets",
            subtext: "Sliding workspace switch transitions",
            icon: "view_carousel",
            type: "toggle"
        },

        // Cursor Theme
        {
            pageIdx: 2,
            category: "Cursor Theme",
            title: "Active Cursor Theme",
            breadcrumb: "Cursor Theme › Themes",
            subtext: "System-wide Hyprcursor and XCursor theme",
            icon: "mouse",
            type: "option",
            varKey: "cursorTheme"
        },
        {
            pageIdx: 2,
            category: "Cursor Theme",
            title: "Cursor Size",
            breadcrumb: "Cursor Theme › Sizing",
            subtext: "Cursor pixel scale for pointer devices",
            icon: "photo_size_select_small",
            type: "stepper",
            varKey: "cursorSize"
        },

        // Keybinds
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Terminal Shortcut",
            breadcrumb: "Keybinds › Core Applications",
            subtext: "Shortcut key combination to launch terminal",
            icon: "terminal",
            type: "option",
            varKey: "kbTerminal"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Application Launcher",
            breadcrumb: "Keybinds › Core Applications",
            subtext: "Shortcut key combination to launch application menu",
            icon: "apps",
            type: "option",
            varKey: "kbLauncher"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Web Browser",
            breadcrumb: "Keybinds › Core Applications",
            subtext: "Shortcut key combination to launch web browser",
            icon: "language",
            type: "option",
            varKey: "kbBrowser"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "File Manager",
            breadcrumb: "Keybinds › Core Applications",
            subtext: "Shortcut key combination to launch file manager",
            icon: "folder",
            type: "option",
            varKey: "kbFileManager"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Close Active Window",
            breadcrumb: "Keybinds › Window Actions",
            subtext: "Shortcut key combination to close active focused window",
            icon: "close",
            type: "option",
            varKey: "kbCloseWindow"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Toggle Floating Window",
            breadcrumb: "Keybinds › Window Actions",
            subtext: "Shortcut key combination to toggle window floating state",
            icon: "picture_in_picture_alt",
            type: "option",
            varKey: "kbToggleFloating"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Screen Lock",
            breadcrumb: "Keybinds › Utilities & Actions",
            subtext: "Shortcut key combination to lock session",
            icon: "lock",
            type: "option",
            varKey: "kbLock"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Screenshot (Snip)",
            breadcrumb: "Keybinds › Utilities & Actions",
            subtext: "Shortcut key combination to capture interactive screenshot region",
            icon: "screenshot_monitor",
            type: "option",
            varKey: "kbScreenshotSnip"
        },

        // Touchpad & Gestures
        {
            pageIdx: 4,
            category: "Touchpad & Gestures",
            title: "Touchpad Tap to Click",
            breadcrumb: "Touchpad & Gestures › Touchpad",
            subtext: "Tap surface to simulate left mouse button click",
            icon: "touch_app",
            type: "toggle",
            varKey: "tapToClick"
        },
        {
            pageIdx: 4,
            category: "Touchpad & Gestures",
            title: "Natural Scrolling",
            breadcrumb: "Touchpad & Gestures › Touchpad",
            subtext: "Invert scroll direction to match finger motion",
            icon: "swap_vert",
            type: "toggle",
            varKey: "naturalScroll"
        },
        {
            pageIdx: 4,
            category: "Touchpad & Gestures",
            title: "Disable While Typing (DWT)",
            breadcrumb: "Touchpad & Gestures › Touchpad",
            subtext: "Temporarily disable touchpad while typing on keyboard",
            icon: "keyboard_hide",
            type: "toggle",
            varKey: "dwt"
        },
        {
            pageIdx: 4,
            category: "Touchpad & Gestures",
            title: "Workspace Swipe Gestures",
            breadcrumb: "Touchpad & Gestures › Gestures",
            subtext: "Multi-finger swipe to switch workspaces",
            icon: "swipe",
            type: "toggle",
            varKey: "workspaceSwipe"
        },

        // Monitors
        {
            pageIdx: 5,
            category: "Monitors",
            title: "Visual Display Layout",
            breadcrumb: "Monitors › Arrange Displays",
            subtext: "Interactive 2D monitor layout, snapping, and positions",
            icon: "desktop_windows",
            type: "action"
        },
        {
            pageIdx: 5,
            category: "Monitors",
            title: "Display Scaling",
            breadcrumb: "Monitors › Connected Displays",
            subtext: "Display scale multiplier for hi-DPI panels",
            icon: "photo_size_select_large",
            type: "slider"
        },

        // Window Rules
        {
            pageIdx: 6,
            category: "Window Rules",
            title: "Add Window Rule",
            breadcrumb: "Window Rules › Management",
            subtext: "Create a new window match rule for floating, workspace, or opacity",
            icon: "web_asset",
            type: "action"
        },
        {
            pageIdx: 6,
            category: "Window Rules",
            title: "Configured Window Rules",
            breadcrumb: "Window Rules › Active Rules",
            subtext: "List and manage existing application window rules",
            icon: "list_alt",
            type: "action"
        },

        // Layer Rules
        {
            pageIdx: 7,
            category: "Layer Rules",
            title: "Add Layer Rule",
            breadcrumb: "Layer Rules › Management",
            subtext: "Configure blur, animation, and dimming for shell layer surfaces",
            icon: "layers",
            type: "action"
        },

        // Autostart
        {
            pageIdx: 8,
            category: "Autostart",
            title: "Add Application Autostart",
            breadcrumb: "Autostart › Applications",
            subtext: "Browse installed desktop applications to launch on boot",
            icon: "rocket_launch",
            type: "action"
        },

        // Profiles
        {
            pageIdx: 9,
            category: "Profiles & Backup",
            title: "Create Snapshot",
            breadcrumb: "Profiles & Backup › Snapshots",
            subtext: "Backup current configuration variables to named profile",
            icon: "save",
            type: "action"
        },

        // Pending Changes
        {
            pageIdx: 10,
            category: "Pending Changes",
            title: "Apply & Save to Disk",
            breadcrumb: "Pending Changes › Actions",
            subtext: "Write all pending changes to hypr-vars.lua and astra-helm.lua",
            icon: "save",
            type: "action"
        },
        {
            pageIdx: 10,
            category: "Pending Changes",
            title: "Test Live (IPC)",
            breadcrumb: "Pending Changes › Actions",
            subtext: "Send pending settings directly to Hyprland runtime without saving to disk",
            icon: "play_arrow",
            type: "action"
        },
        {
            pageIdx: 10,
            category: "Pending Changes",
            title: "Discard Changes",
            breadcrumb: "Pending Changes › Actions",
            subtext: "Revert all pending unsaved modifications",
            icon: "delete_sweep",
            type: "action"
        }
    ]
}
