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

    title: qsTr("Caelestia navigation & modifier variables")
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
            text: qsTr("Window Resizing Shortcuts")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Decrease window width"); varKey: "kbWindowDecreaseWidth" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Increase window width"); varKey: "kbWindowIncreaseWidth" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Decrease window height"); varKey: "kbWindowDecreaseHeight" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Increase window height"); varKey: "kbWindowIncreaseHeight" }

        SectionHeader {
            text: qsTr("Window Group & Tiling Modifiers")
        }

        KeybindRow { rootParent: root.modalOverlay; first: true; label: qsTr("Cycle next window"); varKey: "kbWindowCycleNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle previous window"); varKey: "kbWindowCyclePrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle next in group"); varKey: "kbWindowGroupCycleNext" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Cycle previous in group"); varKey: "kbWindowGroupCyclePrev" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Lock active group"); varKey: "kbGroupLockActive" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Ungroup"); varKey: "kbUngroup" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Toggle group"); varKey: "kbToggleGroup" }
        KeybindRow { rootParent: root.modalOverlay; label: qsTr("Move window modifier"); varKey: "kbMoveWindow" }
        KeybindRow { rootParent: root.modalOverlay; last: true; label: qsTr("Resize window modifier"); varKey: "kbResizeWindow" }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
