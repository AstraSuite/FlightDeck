import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import "monitors"
import Helm.Managers 1.0

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

                OptionRow {
                    last: true
                    title: qsTr("Display Orientation")
                    subtext: qsTr("Rotation angle for %1").arg(monDelegate.modelData.name)
                    options: [
                        { label: qsTr("Normal (0°)"), value: 0 },
                        { label: qsTr("90° Portrait"), value: 1 },
                        { label: qsTr("180° Inverted"), value: 2 },
                        { label: qsTr("270° Portrait (Flipped)"), value: 3 }
                    ]
                    currentIndex: monDelegate.modelData.transform ?? 0
                    currentValue: {
                        var t = monDelegate.modelData.transform ?? 0;
                        if (t === 1) return qsTr("90° Portrait");
                        if (t === 2) return qsTr("180° Inverted");
                        if (t === 3) return qsTr("270° Portrait (Flipped)");
                        return qsTr("Normal (0°)");
                    }
                    onOptionSelected: (val, lbl) => {
                        var modeStr = monDelegate.modelData.width + "x" + monDelegate.modelData.height + "@" + monDelegate.modelData.refreshRate;
                        var posStr = monDelegate.modelData.x + "x" + monDelegate.modelData.y;
                        MonitorManager.applyMonitor(monDelegate.modelData.name, modeStr, posStr, monDelegate.modelData.scale, val, monDelegate.modelData.disabled);
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
