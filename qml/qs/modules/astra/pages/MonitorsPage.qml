import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import "monitors"
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Displays & monitors")

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Visual Display Layout")
        }

        MonitorLayoutPreview {
            id: preview
            Layout.fillWidth: true
        }

        SectionHeader {
            text: qsTr("Display Configuration")
        }

        MonitorCard {
            id: monCard
            cardIndex: (preview.selectedIndex >= 0 && preview.selectedIndex < MonitorManager.liveMonitors.length) ? preview.selectedIndex : 0
            cardModelData: (preview.selectedIndex >= 0 && preview.selectedIndex < MonitorManager.liveMonitors.length)
                           ? MonitorManager.liveMonitors[preview.selectedIndex]
                           : (MonitorManager.liveMonitors.length > 0 ? MonitorManager.liveMonitors[0] : ({}))
            isExpanded: false
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
