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
                        text: qsTr("Plugin Manager & Store")
                    }

                    NavRow {
                        first: true
                        last: true
                        icon: "storefront"
                        label: qsTr("Open Plugin Manager & Store")
                        subtext: qsTr("Enable, disable, install, remove, and update plugins (%1 installed, %2 available)").arg(HyprpmManager.installedCount).arg(HyprpmManager.availableCount)
                        onClicked: root.nState.openSubPage(3)
                    }

                    SectionHeader {
                        text: qsTr("Active Plugins Configuration")
                    }

                    Repeater {
                        model: {
                            return HyprpmManager.installedPlugins.filter(p => p.isEnabled === true);
                        }

                        NavRow {
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === parent.count - 1
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
                        visible: {
                            const enabledList = HyprpmManager.installedPlugins.filter(p => p.isEnabled === true);
                            return enabledList.length === 0;
                        }
                        first: true
                        last: true
                        text: qsTr("No Enabled Plugins")
                        subtext: HyprpmManager.installedCount > 0
                                 ? qsTr("You have %1 installed plugin(s) currently disabled. Open the Plugin Manager to enable them.").arg(HyprpmManager.installedCount)
                                 : qsTr("Install and enable plugins from the Plugin Store to configure them here.")
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
        },

        Component {
            PluginStoreSubPage {
                nState: root.nState
            }
        }
    ]
}
