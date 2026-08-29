pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages.input
import FlightDeck.Caelestia 1.0

StackPage {
    id: root

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("Input devices & gestures")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("Input Hardware & Methods")
                    }

                    NavRow {
                        first: true
                        label: qsTr("Keyboard")
                        subtext: qsTr("Keyboard layout, variants, XKB options, and key repeat rates")
                        icon: "keyboard"
                        onClicked: root.nState.openSubPage(1)
                    }

                    NavRow {
                        label: qsTr("Mouse & pointer")
                        subtext: qsTr("Sensitivity, acceleration profiles, natural scrolling, and focus behavior")
                        icon: "mouse"
                        onClicked: root.nState.openSubPage(2)
                    }

                    NavRow {
                        last: true
                        label: qsTr("Touchpad & gestures")
                        subtext: qsTr("Typing palm rejection, tapping, scrolling, and workspace swipe gestures")
                        icon: "touchpad_mouse"
                        onClicked: root.nState.openSubPage(3)
                    }

                    Item {
                        Layout.preferredHeight: Tokens.padding.large
                        Layout.fillWidth: true
                    }
                }
            }
        },

        Component {
            KeyboardSubPage {
                nState: root.nState
            }
        },

        Component {
            MouseSubPage {
                nState: root.nState
            }
        },

        Component {
            TouchpadSubPage {
                nState: root.nState
            }
        }
    ]
}
