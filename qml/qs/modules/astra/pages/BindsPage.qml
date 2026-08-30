pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages.binds
import FlightDeck.Caelestia 1.0

StackPage {
    id: root

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("Keyboard shortcuts")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("Keybinding Categories")
                    }

                    NavRow {
                        first: true
                        label: qsTr("System & Custom Keybinds")
                        subtext: qsTr("Custom shortcuts, application launchers, media controls, and system actions")
                        icon: "keyboard_command_key"
                        onClicked: root.nState.openSubPage(1)
                    }

                    NavRow {
                        last: true
                        label: qsTr("Caelestia Modifiers & Navigation")
                        subtext: qsTr("Workspace navigation modifiers, window resizing, and group tiling variables")
                        icon: "tune"
                        onClicked: root.nState.openSubPage(2)
                    }

                    Item {
                        Layout.preferredHeight: Tokens.padding.large
                        Layout.fillWidth: true
                    }
                }
            }
        },
        Component {
            CustomBindsSubPage {
                nState: root.nState
            }
        },
        Component {
            CaelestiaBindsSubPage {
                nState: root.nState
            }
        }
    ]
}
