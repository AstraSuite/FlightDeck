pragma Singleton

import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.services
import qs.modules.astra.common
import qs.modules.astra.pages

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // 0: Appearance
        Component {
            StackPage {
                Component {
                    AppearancePage {}
                }
            }
        },

        // 1: Animations
        Component {
            StackPage {
                Component {
                    AnimationsPage {}
                }
            }
        },

        // 2: Cursor
        Component {
            StackPage {
                Component {
                    CursorPage {}
                }
            }
        },

        // 3: Keybinds
        Component {
            StackPage {
                Component {
                    BindsPage {}
                }
            }
        },

        // 4: Touchpad & Gestures
        Component {
            StackPage {
                Component {
                    InputPage {}
                }
            }
        },

        // 5: Monitors
        Component {
            StackPage {
                Component {
                    MonitorsPage {}
                }
            }
        },

        // 6: Window Rules
        Component {
            StackPage {
                Component {
                    WindowRulesPage {}
                }
            }
        },

        // 7: Layer Rules
        Component {
            StackPage {
                Component {
                    LayerRulesPage {}
                }
            }
        },

        // 8: Autostart
        Component {
            StackPage {
                Component {
                    AutostartPage {}
                }
            }
        },

        // 9: Profiles & Backup
        Component {
            StackPage {
                Component {
                    ProfilesPage {}
                }
            }
        },

        // 10: Pending Changes
        Component {
            StackPage {
                Component {
                    PendingPage {}
                }
            }
        },

        // 11: Settings
        Component {
            StackPage {
                Component {
                    HelmSettingsPage {}
                }
            }
        },

        // 12: About
        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
            }
        }
    ]

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    component PlaceholderComp: Item {
        property AstraState nState

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Page under construction")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }
        }
    }
}
