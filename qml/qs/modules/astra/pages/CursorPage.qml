import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Cursor & Pointer")

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
            rootParent: root.modalOverlay
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
            last: false
            varKey: "cursorSize"
            label: qsTr("Cursor Size")
            subtext: qsTr("Pointer size in pixels: %1px").arg(CursorManager.currentSize)
            value: CursorManager.currentSize
            from: 1
            to: 2147483647
            stepSize: 1
            suffix: "px"
            onMoved: v => CursorManager.setCurrentSize(v)
            onReset: CursorManager.setCurrentSize(CaelestiaVars.getDefault("cursorSize", 24))
        }

        ToggleRow {
            varKey: "cursorNoHardwareCursors"
            text: qsTr("Hardware Cursors")
            subtext: qsTr("Render cursor in hardware planes for reduced latency")
            checked: !(CaelestiaVars.pendingVars.cursorNoHardwareCursors ?? CaelestiaVars.currentVars.cursorNoHardwareCursors ?? CaelestiaVars.getDefault("cursorNoHardwareCursors", false))
            onToggled: CaelestiaVars.set("cursorNoHardwareCursors", !checked)
        }

        ToggleRow {
            last: true
            varKey: "cursorEnableHyprcursor"
            text: qsTr("Enable Hyprcursor")
            subtext: qsTr("Hardware/software vector animated cursor support")
            checked: CaelestiaVars.pendingVars.cursorEnableHyprcursor ?? CaelestiaVars.currentVars.cursorEnableHyprcursor ?? CaelestiaVars.getDefault("cursorEnableHyprcursor", true)
            onToggled: CaelestiaVars.set("cursorEnableHyprcursor", checked)
        }

        SectionHeader {
            text: qsTr("Cursor Movement & Warping")
        }

        ToggleRow {
            first: true
            varKey: "cursorNoWarps"
            text: qsTr("Disable Cursor Warps")
            subtext: qsTr("Do not warp cursor when focusing windows or using keybinds")
            checked: CaelestiaVars.pendingVars.cursorNoWarps ?? CaelestiaVars.currentVars.cursorNoWarps ?? CaelestiaVars.getDefault("cursorNoWarps", false)
            onToggled: CaelestiaVars.set("cursorNoWarps", checked)
        }

        ToggleRow {
            varKey: "cursorPersistentWarps"
            text: qsTr("Persistent Warps")
            subtext: qsTr("Remember cursor position per window when warping back")
            checked: CaelestiaVars.pendingVars.cursorPersistentWarps ?? CaelestiaVars.currentVars.cursorPersistentWarps ?? CaelestiaVars.getDefault("cursorPersistentWarps", false)
            onToggled: CaelestiaVars.set("cursorPersistentWarps", checked)
        }

        ToggleRow {
            varKey: "cursorWarpOnChangeWorkspace"
            text: qsTr("Warp on Workspace Change")
            subtext: qsTr("Move cursor to the last focused window after switching workspaces")
            checked: CaelestiaVars.pendingVars.cursorWarpOnChangeWorkspace ?? CaelestiaVars.currentVars.cursorWarpOnChangeWorkspace ?? CaelestiaVars.getDefault("cursorWarpOnChangeWorkspace", false)
            onToggled: CaelestiaVars.set("cursorWarpOnChangeWorkspace", checked)
        }

        SliderRow {
            last: true
            varKey: "cursorZoomFactor"
            label: qsTr("Zoom Factor")
            subtext: qsTr("Magnification scale factor for cursor zoom")
            value: CaelestiaVars.pendingVars.cursorZoomFactor ?? CaelestiaVars.currentVars.cursorZoomFactor ?? CaelestiaVars.getDefault("cursorZoomFactor", 1.0)
            valueLabel: value.toFixed(1) + "x"
            from: 1.0
            to: 5.0
            stepSize: 0.1
            onMoved: v => CaelestiaVars.set("cursorZoomFactor", Math.round(v * 10) / 10)
        }

        SectionHeader {
            text: qsTr("Cursor Visibility")
        }

        StepperRow {
            first: true
            varKey: "cursorInactiveTimeout"
            label: qsTr("Inactive Timeout")
            subtext: qsTr("Seconds before hiding cursor automatically (0 = never hide)")
            value: CaelestiaVars.pendingVars.cursorInactiveTimeout ?? CaelestiaVars.currentVars.cursorInactiveTimeout ?? CaelestiaVars.getDefault("cursorInactiveTimeout", 0)
            from: 0
            to: 60
            stepSize: 1
            suffix: "s"
            onMoved: v => CaelestiaVars.set("cursorInactiveTimeout", v)
        }

        ToggleRow {
            varKey: "cursorHideOnKeyPress"
            text: qsTr("Hide on Key Press")
            subtext: qsTr("Hide cursor when typing on keyboard")
            checked: CaelestiaVars.pendingVars.cursorHideOnKeyPress ?? CaelestiaVars.currentVars.cursorHideOnKeyPress ?? CaelestiaVars.getDefault("cursorHideOnKeyPress", false)
            onToggled: CaelestiaVars.set("cursorHideOnKeyPress", checked)
        }

        ToggleRow {
            varKey: "cursorHideOnTouch"
            text: qsTr("Hide on Touch")
            subtext: qsTr("Hide cursor when using touch input")
            checked: CaelestiaVars.pendingVars.cursorHideOnTouch ?? CaelestiaVars.currentVars.cursorHideOnTouch ?? CaelestiaVars.getDefault("cursorHideOnTouch", false)
            onToggled: CaelestiaVars.set("cursorHideOnTouch", checked)
        }

        ToggleRow {
            last: true
            varKey: "cursorHideOnTablet"
            text: qsTr("Hide on Tablet")
            subtext: qsTr("Hide cursor when drawing with graphics tablet stylus")
            checked: CaelestiaVars.pendingVars.cursorHideOnTablet ?? CaelestiaVars.currentVars.cursorHideOnTablet ?? CaelestiaVars.getDefault("cursorHideOnTablet", false)
            onToggled: CaelestiaVars.set("cursorHideOnTablet", checked)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
