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

    title: qsTr("Caelestia & system shortcuts")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Workspace Navigation Modifiers")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; isModifier: true; label: qsTr("Go to workspace"); varKey: "kbGoToWs" }
        KeybindRow { rootParent: root.modalOverlay; isModifier: true; label: qsTr("Go to workspace group"); varKey: "kbGoToWsGroup" }
        KeybindRow { rootParent: root.modalOverlay; isModifier: true; label: qsTr("Move window to workspace"); varKey: "kbMoveWinToWs" }
        KeybindRow { rootParent: root.modalOverlay; isModifier: true; label: qsTr("Move window to workspace group"); varKey: "kbMoveWinToWsGroup" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Next workspace"); varKey: "kbNextWs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Previous workspace"); varKey: "kbPrevWs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Next workspace group"); varKey: "kbNextWsGroup" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Previous workspace group"); varKey: "kbPrevWsGroup" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Move window to next workspace"); varKey: "kbMoveWinToWsNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Move window to previous workspace"); varKey: "kbMoveWinToWsPrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Move window to special workspace"); varKey: "kbMoveWinToWsSpecial" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Move window from special workspace"); varKey: "kbMoveWinFromWsSpecial" }

        SectionHeader {
            text: qsTr("Window Group")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Cycle next window"); varKey: "kbWindowCycleNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle previous window"); varKey: "kbWindowCyclePrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle next in group"); varKey: "kbWindowGroupCycleNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle previous in group"); varKey: "kbWindowGroupCyclePrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Lock active group"); varKey: "kbGroupLockActive" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Ungroup"); varKey: "kbUngroup" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Toggle group"); varKey: "kbToggleGroup" }

        SectionHeader {
            text: qsTr("Window Management")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Move window"); varKey: "kbMoveWindow" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Resize window"); varKey: "kbResizeWindow" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Picture-in-picture"); varKey: "kbWindowPip" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Pin window"); varKey: "kbPinWindow" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Center window"); varKey: "kbCenterWindow" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Normalize window size"); varKey: "kbNormalizeWindow" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Fullscreen"); varKey: "kbWindowFullscreen" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Maximized / Bordered Fullscreen"); varKey: "kbWindowBorderedFullscreen" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Toggle floating"); varKey: "kbToggleWindowFloating" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Close active window"); varKey: "kbCloseWindow" }

        SectionHeader {
            text: qsTr("Window Resizing Shortcuts")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Decrease window width"); varKey: "kbWindowDecreaseWidth" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Increase window width"); varKey: "kbWindowIncreaseWidth" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Decrease window height"); varKey: "kbWindowDecreaseHeight" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Increase window height"); varKey: "kbWindowIncreaseHeight" }

        SectionHeader {
            text: qsTr("Applications")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Terminal"); varKey: "kbTerminal" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Web Browser"); varKey: "kbBrowser" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Code / Text Editor"); varKey: "kbEditor" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("File Explorer"); varKey: "kbFileExplorer" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Audio Settings"); varKey: "kbAudioSettings" }

        SectionHeader {
            text: qsTr("Utilities")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Full Screenshot"); varKey: "kbScreenshot" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Screenshot Region"); varKey: "kbScreenshotRegion" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Screenshot Freeze"); varKey: "kbScreenshotFreeze" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Screen Record"); varKey: "kbRecord" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Screen Record Sound"); varKey: "kbRecordSound" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Screen Record Region"); varKey: "kbRecordRegion" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Color Picker"); varKey: "kbColorPicker" }

        SectionHeader {
            text: qsTr("Media & Volume")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Media Play / Pause"); varKey: "kbMediaToggle" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Next Track"); varKey: "kbMediaNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Previous Track"); varKey: "kbMediaPrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Stop Media"); varKey: "kbMediaStop" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Mute Volume"); varKey: "kbVolumeMute" }

        SectionHeader {
            text: qsTr("System & Session")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Application Launcher"); varKey: "kbLauncher" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Session Menu"); varKey: "kbSession" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Toggle Sidebar"); varKey: "kbShowSidebar" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Clear Notifications"); varKey: "kbClearNotifs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Toggle Panels"); varKey: "kbShowPanels" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Lock Screen"); varKey: "kbLock" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Restore Lock Screen"); varKey: "kbRestoreLock" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Sleep / Suspend"); varKey: "kbSleep" }

        SectionHeader {
            text: qsTr("Clipboard & Emoji")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Clipboard History"); varKey: "kbClipboard" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Delete Clipboard Entry"); varKey: "kbClipboardDel" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Paste Latest Entry"); varKey: "kbClipboardPasteLatest" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Emoji Picker"); varKey: "kbEmoji" }

        SectionHeader {
            text: qsTr("Special Workspaces")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Toggle Special Workspace"); varKey: "kbSpecialWs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("System Monitor"); varKey: "kbSystemMonitorWs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Music Workspace"); varKey: "kbMusicWs" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Communication"); varKey: "kbCommunicationWs" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Todo Workspace"); varKey: "kbTodoWs" }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
