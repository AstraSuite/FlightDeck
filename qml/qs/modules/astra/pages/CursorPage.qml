import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Managers 1.0
import Helm.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Cursor Theme & Size")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Cursor Theme")
        }

        DialogRowButton {
            id: themeRow
            rootParent: root.flickable
            first: true
            last: false
            icon: "mouse"
            label: qsTr("Cursor Theme")
            header: qsTr("Select Cursor Theme")
            acceptLabel: qsTr("Apply")
            separateContent: true
            horizontalContentMargin: -Tokens.padding.small

            property string selectedTheme: CursorManager.currentTheme

            acceptAllowed: selectedTheme !== ""

            onOpenChanged: {
                if (open) {
                    selectedTheme = CursorManager.currentTheme;
                }
            }

            onAccepted: {
                if (selectedTheme !== "") {
                    CursorManager.setCurrentTheme(selectedTheme);
                }
            }

            content: Component {
                VerticalFadeListView {
                    spacing: 0
                    topMargin: Tokens.padding.large
                    bottomMargin: Tokens.padding.large

                    model: CursorManager.availableThemes

                    delegate: StyledRect {
                        id: itemRow
                        required property var modelData
                        required property int index

                        readonly property bool selected: themeRow.selectedTheme === (itemRow.modelData ? itemRow.modelData.name : "")

                        anchors.left: ListView.view.contentItem.left
                        anchors.right: ListView.view.contentItem.right
                        anchors.margins: 1
                        implicitHeight: Math.max(52, col.implicitHeight + Tokens.padding.medium * 2)

                        radius: stateLayer.pressed ? Tokens.rounding.extraSmall : selected ? Tokens.rounding.largeIncreased : Tokens.rounding.medium
                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, selected ? 1 : 0)

                        Behavior on radius {
                            Anim {
                                type: Anim.SlowEffects
                            }
                        }

                        StateLayer {
                            id: stateLayer
                            anchors.fill: parent
                            onClicked: {
                                if (itemRow.modelData) {
                                    themeRow.selectedTheme = itemRow.modelData.name;
                                }
                            }
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.medium

                            Image {
                                id: cursorImg
                                source: (itemRow.modelData && itemRow.modelData.name) ? "image://cursor/" + itemRow.modelData.name : ""
                                sourceSize.width: 32
                                sourceSize.height: 32
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            ColumnLayout {
                                id: col
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: itemRow.modelData ? itemRow.modelData.name : ""
                                    font: Tokens.font.body.small
                                    color: itemRow.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: itemRow.modelData ? (itemRow.modelData.isHyprcursor ? qsTr("Hyprcursor") : qsTr("XCursor")) : ""
                                    font: Tokens.font.label.small
                                    color: itemRow.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3outline
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MaterialIcon {
                                text: "check"
                                color: Colours.palette.m3onTertiaryContainer
                                fontStyle: Tokens.font.icon.medium
                                opacity: itemRow.selected ? 1 : 0

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.SlowEffects
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StepperRow {
            last: true
            varKey: "cursorSize"
            label: qsTr("Cursor Size")
            subtext: qsTr("Pointer size in pixels: %1px").arg(CursorManager.currentSize)
            value: CursorManager.currentSize
            from: 16
            to: 64
            stepSize: 4
            suffix: "px"
            onMoved: v => CursorManager.setCurrentSize(v)
            onReset: CursorManager.setCurrentSize(CaelestiaVars.getDefault("cursorSize", 24))
        }

        SectionHeader {
            text: qsTr("Multi-App Propagation")
        }

        InfoRow {
            first: true
            label: qsTr("Hyprland & Environments")
            value: qsTr("HYPRCURSOR & XCURSOR Env live reload")
            icon: "terminal"
        }

        InfoRow {
            label: qsTr("Desktop Interface")
            value: qsTr("GNOME & Cinnamon GSettings")
            icon: "settings"
        }

        InfoRow {
            label: qsTr("Toolkit Settings")
            value: qsTr("GTK 3/4 settings.ini & ~/.icons/default")
            icon: "palette"
        }

        InfoRow {
            last: true
            label: qsTr("X11 Compatibility")
            value: qsTr("~/.Xresources (xrdb merge)")
            icon: "desktop_windows"
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
