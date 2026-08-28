import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Hyprland 1.0

PageBase {
    id: root

    title: qsTr("About")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: heroCol.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: heroCol
                anchors.centerIn: parent
                width: parent.width - Tokens.padding.large * 2
                spacing: Tokens.padding.small

                AnimatedLogo {
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "FlightDeck"
                    font: Tokens.font.headline.large
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("v%1").arg(typeof appVersion !== "undefined" ? appVersion : "1.0.0")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Hyprland Configuration Suite with Caelestia dotfiles integration.")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }

        SectionHeader {
            text: qsTr("Compositor & Environment")
        }

        InfoRow {
            first: true
            label: qsTr("Hyprland Status")
            value: HyprlandState.online ? qsTr("Online (IPC Connected)") : qsTr("Offline")
            icon: "terminal"
        }

        InfoRow {
            label: qsTr("Hyprland Version")
            value: HyprlandState.version
            icon: "info"
        }

        InfoRow {
            last: true
            label: qsTr("Configuration Target")
            value: "hypr-vars.lua & astra-helm.lua"
            icon: "folder"
        }

        SectionHeader {
            text: qsTr("Credits & License")
        }

        InfoRow {
            first: true
            label: qsTr("License")
            value: "GNU GPL v3.0"
            icon: "gavel"
        }

        InfoRow {
            last: true
            label: qsTr("Design & Components")
            value: "Astra Suite & Caelestia Shell"
            icon: "favorite"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
