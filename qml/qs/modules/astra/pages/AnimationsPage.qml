import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import "animations"
import Helm.Managers 1.0

PageBase {
    id: root

    title: qsTr("Animations & Motion")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Bezier Curve Graphical Editor")
        }

        BezierEditorCard {
            id: curveEditor
            Layout.fillWidth: true
        }

        SectionHeader {
            text: qsTr("Caelestia Animation Preset")
        }

        OptionRow {
            first: true
            last: true
            title: qsTr("Active Preset")
            subtext: qsTr("Caelestia motion timing and curve preset (.lua)")
            options: (AnimationManager.availablePresets || []).map(p => ({ label: p + ".lua", value: p }))
            currentValue: AnimationManager.activePreset ? (AnimationManager.activePreset + ".lua") : qsTr("None")
            onOptionSelected: (val, lbl) => {
                AnimationManager.activePreset = val;
            }
        }

        SectionHeader {
            text: qsTr("Saved Bezier Curves")
        }

        Repeater {
            model: AnimationManager.bezierCurves

            delegate: OptionRow {
                id: curveRow
                required property var modelData
                required property int index

                first: index === 0
                last: index === AnimationManager.bezierCurves.length - 1
                title: modelData ? modelData.name : ""
                subtext: modelData ? ("Cubic bezier: (" + modelData.x1 + ", " + modelData.y1 + ", " + modelData.x2 + ", " + modelData.y2 + ")") : ""
                currentValue: qsTr("Load into Editor")
                onClicked: {
                    if (modelData) {
                        curveEditor.curveName = modelData.name;
                        curveEditor.x1 = modelData.x1;
                        curveEditor.y1 = modelData.y1;
                        curveEditor.x2 = modelData.x2;
                        curveEditor.y2 = modelData.y2;
                        AnimationManager.testCurve(modelData.name, modelData.x1, modelData.y1, modelData.x2, modelData.y2);
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Animation Targets")
        }

        Repeater {
            model: AnimationManager.animationTargets

            delegate: ToggleRow {
                id: targetRow
                required property var modelData
                required property int index

                first: index === 0
                last: index === AnimationManager.animationTargets.length - 1
                text: modelData ? modelData.target : ""
                subtext: modelData ? ("Duration: " + modelData.duration + "s | Curve: " + modelData.curve + (modelData.style ? (" | " + modelData.style) : "")) : ""
                checked: modelData ? modelData.enabled : true
                onToggled: {
                    if (modelData) {
                        AnimationManager.setTargetEnabled(modelData.target, checked);
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
