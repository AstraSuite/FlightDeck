pragma ComponentBehavior: Bound

import "navpane"
import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra

ColumnLayout {
    id: root

    required property AstraState nState

    spacing: Tokens.spacing.medium

    SearchBar {
        id: searchField

        z: 10
        Layout.fillWidth: true

        placeholderText: qsTr("Search settings")
        font: Tokens.font.body.large

        bg.color: Colours.tPalette.m3surfaceContainerLowest
        bg.border.color: Colours.palette.m3outlineVariant
        searchIcon.fontStyle: Tokens.font.icon.medium
        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
        clearIcon.font: Tokens.font.icon.medium
        clearIcon.padding: Tokens.padding.extraSmall

        Behavior on bg.border.color {
            CAnim {}
        }

        Binding {
            target: root.nState
            property: "searchOpen"
            value: searchField.text.length > 0
        }

        Connections {
            target: root.nState
            function onFocusSearchRequested() {
                searchField.forceActiveFocus();
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        NavLocations {
            id: locations
            anchors.fill: parent
            z: root.nState.searchOpen ? 1 : 2
            nState: root.nState

            opacity: root.nState.searchOpen ? 0.0 : 1.0
            visible: opacity > 0.001

            transform: Translate {
                y: root.nState.searchOpen ? -16 : 0
                Behavior on y {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }

        NavSearchResults {
            id: searchResults
            anchors.fill: parent
            z: root.nState.searchOpen ? 2 : 1
            query: searchField.text
            nState: root.nState

            opacity: root.nState.searchOpen ? 1.0 : 0.0
            visible: opacity > 0.001

            transform: Translate {
                y: root.nState.searchOpen ? 0 : 16
                Behavior on y {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            onResultSelected: {
                searchField.text = "";
                root.nState.searchOpen = false;
            }
        }
    }
}
