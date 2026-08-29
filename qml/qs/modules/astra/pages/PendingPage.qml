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

    title: qsTr("Pending changes")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Actions")
        }

        ButtonRow {
            first: true
            icon: "save"
            title: qsTr("Apply & Save to Disk")
            subtext: qsTr("Write all pending changes to hypr-vars.lua and flightdeck.lua")
            actionLabel: (CaelestiaVars.isDirty || FlightDeckWriter.isDirty) ? qsTr("Save Now") : qsTr("Up to Date")
            onClicked: {
                CaelestiaVars.save();
                FlightDeckWriter.save();
                HyprlandState.reloadCompositor();
            }
        }

        ButtonRow {
            icon: "play_arrow"
            title: qsTr("Test Live (IPC)")
            subtext: qsTr("Send pending settings directly to Hyprland runtime without saving to disk")
            actionLabel: qsTr("Apply Live")
            onClicked: {
                for (var key in CaelestiaVars.pendingVars) {
                    HyprlandState.keyword(key, CaelestiaVars.pendingVars[key]);
                }
            }
        }

        ButtonRow {
            last: true
            icon: "delete_sweep"
            title: qsTr("Discard Changes")
            subtext: qsTr("Revert all pending unsaved modifications")
            actionLabel: (CaelestiaVars.isDirty || FlightDeckWriter.isDirty) ? qsTr("Revert") : qsTr("Clean")
            onClicked: {
                CaelestiaVars.discardAll();
                FlightDeckWriter.discard();
            }
        }

        SectionHeader {
            text: qsTr("Pending Modifications (%1)").arg(CaelestiaVars.dirtyCount + FlightDeckWriter.dirtyCount)
        }

        Repeater {
            model: CaelestiaVars.pendingKeys

            delegate: OptionRow {
                required property string modelData
                required property int index

                first: index === 0
                last: index === CaelestiaVars.pendingKeys.length - 1
                title: modelData
                subtext: qsTr("Saved: %1 -> Pending: %2").arg(CaelestiaVars.currentVars[modelData] ?? qsTr("Default")).arg(CaelestiaVars.pendingVars[modelData])
                currentValue: qsTr("Revert Key")
                onClicked: CaelestiaVars.resetKey(modelData)
            }
        }

        Item {
            visible: CaelestiaVars.dirtyCount === 0 && FlightDeckWriter.dirtyCount === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No pending modifications")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
