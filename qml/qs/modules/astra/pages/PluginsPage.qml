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

StackPage {
    id: root

    property var selectedPluginData: null

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("Plugins & extensions")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("Installed Plugins")
                    }

                    Repeater {
                        model: HyprlandSchema.installedPlugins

                        NavRow {
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === HyprlandSchema.installedPlugins.length - 1
                            label: modelData.label ?? modelData.name
                            subtext: modelData.description ?? ""
                            icon: modelData.icon ?? "extension"
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
                        visible: HyprlandSchema.installedPlugins.length === 0
                        first: true
                        last: true
                        text: qsTr("No Installed Plugins Detected")
                        subtext: qsTr("Plugins installed via hyprpm or active in Hyprland will appear here with dedicated configuration pages.")
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
