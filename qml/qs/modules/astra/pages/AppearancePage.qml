pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages.appearance
import FlightDeck.Caelestia 1.0

StackPage {
    id: root

    pages: [
        Component {
            PageBase {
                id: mainHub
                title: qsTr("Appearance & styling")
                nState: root.nState

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: mainHub ? mainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    SectionHeader {
                        first: true
                        text: qsTr("Visual Customization")
                    }

                    NavRow {
                        first: true
                        label: qsTr("Window styling & layout")
                        subtext: qsTr("Borders, colors, resize behavior, and window opacity")
                        icon: "border_style"
                        onClicked: root.nState.openSubPage(1)
                    }

                    NavRow {
                        label: qsTr("Gaps & rounding")
                        subtext: qsTr("Corner radius curvature, window gaps, and workspace gaps")
                        icon: "rounded_corner"
                        onClicked: root.nState.openSubPage(2)
                    }

                    NavRow {
                        label: qsTr("Dimming & snapping")
                        subtext: qsTr("Inactive window dimming and floating window screen snapping")
                        icon: "brightness_medium"
                        onClicked: root.nState.openSubPage(3)
                    }

                    NavRow {
                        label: qsTr("Blur effects")
                        subtext: qsTr("Dual kawase background blur, noise, and vibrancy filters")
                        icon: "blur_on"
                        onClicked: root.nState.openSubPage(4)
                    }

                    NavRow {
                        label: qsTr("Drop shadows")
                        subtext: qsTr("Dynamic window shadow radius, colors, and offsets")
                        icon: "filter_drama"
                        onClicked: root.nState.openSubPage(5)
                    }

                    NavRow {
                        last: true
                        label: qsTr("Window groups & tabs")
                        subtext: qsTr("Groupbar tab heights, title rendering, gradients, and tab drag behavior")
                        icon: "tab"
                        onClicked: root.nState.openSubPage(6)
                    }

                    Item {
                        Layout.preferredHeight: Tokens.padding.large
                        Layout.fillWidth: true
                    }
                }
            }
        },

        Component {
            WindowStylingSubPage {
                nState: root.nState
            }
        },

        Component {
            GapsRoundingSubPage {
                nState: root.nState
            }
        },

        Component {
            DimmingSnappingSubPage {
                nState: root.nState
            }
        },

        Component {
            BlurSubPage {
                nState: root.nState
            }
        },

        Component {
            ShadowsSubPage {
                nState: root.nState
            }
        },

        Component {
            WindowGroupsSubPage {
                nState: root.nState
            }
        }
    ]
}
