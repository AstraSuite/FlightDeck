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

    title: qsTr("Default applications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Applications")
        }

        TextFieldRow {
            first: true
            varKey: "terminal"
            label: qsTr("Default Terminal")
            subtext: qsTr("Terminal emulator executable")
            placeholderText: "foot"
        }

        TextFieldRow {
            varKey: "browser"
            label: qsTr("Web Browser")
            subtext: qsTr("Primary internet browser command")
            placeholderText: "firefox"
        }

        TextFieldRow {
            varKey: "editor"
            label: qsTr("Code / Text Editor")
            subtext: qsTr("Code editor command")
            placeholderText: "codium"
        }

        TextFieldRow {
            varKey: "fileExplorer"
            label: qsTr("File Manager")
            subtext: qsTr("Graphical file manager")
            placeholderText: "thunar"
        }

        TextFieldRow {
            last: true
            varKey: "audioSettings"
            label: qsTr("Audio Mixer GUI")
            subtext: qsTr("Volume control interface executable")
            placeholderText: "pwvucontrol"
        }

        SectionHeader {
            text: qsTr("Audio & Volume Steps")
        }

        SliderRow {
            first: true
            varKey: "volumeStep"
            label: qsTr("Volume Step Size")
            subtext: qsTr("Volume change percentage per step")
            value: CaelestiaVars.pendingVars.volumeStep ?? CaelestiaVars.currentVars.volumeStep ?? CaelestiaVars.getDefault("volumeStep", 10)
            valueLabel: Math.round(value) + "%"
            from: 1
            to: 25
            stepSize: 1
            onMoved: v => CaelestiaVars.set("volumeStep", Math.round(v))
        }

        StepperRow {
            last: true
            varKey: "volumeMax"
            label: qsTr("Maximum Volume Limit")
            subtext: qsTr("Ceiling percentage for volume amplification")
            value: CaelestiaVars.pendingVars.volumeMax ?? CaelestiaVars.currentVars.volumeMax ?? CaelestiaVars.getDefault("volumeMax", 100)
            from: 50
            to: 150
            stepSize: 5
            suffix: "%"
            onMoved: v => CaelestiaVars.set("volumeMax", v)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
