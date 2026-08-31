pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

Popup {
    id: root

    property string repoUrl: ""
    property string gitRev: ""

    width: Math.min(520, parent ? parent.width - 40 : 520)
    implicitHeight: contentCol.implicitHeight + Tokens.padding.large * 2
    anchors.centerIn: parent

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: StyledRect {
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
    }

    contentItem: ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Install Custom Plugin")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                onClicked: root.close()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Enter the Git repository URL of the Hyprland plugin to clone, compile, and install via hyprpm.")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Git Repository URL")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledTextField {
                id: repoInput
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. https://github.com/hyprwm/hyprland-plugins")
                text: root.repoUrl
                onTextEdited: root.repoUrl = text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Git Branch / Revision (Optional)")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledTextField {
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. main, v0.1.0, or commit hash")
                text: root.gitRev
                onTextEdited: root.gitRev = text
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Tokens.spacing.small
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Item { Layout.fillWidth: true }

            TextButton {
                type: TextButton.Outlined
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            TextButton {
                type: TextButton.Filled
                text: qsTr("Install Plugin")
                enabled: root.repoUrl.trim().length > 0 && !HyprpmManager.isBusy
                onClicked: {
                    HyprpmManager.installPlugin(root.repoUrl.trim(), root.gitRev.trim());
                    root.close();
                }
            }
        }
    }
}
