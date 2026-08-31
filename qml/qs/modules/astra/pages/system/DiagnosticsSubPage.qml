pragma ComponentBehavior: Bound

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

    title: qsTr("System Diagnostics")
    isSubPage: true

    headerContent: Component {
        IconTextButton {
            text: qsTr("Re-run Checks")
            icon: "refresh"
            type: TextButton.Filled
            onClicked: DiagnosticsManager.runAllChecks()
        }
    }
    headerContentWidth: 160

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.medium

        // Summary Card
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: summaryLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainer

            RowLayout {
                id: summaryLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall / 2

                    StyledText {
                        text: qsTr("Compositor & Environment Health")
                        font: Tokens.font.title.medium
                        color: Colours.palette.m3onSurface
                    }

                    StyledText {
                        text: qsTr("Automated diagnostics for GPU drivers, IPC sockets, Lua syntax, daemons, and shortcuts.")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.small

                    // Passed Badge
                    StyledRect {
                        implicitWidth: passRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 36
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primaryContainer

                        RowLayout {
                            id: passRow
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                text: "check_circle"
                                color: Colours.palette.m3onPrimaryContainer
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: qsTr("%1 Passed").arg(DiagnosticsManager.passCount)
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onPrimaryContainer
                            }
                        }
                    }

                    // Warnings Badge
                    StyledRect {
                        visible: DiagnosticsManager.warningCount > 0
                        implicitWidth: warnRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 36
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3tertiaryContainer

                        RowLayout {
                            id: warnRow
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                text: "warning"
                                color: Colours.palette.m3onTertiaryContainer
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: qsTr("%1 Warnings").arg(DiagnosticsManager.warningCount)
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onTertiaryContainer
                            }
                        }
                    }

                    // Errors Badge
                    StyledRect {
                        visible: DiagnosticsManager.errorCount > 0
                        implicitWidth: errRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 36
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3errorContainer

                        RowLayout {
                            id: errRow
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                text: "error"
                                color: Colours.palette.m3onErrorContainer
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: qsTr("%1 Errors").arg(DiagnosticsManager.errorCount)
                                font: Tokens.font.label.medium
                                color: Colours.palette.m3onErrorContainer
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Diagnostic Checks")
        }

        // Diagnostic Items List
        Repeater {
            model: DiagnosticsManager.results

            StyledRect {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerLow
                border.width: 1
                border.color: modelData.status === "error" ? Colours.palette.m3error :
                              modelData.status === "warning" ? Colours.palette.m3outlineVariant :
                              Colours.palette.m3outlineVariant

                ColumnLayout {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: modelData.status === "pass" ? "check_circle" : (modelData.status === "warning" ? "warning" : "error")
                            color: modelData.status === "pass" ? Colours.palette.m3primary : (modelData.status === "warning" ? Colours.palette.m3tertiary : Colours.palette.m3error)
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: modelData.title ?? ""
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3onSurface
                                }

                                StyledRect {
                                    implicitWidth: catTxt.implicitWidth + 12
                                    implicitHeight: 20
                                    radius: Tokens.rounding.extraSmall
                                    color: Colours.palette.m3surfaceContainerHigh

                                    StyledText {
                                        id: catTxt
                                        anchors.centerIn: parent
                                        text: modelData.category ?? ""
                                        font: Tokens.font.label.small
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }

                            StyledText {
                                text: modelData.message ?? ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Detail text if present
                    StyledText {
                        visible: modelData.detail && modelData.detail !== ""
                        text: modelData.detail ?? ""
                        font: Tokens.font.body.small
                        color: Colours.palette.m3outline
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                        Layout.leftMargin: 36
                    }

                    // Suggested Fix banner
                    StyledRect {
                        visible: modelData.suggestedFix && modelData.suggestedFix !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: 36
                        implicitHeight: fixRow.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.small
                        color: modelData.status === "error" ? Colours.palette.m3errorContainer : Colours.palette.m3tertiaryContainer

                        RowLayout {
                            id: fixRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "lightbulb"
                                color: modelData.status === "error" ? Colours.palette.m3onErrorContainer : Colours.palette.m3onTertiaryContainer
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Fix: %1").arg(modelData.suggestedFix)
                                font: Tokens.font.body.small
                                color: modelData.status === "error" ? Colours.palette.m3onErrorContainer : Colours.palette.m3onTertiaryContainer
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
