pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages.plugins
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0
import FlightDeck.Managers 1.0

StackPage {
    id: root

    property var selectedPluginData: null

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("Plugin Configuration")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("Active Plugins (%1)").arg(enabledRepeater.count)
                    }

                    Repeater {
                        id: enabledRepeater
                        model: {
                            return HyprpmManager.installedPlugins.filter(p => p.isEnabled === true);
                        }

                        NavRow {
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === enabledRepeater.count - 1
                            label: modelData.label ?? modelData.name
                            subtext: modelData.description ?? ""
                            icon: modelData.icon ?? "tune"
                            onClicked: {
                                if (modelData.id === "hypr-dynamic-cursors" || modelData.name === "dynamic-cursors") {
                                    root.nState.openSubPage(1);
                                } else {
                                    root.selectedPluginData = modelData;
                                    root.nState.openSubPage(2);
                                }
                            }
                        }
                    }

                    OptionRow {
                        visible: enabledRepeater.count === 0
                        first: true
                        last: true
                        text: qsTr("No Enabled Plugins Detected")
                        subtext: HyprpmManager.installedCount > 0
                                 ? qsTr("You have %1 installed plugin(s) that are currently disabled. Run 'flightdeck plugin enable <name>' in your terminal to enable them.").arg(HyprpmManager.installedCount)
                                 : qsTr("Install and enable plugins using 'flightdeck plugin' in your terminal to configure them here.")
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: cliInfoCol.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.medium
                        color: Colours.palette.m3surfaceContainerLow
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant

                        ColumnLayout {
                            id: cliInfoCol
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.extraSmall

                            RowLayout {
                                spacing: Tokens.spacing.small
                                MaterialIcon {
                                    text: "terminal"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }
                                StyledText {
                                    text: qsTr("Plugin Management CLI")
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3onSurface
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("Manage plugins directly in your terminal using FlightDeck CLI:\n  • flightdeck plugin                (List catalog and status)\n  • flightdeck plugin install <repo> (Install from Git repo)\n  • flightdeck plugin enable <name>  (Enable plugin)\n  • flightdeck plugin update         (Compile and update)\n  • flightdeck plugin repair         (Fix cache permissions)")
                                font.family: "Monospace"
                                font.pixelSize: 11
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: Tokens.padding.large
                        Layout.fillWidth: true
                    }
                }
            }
        },

        Component {
            DynamicCursorsSubPage {
                nState: root.nState
            }
        },

        Component {
            GenericPluginSubPage {
                pluginData: root.selectedPluginData
                nState: root.nState
            }
        }
    ]
}
