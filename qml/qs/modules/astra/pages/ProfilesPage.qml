import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Configuration Profiles")

    property string statusText: ""

    data: [
        Connections {
            target: ProfileManager
            function onOperationFinished(success, message): void {
                root.statusText = message;
            }
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Save Current Profile")
        }

        OptionRow {
            first: true
            last: true
            title: qsTr("Create Snapshot Backup")
            subtext: qsTr("Save current hypr-vars.lua & flightdeck.lua to named profile")
            currentValue: qsTr("Create Profile")
            onClicked: {
                var name = "Backup_" + Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss");
                ProfileManager.createProfile(name);
            }
        }

        SectionHeader {
            text: qsTr("Saved Profiles (%1)").arg(ProfileManager.profiles.length)
        }

        Repeater {
            model: ProfileManager.profiles

            delegate: ConnectedRect {
                id: pRow
                required property string modelData
                required property int index

                first: index === 0
                last: index === ProfileManager.profiles.length - 1
                Layout.fillWidth: true
                implicitHeight: rLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: rLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "folder_zip"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: pRow.modelData
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: qsTr("Stored snapshot in ~/.local/share/flightdeck/profiles")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    OptionRow {
                        Layout.preferredWidth: 100
                        title: ""
                        currentValue: qsTr("Restore")
                        onClicked: ProfileManager.restoreProfile(pRow.modelData)
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: ProfileManager.deleteProfile(pRow.modelData)
                    }
                }
            }
        }

        StyledText {
            visible: root.statusText.length > 0
            text: root.statusText
            color: Colours.palette.m3primary
            font: Tokens.font.body.medium
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
