pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property var items: [
        // Appearance - Subpage 1: Window styling & layout
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Active Window Border Color",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Primary active window outline color",
            icon: "border_style",
            type: "option",
            varKey: "activeWindowBorderColour"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Inactive Window Border Color",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Inactive unfocused window border color",
            icon: "border_style",
            type: "option",
            varKey: "inactiveWindowBorderColour"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Window Border Width",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Thickness of window borders in pixels",
            icon: "line_weight",
            type: "stepper",
            varKey: "windowBorderSize"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Resize on Border",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Resize windows by dragging on their borders",
            icon: "drag_pan",
            type: "toggle",
            varKey: "resizeOnBorder"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Tiling Layout",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Set default layout engine (Dwindle, Master, Scrolling, Monocle)",
            icon: "view_quilt",
            type: "option",
            varKey: "layout"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Allow Screen Tearing",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Allow tearing for lowest input lag in fullscreen games",
            icon: "speed",
            type: "toggle",
            varKey: "allowTearing"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Active Window Opacity",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Transparency level of active focused window",
            icon: "opacity",
            type: "slider",
            varKey: "activeWindowOpacity"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Inactive Window Opacity",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Transparency level of background unfocused windows",
            icon: "opacity",
            type: "slider",
            varKey: "inactiveWindowOpacity"
        },
        {
            pageIdx: 0,
            subPageIdx: 1,
            category: "Appearance",
            title: "Fullscreen Window Opacity",
            breadcrumb: "Appearance › Window styling & layout",
            subtext: "Opacity for fullscreen application windows",
            icon: "fullscreen",
            type: "slider",
            varKey: "fullscreenOpacity"
        },

        // Appearance - Subpage 2: Gaps & rounding
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Window Rounding",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Corner radius rounding for all client windows",
            icon: "rounded_corner",
            type: "stepper",
            varKey: "windowRounding"
        },
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Corner Rounding Power",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Exponent curve power for corner rounding",
            icon: "rounded_corner",
            type: "slider",
            varKey: "windowRoundingPower"
        },
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Inner Window Gaps",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Spacing between adjacent tiled windows",
            icon: "space_dashboard",
            type: "stepper",
            varKey: "windowGapsIn"
        },
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Outer Window Gaps",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Spacing between windows and screen edges",
            icon: "fullscreen_exit",
            type: "stepper",
            varKey: "windowGapsOut"
        },
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Single Window Gaps",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Outer gap when only a single window is open on a workspace",
            icon: "fullscreen",
            type: "stepper",
            varKey: "singleWindowGapsOut"
        },
        {
            pageIdx: 0,
            subPageIdx: 2,
            category: "Appearance",
            title: "Workspace Gaps",
            breadcrumb: "Appearance › Gaps & rounding",
            subtext: "Spacing around workspaces overview",
            icon: "view_compact",
            type: "stepper",
            varKey: "workspaceGaps"
        },

        // Appearance - Subpage 3: Dimming & snapping
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Dim Inactive Windows",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Dim unfocused background windows",
            icon: "brightness_medium",
            type: "toggle",
            varKey: "dimInactive"
        },
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Dim Around Floating Windows",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Darken background when modal dialogs or floating windows are open",
            icon: "vignette",
            type: "slider",
            varKey: "dimAround"
        },
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Dim Special Workspace",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Dim screen when special scratchpad workspace is open",
            icon: "exposure",
            type: "slider",
            varKey: "dimSpecial"
        },
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Floating Window Snapping",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Snap floating windows to other windows and monitor edges",
            icon: "fit_screen",
            type: "toggle",
            varKey: "snapEnabled"
        },
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Window Snap Gap",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Minimum distance to snap to neighboring windows",
            icon: "straighten",
            type: "stepper",
            varKey: "snapWindowGap"
        },
        {
            pageIdx: 0,
            subPageIdx: 3,
            category: "Appearance",
            title: "Monitor Edge Snap Gap",
            breadcrumb: "Appearance › Dimming & snapping",
            subtext: "Minimum distance to snap to display edges",
            icon: "border_all",
            type: "stepper",
            varKey: "snapMonitorGap"
        },

        // Appearance - Subpage 4: Blur effects
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Window Blur",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Enable or disable GPU background blur effect",
            icon: "blur_on",
            type: "toggle",
            varKey: "blurEnabled"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Size",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Radius of the dual Kawase blur sampling pass",
            icon: "blur_circular",
            type: "stepper",
            varKey: "blurSize"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Passes",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Number of blur sampling iterations",
            icon: "blur_linear",
            type: "stepper",
            varKey: "blurPasses"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Ignore Opacity",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Blur transparent surfaces behind windows regardless of window opacity",
            icon: "blur_on",
            type: "toggle",
            varKey: "blurIgnoreOpacity"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur X-Ray",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Floating windows ignore tiled windows in blur calculations",
            icon: "visibility",
            type: "toggle",
            varKey: "blurXray"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Noise",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Noise texture applied to blur surface",
            icon: "grain",
            type: "slider",
            varKey: "blurNoise"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Contrast",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Contrast modulation for blur filter",
            icon: "contrast",
            type: "slider",
            varKey: "blurContrast"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Brightness",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Brightness modulation for blur filter",
            icon: "brightness_medium",
            type: "slider",
            varKey: "blurBrightness"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Vibrancy",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Saturation boost of blurred colors",
            icon: "palette",
            type: "slider",
            varKey: "blurVibrancy"
        },
        {
            pageIdx: 0,
            subPageIdx: 4,
            category: "Appearance",
            title: "Blur Popups & Menus",
            breadcrumb: "Appearance › Blur effects",
            subtext: "Apply blur filter to context menus and popups",
            icon: "filter",
            type: "toggle",
            varKey: "blurPopups"
        },

        // Appearance - Subpage 5: Drop shadows
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Drop Shadows",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Render drop shadow effects under floating windows",
            icon: "filter_drama",
            type: "toggle",
            varKey: "shadowEnabled"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Active Shadow Color",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Drop shadow color for focused windows",
            icon: "palette",
            type: "option",
            varKey: "shadowColour"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Inactive Shadow Color",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Drop shadow color for unfocused windows",
            icon: "palette",
            type: "option",
            varKey: "inactiveShadowColour"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Shadow Range",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Shadow spread size in pixels",
            icon: "blur_medium",
            type: "stepper",
            varKey: "shadowRange"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Shadow Render Power",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Shadow falloff power exponent (1 - 4)",
            icon: "tune",
            type: "stepper",
            varKey: "shadowRenderPower"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Shadow Scale",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Configure drop shadow relative scale factor",
            icon: "filter_drama",
            type: "slider",
            varKey: "shadowScale"
        },
        {
            pageIdx: 0,
            subPageIdx: 5,
            category: "Appearance",
            title: "Shadow Offset",
            breadcrumb: "Appearance › Drop shadows",
            subtext: "Configure drop shadow position offset in pixels",
            icon: "straighten",
            type: "textfield",
            varKey: "shadowOffset"
        },

        // Animations (PageIdx: 1)
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

        // Cursor Theme (PageIdx: 2)
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Active Cursor Theme",
            breadcrumb: "Cursor & pointer › Themes",
            subtext: "System-wide Hyprcursor and XCursor theme",
            icon: "mouse",
            type: "option",
            varKey: "cursorTheme"
        },
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Cursor Size",
            breadcrumb: "Cursor & pointer › Sizing",
            subtext: "Cursor pixel scale for pointer devices",
            icon: "photo_size_select_small",
            type: "stepper",
            varKey: "cursorSize"
        },
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Hardware Cursors",
            breadcrumb: "Cursor & pointer › Rendering",
            subtext: "Use hardware DRM planes for cursor rendering",
            icon: "mouse",
            type: "toggle",
            varKey: "cursorNoHardwareCursors"
        },
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Enable Hyprcursor",
            breadcrumb: "Cursor & pointer › Rendering",
            subtext: "Hardware-accelerated vector shape animated cursor format",
            icon: "mouse",
            type: "toggle",
            varKey: "cursorEnableHyprcursor"
        },
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Disable Cursor Warps",
            breadcrumb: "Cursor & pointer › Warping",
            subtext: "Prevent cursor from jumping when switching focus or workspace",
            icon: "near_me_disabled",
            type: "toggle",
            varKey: "cursorNoWarps"
        },
        {
            pageIdx: 2,
            category: "Cursor & pointer",
            title: "Cursor Inactive Timeout",
            breadcrumb: "Cursor & pointer › Visibility",
            subtext: "Hide cursor after inactivity period in seconds",
            icon: "visibility_off",
            type: "stepper",
            varKey: "cursorInactiveTimeout"
        },

        // Keybinds (PageIdx: 3)
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Terminal Shortcut",
            breadcrumb: "Keyboard shortcuts › Core Applications",
            subtext: "Shortcut key combination to launch terminal",
            icon: "terminal",
            type: "option",
            varKey: "kbTerminal"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Application Launcher",
            breadcrumb: "Keyboard shortcuts › Core Applications",
            subtext: "Shortcut key combination to launch application menu",
            icon: "apps",
            type: "option",
            varKey: "kbLauncher"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Web Browser",
            breadcrumb: "Keyboard shortcuts › Core Applications",
            subtext: "Shortcut key combination to launch web browser",
            icon: "language",
            type: "option",
            varKey: "kbBrowser"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "File Manager",
            breadcrumb: "Keyboard shortcuts › Core Applications",
            subtext: "Shortcut key combination to launch file manager",
            icon: "folder",
            type: "option",
            varKey: "kbFileManager"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Close Active Window",
            breadcrumb: "Keyboard shortcuts › Window Actions",
            subtext: "Shortcut key combination to close active focused window",
            icon: "close",
            type: "option",
            varKey: "kbCloseWindow"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Toggle Floating Window",
            breadcrumb: "Keyboard shortcuts › Window Actions",
            subtext: "Shortcut key combination to toggle window floating state",
            icon: "picture_in_picture_alt",
            type: "option",
            varKey: "kbToggleFloating"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Screen Lock",
            breadcrumb: "Keyboard shortcuts › Utilities & Actions",
            subtext: "Shortcut key combination to lock session",
            icon: "lock",
            type: "option",
            varKey: "kbLock"
        },
        {
            pageIdx: 3,
            category: "Keybinds",
            title: "Screenshot (Snip)",
            breadcrumb: "Keyboard shortcuts › Utilities & Actions",
            subtext: "Shortcut key combination to capture interactive screenshot region",
            icon: "screenshot_monitor",
            type: "option",
            varKey: "kbScreenshotSnip"
        },

        // Input Devices (PageIdx: 4) - Subpage 1: Keyboard
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Keyboard Layout",
            breadcrumb: "Input devices › Keyboard",
            subtext: "Primary XKB keyboard layout (e.g. us, de, fr)",
            icon: "keyboard",
            type: "textfield",
            varKey: "kbLayout"
        },
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Keyboard Variant",
            breadcrumb: "Input devices › Keyboard",
            subtext: "XKB keyboard layout variant",
            icon: "keyboard",
            type: "textfield",
            varKey: "kbVariant"
        },
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Keyboard Options",
            breadcrumb: "Input devices › Keyboard",
            subtext: "XKB options (e.g. grp:alt_shift_toggle)",
            icon: "tune",
            type: "textfield",
            varKey: "kbOptions"
        },
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Numlock by Default",
            breadcrumb: "Input devices › Keyboard",
            subtext: "Activate NumLock automatically on compositor startup",
            icon: "pin",
            type: "toggle",
            varKey: "numlockByDefault"
        },
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Key Repeat Rate",
            breadcrumb: "Input devices › Keyboard",
            subtext: "Repeats per second when holding down a key",
            icon: "repeat",
            type: "stepper",
            varKey: "keyRepeatRate"
        },
        {
            pageIdx: 4,
            subPageIdx: 1,
            category: "Input devices",
            title: "Key Repeat Delay",
            breadcrumb: "Input devices › Keyboard",
            subtext: "Delay in milliseconds before key repeat begins",
            icon: "timer",
            type: "stepper",
            varKey: "keyRepeatDelay"
        },

        // Input Devices (PageIdx: 4) - Subpage 2: Mouse & pointer
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Mouse Sensitivity",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Pointer speed multiplier (-1.0 to 1.0)",
            icon: "speed",
            type: "slider",
            varKey: "mouseSensitivity"
        },
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Mouse Acceleration Profile",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Pointer acceleration behavior (Flat, Adaptive)",
            icon: "trending_up",
            type: "option",
            varKey: "mouseAccelProfile"
        },
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Window Focus Follows Mouse",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Focus windows on pointer hover (Disabled, Full, Loose)",
            icon: "ads_click",
            type: "option",
            varKey: "followMouse"
        },
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Mouse Natural Scrolling",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Invert mouse wheel scroll direction",
            icon: "swap_vert",
            type: "toggle",
            varKey: "mouseNaturalScroll"
        },
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Mouse Scroll Factor",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Multiplier for mouse wheel scroll speed",
            icon: "unfold_more",
            type: "slider",
            varKey: "mouseScrollFactor"
        },
        {
            pageIdx: 4,
            subPageIdx: 2,
            category: "Input devices",
            title: "Left-Handed Mode",
            breadcrumb: "Input devices › Mouse & pointer",
            subtext: "Swap left and right mouse buttons",
            icon: "pan_tool",
            type: "toggle",
            varKey: "leftHandedMode"
        },

        // Input Devices (PageIdx: 4) - Subpage 3: Touchpad & gestures
        {
            pageIdx: 4,
            subPageIdx: 3,
            category: "Input devices",
            title: "Disable While Typing",
            breadcrumb: "Input devices › Touchpad & gestures",
            subtext: "Temporarily disable touchpad while typing",
            icon: "keyboard_hide",
            type: "toggle",
            varKey: "touchpadDisableTyping"
        },
        {
            pageIdx: 4,
            subPageIdx: 3,
            category: "Input devices",
            title: "Touchpad Tap to Click",
            breadcrumb: "Input devices › Touchpad & gestures",
            subtext: "Tap surface to simulate clicks",
            icon: "touch_app",
            type: "toggle",
            varKey: "touchpadTapToClick"
        },
        {
            pageIdx: 4,
            subPageIdx: 3,
            category: "Input devices",
            title: "Touchpad Scroll Factor",
            breadcrumb: "Input devices › Touchpad & gestures",
            subtext: "Two-finger scroll sensitivity multiplier",
            icon: "swap_vert",
            type: "slider",
            varKey: "touchpadScrollFactor"
        },
        {
            pageIdx: 4,
            subPageIdx: 3,
            category: "Input devices",
            title: "Workspace Swipe Gestures",
            breadcrumb: "Input devices › Touchpad & gestures",
            subtext: "Multi-finger swipe to switch workspaces",
            icon: "swipe",
            type: "toggle",
            varKey: "workspaceSwipeCreateNew"
        },
        {
            pageIdx: 4,
            subPageIdx: 3,
            category: "Input devices",
            title: "Workspace Swipe Fingers",
            breadcrumb: "Input devices › Touchpad & gestures",
            subtext: "Number of fingers for workspace swipe",
            icon: "fingerprint",
            type: "stepper",
            varKey: "workspaceSwipeFingers"
        },

        // Monitors (PageIdx: 5)
        {
            pageIdx: 5,
            category: "Displays & monitors",
            title: "Visual Display Layout",
            breadcrumb: "Displays & monitors › Arrange Displays",
            subtext: "Interactive 2D monitor layout, snapping, and positions",
            icon: "desktop_windows",
            type: "action"
        },
        {
            pageIdx: 5,
            category: "Displays & monitors",
            title: "Display Scaling",
            breadcrumb: "Displays & monitors › Connected Displays",
            subtext: "Display scale multiplier for hi-DPI panels",
            icon: "photo_size_select_large",
            type: "slider"
        },

        // Window Rules (PageIdx: 6)
        {
            pageIdx: 6,
            category: "Window rules",
            title: "Add Window Rule",
            breadcrumb: "Window rules › Management",
            subtext: "Create a new window match rule for floating, workspace, or opacity",
            icon: "web_asset",
            type: "action"
        },
        {
            pageIdx: 6,
            category: "Window rules",
            title: "Configured Window Rules",
            breadcrumb: "Window rules › Active Rules",
            subtext: "List and manage existing application window rules",
            icon: "list_alt",
            type: "action"
        },

        // Layer Rules (PageIdx: 7)
        {
            pageIdx: 7,
            category: "Layer rules",
            title: "Add Layer Rule",
            breadcrumb: "Layer rules › Management",
            subtext: "Configure blur, animation, and dimming for shell layer surfaces",
            icon: "layers",
            type: "action"
        },

        // Autostart (PageIdx: 8)
        {
            pageIdx: 8,
            category: "Autostart",
            title: "Add Application Autostart",
            breadcrumb: "Autostart › Applications",
            subtext: "Browse installed desktop applications to launch on boot",
            icon: "rocket_launch",
            type: "action"
        },

        // Profiles (PageIdx: 9)
        {
            pageIdx: 9,
            category: "Profiles & backup",
            title: "Create Snapshot",
            breadcrumb: "Profiles & backup › Snapshots",
            subtext: "Backup current configuration variables to named profile",
            icon: "save",
            type: "action"
        },

        // Pending Changes (PageIdx: 10)
        {
            pageIdx: 10,
            category: "Pending changes",
            title: "Apply & Save to Disk",
            breadcrumb: "Pending changes › Actions",
            subtext: "Write all pending changes to hypr-vars.lua and astra-flightdeck.lua",
            icon: "save",
            type: "action"
        },
        {
            pageIdx: 10,
            category: "Pending changes",
            title: "Test Live (IPC)",
            breadcrumb: "Pending changes › Actions",
            subtext: "Send pending settings directly to Hyprland runtime without saving to disk",
            icon: "play_arrow",
            type: "action"
        },

        // System & Compositor (PageIdx: 11) - Subpage 1: Default apps
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Default Terminal",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Terminal emulator executable",
            icon: "terminal",
            type: "textfield",
            varKey: "terminal"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Web Browser",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Primary internet browser command",
            icon: "language",
            type: "textfield",
            varKey: "browser"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Code Editor",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Code editor command",
            icon: "code",
            type: "textfield",
            varKey: "editor"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "File Manager",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Graphical file manager",
            icon: "folder",
            type: "textfield",
            varKey: "fileExplorer"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Audio Mixer GUI",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Volume control interface executable",
            icon: "volume_up",
            type: "textfield",
            varKey: "audioSettings"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Volume Step Size",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Volume change percentage per step",
            icon: "tune",
            type: "slider",
            varKey: "volumeStep"
        },
        {
            pageIdx: 11,
            subPageIdx: 1,
            category: "System & compositor",
            title: "Maximum Volume Limit",
            breadcrumb: "System & compositor › Default applications",
            subtext: "Ceiling percentage for volume amplification",
            icon: "volume_up",
            type: "stepper",
            varKey: "volumeMax"
        },

        // System & Compositor (PageIdx: 11) - Subpage 2: XWayland & compatibility
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "XWayland Compatibility",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Enable XWayland for legacy X11 applications",
            icon: "application_x_executable",
            type: "toggle",
            varKey: "xwaylandEnabled"
        },
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "Force Zero Scaling",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Force apps to use Wayland-native scaling instead of X11 scaling",
            icon: "zoom_out_map",
            type: "toggle",
            varKey: "xwaylandForceZeroScaling"
        },
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "Nearest Neighbor Filter",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Pixelated scaling filter for upscaling low-res XWayland applications",
            icon: "filter_vintage",
            type: "toggle",
            varKey: "xwaylandUseNearestNeighbor"
        },
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "Disable Update News",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Suppress update notifications on new Hyprland versions",
            icon: "notifications_off",
            type: "toggle",
            varKey: "noUpdateNews"
        },
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "Disable Donation Nag",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Suppress periodic donation reminders",
            icon: "do_not_disturb_on",
            type: "toggle",
            varKey: "noDonationNag"
        },
        {
            pageIdx: 11,
            subPageIdx: 2,
            category: "System & compositor",
            title: "Enforce Permissions",
            breadcrumb: "System & compositor › XWayland & compatibility",
            subtext: "Enforce IPC client permission requirements",
            icon: "security",
            type: "toggle",
            varKey: "enforcePermissions"
        },

        // System & Compositor (PageIdx: 11) - Subpage 3: Theme sync & airlock
        {
            pageIdx: 11,
            subPageIdx: 3,
            category: "System & compositor",
            title: "Theme Synchronization",
            breadcrumb: "System & compositor › Theme sync & airlock",
            subtext: "Sync Material color scheme and shell tokens with Caelestia",
            icon: "palette",
            type: "toggle"
        },
        {
            pageIdx: 11,
            subPageIdx: 3,
            category: "System & compositor",
            title: "Airlock Greeter Integration",
            breadcrumb: "System & compositor › Theme sync & airlock",
            subtext: "Sync monitor setup, cursor theme, and input settings to greetd",
            icon: "lock",
            type: "action"
        },

        // System & Compositor (PageIdx: 11) - Subpage 4: Compositor behavior
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Focus on Activate",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Automatically switch focus to windows requesting activation",
            icon: "center_focus_strong",
            type: "toggle",
            varKey: "focusOnActivate"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Disable Config Autoreload",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Prevent automatic configuration reload on file change",
            icon: "sync_disabled",
            type: "toggle",
            varKey: "disableAutoreload"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Animate Manual Resizes",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Smooth window animation during interactive move and resize",
            icon: "animation",
            type: "toggle",
            varKey: "animateManualResizes"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Variable Frame Rate (VFR)",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Lower power consumption when screen is idle",
            icon: "bolt",
            type: "toggle",
            varKey: "vfr"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Variable Refresh Rate (VRR)",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Adaptive sync mode for compatible displays (G-Sync / FreeSync)",
            icon: "tv",
            type: "option",
            varKey: "vrr"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Disable Hyprland Logo",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Hide watermark logo on default desktop wallpaper",
            icon: "hide_image",
            type: "toggle",
            varKey: "disableHyprlandLogo"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Disable Splash Text",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Hide splash quotes text on default wallpaper",
            icon: "format_quote",
            type: "toggle",
            varKey: "disableSplashRendering"
        },
        {
            pageIdx: 11,
            subPageIdx: 4,
            category: "System & compositor",
            title: "Force Default Wallpaper",
            breadcrumb: "System & compositor › Compositor behavior",
            subtext: "Select default bundled anime desktop wallpaper",
            icon: "wallpaper",
            type: "option",
            varKey: "forceDefaultWallpaper"
        }
    ]
}
