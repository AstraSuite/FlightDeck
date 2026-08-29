pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages.system
import FlightDeck.Theme 1.0
import FlightDeck.Managers 1.0
import FlightDeck.Caelestia 1.0

StackPage {
    id: root

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("System & compositor")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("System Configuration")
                    }

                    NavRow {
                        first: true
                        label: qsTr("Default applications")
                        subtext: qsTr("Terminal, web browser, code editor, file manager, and audio mixer")
                        icon: "apps"
                        onClicked: root.nState.openSubPage(1)
                    }

                    NavRow {
                        label: qsTr("XWayland & compatibility")
                        subtext: qsTr("Legacy X11 app support, zero scaling, nearest neighbor filtering, and privacy")
                        icon: "layers"
                        onClicked: root.nState.openSubPage(2)
                    }

                    NavRow {
                        label: qsTr("Theme sync & airlock")
                        subtext: qsTr("Caelestia material scheme sync and Airlock greeter integration")
                        icon: "palette"
                        onClicked: root.nState.openSubPage(3)
                    }

                    NavRow {
                        last: true
                        label: qsTr("Compositor behavior")
                        subtext: qsTr("Focus activation, window animations, VFR, VRR, DPMS, and wallpapers")
                        icon: "settings"
                        onClicked: root.nState.openSubPage(4)
                    }

                    Item {
                        Layout.preferredHeight: Tokens.padding.large
                        Layout.fillWidth: true
                    }
                }
            }
        },

        Component {
            DefaultAppsSubPage {
                nState: root.nState
            }
        },

        Component {
            XWaylandSubPage {
                nState: root.nState
            }
        },

        Component {
            ThemeAirlockSubPage {
                nState: root.nState
            }
        },

        Component {
            CompositorSubPage {
                nState: root.nState
            }
        }
    ]
}
