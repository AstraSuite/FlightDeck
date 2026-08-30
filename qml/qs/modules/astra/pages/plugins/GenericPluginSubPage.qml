pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0

PageBase {
    id: root

    property var pluginData: null

    title: pluginData ? (pluginData.label ?? pluginData.name ?? qsTr("Plugin Settings")) : qsTr("Plugin Settings")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: root.pluginData ? (root.pluginData.sections ?? []) : []

            ColumnLayout {
                id: secCol
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: secCol.index === 0
                    text: secCol.modelData.label ?? qsTr("Settings")
                }

                Repeater {
                    id: optRep
                    model: secCol.modelData.options ?? []

                    Loader {
                        id: optLoader
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        readonly property var opt: modelData
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === (optRep.count - 1)
                        readonly property string optKey: opt.key ?? ""
                        readonly property var optDef: opt.default

                        sourceComponent: {
                            if (!opt) return null;
                            if (opt.type === "bool") return boolComp;
                            if (opt.type === "choice") return choiceComp;
                            if (opt.type === "int" || opt.type === "float") {
                                if (opt.min !== undefined && opt.max !== undefined) return sliderComp;
                                return stepperComp;
                            }
                            return stringComp;
                        }

                        Component {
                            id: boolComp
                            ToggleRow {
                                first: optLoader.isFirst
                                last: optLoader.isLast
                                varKey: optLoader.optKey
                                text: optLoader.opt.label ?? optLoader.optKey
                                subtext: optLoader.opt.description ?? ""
                                checked: CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? false)
                                onToggled: CaelestiaVars.set(optLoader.optKey, checked)
                            }
                        }

                        Component {
                            id: sliderComp
                            SliderRow {
                                first: optLoader.isFirst
                                last: optLoader.isLast
                                varKey: optLoader.optKey
                                label: optLoader.opt.label ?? optLoader.optKey
                                subtext: optLoader.opt.description ?? ""
                                from: optLoader.opt.min ?? 0
                                to: optLoader.opt.max ?? 100
                                stepSize: optLoader.opt.step ?? (optLoader.opt.type === "float" ? 0.05 : 1)
                                value: CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? 0)
                                valueLabel: optLoader.opt.type === "float" ? value.toFixed(2) : String(Math.round(value))
                                onMoved: v => CaelestiaVars.set(optLoader.optKey, optLoader.opt.type === "float" ? (Math.round(v * 100) / 100) : Math.round(v))
                            }
                        }

                        Component {
                            id: stepperComp
                            StepperRow {
                                first: optLoader.isFirst
                                last: optLoader.isLast
                                varKey: optLoader.optKey
                                label: optLoader.opt.label ?? optLoader.optKey
                                subtext: optLoader.opt.description ?? ""
                                from: optLoader.opt.min ?? 0
                                to: optLoader.opt.max ?? 9999
                                stepSize: optLoader.opt.step ?? 1
                                value: CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? 0)
                                onMoved: v => CaelestiaVars.set(optLoader.optKey, v)
                            }
                        }

                        Component {
                            id: choiceComp
                            SelectRow {
                                id: selRow
                                first: optLoader.isFirst
                                last: optLoader.isLast
                                label: optLoader.opt.label ?? optLoader.optKey
                                subtext: optLoader.opt.description ?? ""
                                fallbackText: {
                                    const cur = CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? "");
                                    const vals = optLoader.opt.values ?? [];
                                    for (var i = 0; i < vals.length; i++) {
                                        if (vals[i].id === cur) return vals[i].label;
                                    }
                                    return String(cur);
                                }
                                active: {
                                    const cur = CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? "");
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].activeText === cur || menuItems[i].text === cur) return menuItems[i];
                                    }
                                    return menuItems[0] || null;
                                }
                                menuItems: {
                                    const res = [];
                                    const vals = optLoader.opt.values ?? [];
                                    for (var i = 0; i < vals.length; i++) {
                                        const valId = vals[i].id;
                                        const valLabel = vals[i].label ?? vals[i].id;
                                        const targetK = optLoader.optKey;
                                        const item = menuItemComp.createObject(selRow, {
                                            text: valLabel,
                                            activeText: valId
                                        });
                                        item.clicked.connect(() => {
                                            CaelestiaVars.set(targetK, valId);
                                        });
                                        res.push(item);
                                    }
                                    return res;
                                }

                                Component {
                                    id: menuItemComp
                                    MenuItem {}
                                }
                            }
                        }

                        Component {
                            id: stringComp
                            OptionRow {
                                first: optLoader.isFirst
                                last: optLoader.isLast
                                text: optLoader.opt.label ?? optLoader.optKey
                                subtext: optLoader.opt.description ?? ""
                                currentValue: String(CaelestiaVars.pendingVars[optLoader.optKey] ?? CaelestiaVars.currentVars[optLoader.optKey] ?? HyprlandSchema.getDefault(optLoader.optKey, optLoader.optDef ?? ""))
                            }
                        }
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
