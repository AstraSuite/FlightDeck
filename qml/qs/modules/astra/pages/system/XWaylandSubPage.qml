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

    title: qsTr("XWayland & compatibility")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("XWayland Configuration")
        }

        ToggleRow {
            first: true
            varKey: "xwaylandEnabled"
            text: qsTr("Enable XWayland")
            subtext: qsTr("Allow running legacy X11 applications")
            checked: CaelestiaVars.pendingVars.xwaylandEnabled ?? CaelestiaVars.currentVars.xwaylandEnabled ?? CaelestiaVars.getDefault("xwaylandEnabled", true)
            onToggled: CaelestiaVars.set("xwaylandEnabled", checked)
        }

        ToggleRow {
            varKey: "xwaylandForceZeroScaling"
            text: qsTr("Force Zero Scaling")
            subtext: qsTr("Force apps to use Wayland-native scaling instead of X11 scaling")
            checked: CaelestiaVars.pendingVars.xwaylandForceZeroScaling ?? CaelestiaVars.currentVars.xwaylandForceZeroScaling ?? CaelestiaVars.getDefault("xwaylandForceZeroScaling", false)
            onToggled: CaelestiaVars.set("xwaylandForceZeroScaling", checked)
        }

        ToggleRow {
            last: true
            varKey: "xwaylandUseNearestNeighbor"
            text: qsTr("Use Nearest Neighbor Filter")
            subtext: qsTr("Pixelated scaling filter for upscaling low-res XWayland applications")
            checked: CaelestiaVars.pendingVars.xwaylandUseNearestNeighbor ?? CaelestiaVars.currentVars.xwaylandUseNearestNeighbor ?? CaelestiaVars.getDefault("xwaylandUseNearestNeighbor", false)
            onToggled: CaelestiaVars.set("xwaylandUseNearestNeighbor", checked)
        }

        SectionHeader {
            text: qsTr("Ecosystem & Privacy")
        }

        ToggleRow {
            first: true
            varKey: "noUpdateNews"
            text: qsTr("Disable Update News")
            subtext: qsTr("Suppress update notifications on new Hyprland versions")
            checked: CaelestiaVars.pendingVars.noUpdateNews ?? CaelestiaVars.currentVars.noUpdateNews ?? CaelestiaVars.getDefault("noUpdateNews", false)
            onToggled: CaelestiaVars.set("noUpdateNews", checked)
        }

        ToggleRow {
            varKey: "noDonationNag"
            text: qsTr("Disable Donation Nag")
            subtext: qsTr("Suppress periodic donation reminders")
            checked: CaelestiaVars.pendingVars.noDonationNag ?? CaelestiaVars.currentVars.noDonationNag ?? CaelestiaVars.getDefault("noDonationNag", false)
            onToggled: CaelestiaVars.set("noDonationNag", checked)
        }

        ToggleRow {
            last: true
            varKey: "enforcePermissions"
            text: qsTr("Enforce Permissions")
            subtext: qsTr("Enforce IPC client permission requirements")
            checked: CaelestiaVars.pendingVars.enforcePermissions ?? CaelestiaVars.currentVars.enforcePermissions ?? CaelestiaVars.getDefault("enforcePermissions", false)
            onToggled: CaelestiaVars.set("enforcePermissions", checked)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
