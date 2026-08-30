pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Theme 1.0
import FlightDeck.Managers 1.0
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Theme sync & airlock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Caelestia Theme Synchronization")
        }

        ToggleRow {
            first: true
            text: qsTr("Sync Material Scheme")
            subtext: qsTr("Automatically sync colors with ~/.local/state/caelestia/scheme.json")
            checked: ThemeWatcher.syncScheme
            onCheckedChanged: ThemeWatcher.syncScheme = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Sync Shell Tokens")
            subtext: qsTr("Follow Caelestia shell padding, curves, and font tokens")
            checked: ThemeWatcher.syncTokens
            onCheckedChanged: ThemeWatcher.syncTokens = checked
        }

        SectionHeader {
            text: qsTr("Airlock Greeter Integration")
        }

        InfoRow {
            first: true
            label: qsTr("Airlock Config Status")
            value: AirlockManager.hasAirlockConfig ? qsTr("Found (/etc/greetd/hyprland.lua)") : qsTr("Not installed")
            icon: "lock"
        }

        OptionRow {
            last: true
            title: qsTr("Sync Configuration to Airlock")
            subtext: qsTr("Sync current monitors, cursor theme, and input settings (requires pkexec)")
            currentValue: AirlockManager.isSyncing ? qsTr("Syncing...") : qsTr("Sync (pkexec)")
            onClicked: {
                if (!AirlockManager.isSyncing) {
                    AirlockManager.syncToAirlock();
                }
            }
        }

        StyledText {
            visible: AirlockManager.lastMessage.length > 0
            text: AirlockManager.lastMessage
            color: Colours.palette.m3primary
            font: Tokens.font.body.medium
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
