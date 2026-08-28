import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import "monitors"
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Monitors & Displays")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Visual Display Layout")
        }

        MonitorLayoutPreview {
            Layout.fillWidth: true
        }

        SectionHeader {
            text: qsTr("Connected Displays")
        }

        Repeater {
            model: MonitorManager.liveMonitors

            delegate: ColumnLayout {
                id: monDelegate
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                ToggleRow {
                    first: true
                    text: monDelegate.modelData.name + (monDelegate.modelData.focused ? " " + qsTr("(Primary / Focused)") : "")
                    subtext: qsTr("Resolution: %1x%2 @ %3Hz | Pos: %4x%5 | Scale: %6x").arg(monDelegate.modelData.width).arg(monDelegate.modelData.height).arg(Math.round(monDelegate.modelData.refreshRate * 100) / 100).arg(monDelegate.modelData.x).arg(monDelegate.modelData.y).arg(monDelegate.modelData.scale)
                    checked: !monDelegate.modelData.disabled
                    onToggled: {
                        var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                        var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                        MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, monDelegate.modelData.transform, !checked);
                    }
                }

                SliderRow {
                    label: qsTr("Display Scale")
                    subtext: qsTr("Scaling multiplier for %1").arg(monDelegate.modelData.name)
                    value: monDelegate.modelData.scale
                    valueLabel: Math.round(monDelegate.modelData.scale * 100) + "%"
                    from: 0.5
                    to: 2.0
                    stepSize: 0.05
                    onMoved: v => {
                        var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                        var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                        MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, v, monDelegate.modelData.transform, monDelegate.modelData.disabled);
                    }
                    onInteraction: v => {
                        var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                        var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                        MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, v, monDelegate.modelData.transform, monDelegate.modelData.disabled);
                    }
                }

                SelectRow {
                    last: true
                    label: qsTr("Display Orientation")
                    subtext: qsTr("Rotation angle for %1").arg(monDelegate.modelData.name)
                    menuItems: [
                        MenuItem {
                            text: qsTr("Normal (0°)")
                            icon: "crop_portrait"
                            onClicked: {
                                var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                                var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                                MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, 0, monDelegate.modelData.disabled);
                            }
                        },
                        MenuItem {
                            text: qsTr("90° Portrait")
                            icon: "crop_rotate"
                            onClicked: {
                                var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                                var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                                MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, 1, monDelegate.modelData.disabled);
                            }
                        },
                        MenuItem {
                            text: qsTr("180° Inverted")
                            icon: "screen_rotation"
                            onClicked: {
                                var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                                var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                                MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, 2, monDelegate.modelData.disabled);
                            }
                        },
                        MenuItem {
                            text: qsTr("270° Portrait (Flipped)")
                            icon: "crop_rotate"
                            onClicked: {
                                var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                                var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                                MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, 3, monDelegate.modelData.disabled);
                            }
                        }
                    ]
                    active: {
                        var t = monDelegate.modelData.transform ?? 0;
                        return (t >= 0 && t < menuItems.length) ? menuItems[t] : menuItems[0];
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
