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
            first: true
            icon: "mouse"
            label: qsTr("Cursor Theme")
            header: qsTr("Select Cursor Theme")
            acceptLabel: qsTr("Apply")

            property string selectedTheme: CursorManager.currentTheme

            acceptAllowed: selectedTheme !== ""

            onAccepted: {
                if (selectedTheme !== "") {
                    CursorManager.setCurrentTheme(selectedTheme);
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.small

                    VerticalFadeListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 260
                        clip: true

                        model: CursorManager.availableThemes

                        delegate: Item {
                            id: itemRow
                            required property var modelData
                            required property int index

                            width: ListView.view ? ListView.view.width : 320
                            implicitHeight: 52

                            readonly property bool selected: themeRow.selectedTheme === (itemRow.modelData ? itemRow.modelData.name : "")

                            StateLayer {
                                radius: Tokens.rounding.small

                                onClicked: {
                                    if (itemRow.modelData) {
                                        themeRow.selectedTheme = itemRow.modelData.name;
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
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
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            text: itemRow.modelData ? itemRow.modelData.name : ""
                                            font: Tokens.font.body.small
                                            color: itemRow.selected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        StyledText {
                                            text: itemRow.modelData ? (itemRow.modelData.isHyprcursor ? qsTr("Hyprcursor") : qsTr("XCursor")) : ""
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3outline
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MaterialIcon {
                                        visible: itemRow.selected || (itemRow.modelData && CursorManager.currentTheme === itemRow.modelData.name)
                                        text: "check"
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.small
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
