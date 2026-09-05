import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import "animations"
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Animations & Motion")

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Master Switch")
        }

        ToggleRow {
            first: true
            last: true
            varKey: "animations:enabled"
            text: qsTr("Enable Animations")
            subtext: qsTr("Global master toggle for all window, workspace, and layer animations")
            checked: CaelestiaVars.get("animations:enabled", true)
            onToggled: {
                CaelestiaVars.set("animations:enabled", checked);
                FlightDeckWriter.save();
            }
        }

        SectionHeader {
            text: qsTr("Bezier Curve Graphical Editor")
        }

        BezierEditorCard {
            id: curveEditor
            Layout.fillWidth: true
        }

        SectionHeader {
            text: qsTr("Saved Bezier Curves (%1)").arg(AnimationManager.bezierCurves.length)
        }

        Repeater {
            model: AnimationManager.bezierCurves

            delegate: ConnectedRect {
                id: curveRow
                required property var modelData
                required property int index

                first: index === 0
                last: index === AnimationManager.bezierCurves.length - 1
                Layout.fillWidth: true
                implicitHeight: 64

                Row {
                    id: actionsRow
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: curveRow.modelData ? !curveRow.modelData.isReadOnly : false
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: {
                            if (curveRow.modelData) {
                                AnimationManager.removeBezierCurve(curveRow.modelData.name);
                            }
                        }
                    }

                    TextButton {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitHeight: 34
                        text: qsTr("Load into Editor")
                        onClicked: {
                            if (curveRow.modelData) {
                                curveEditor.curveName = curveRow.modelData.name;
                                curveEditor.x1 = curveRow.modelData.x1;
                                curveEditor.y1 = curveRow.modelData.y1;
                                curveEditor.x2 = curveRow.modelData.x2;
                                curveEditor.y2 = curveRow.modelData.y2;
                                root.flickable.contentY = -root.flickable.topMargin;
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: actionsRow.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: curveRow.modelData ? curveRow.modelData.name : ""
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: curveRow.modelData ? ("Cubic bezier: (" + curveRow.modelData.x1 + ", " + curveRow.modelData.y1 + ", " + curveRow.modelData.x2 + ", " + curveRow.modelData.y2 + ")") : ""
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Animation Targets (%1)").arg(AnimationManager.animationTargets.length)
        }

        Repeater {
            model: AnimationManager.animationTargets

            delegate: DialogRowButton {
                id: targetRow
                required property var modelData
                required property int index

                rootParent: root.modalOverlay
                first: index === 0
                last: index === AnimationManager.animationTargets.length - 1
                icon: "motion_photos_on"

                property string targetName: targetRow.modelData ? (targetRow.modelData.target || targetRow.modelData.name || "") : ""
                property bool targetEnabled: targetRow.modelData ? (targetRow.modelData.enabled ?? true) : true
                property real targetSpeed: targetRow.modelData ? (targetRow.modelData.speed ?? targetRow.modelData.duration ?? 5.0) : 5.0
                property string targetCurve: targetRow.modelData ? (targetRow.modelData.curve || targetRow.modelData.bezier || "default") : "default"
                property string targetStyle: targetRow.modelData ? (targetRow.modelData.style || "") : ""

                label: targetName
                subtext: qsTr("Speed: %1 | Curve: %2%3").arg(targetSpeed).arg(targetCurve).arg(targetStyle ? (" | " + targetStyle) : "")

                header: qsTr("Configure %1 Animation").arg(targetName)
                acceptLabel: qsTr("Save Target")

                openWidth: Math.min((rootParent ? rootParent.width : 540) * 0.9, 520)
                openHeight: Math.min((rootParent ? rootParent.height : 500) * 0.9, 480)

                onOpenChanged: {
                    if (open && targetRow.modelData) {
                        targetEnabled = targetRow.modelData.enabled ?? true;
                        targetSpeed = targetRow.modelData.speed ?? targetRow.modelData.duration ?? 5.0;
                        targetCurve = targetRow.modelData.curve || targetRow.modelData.bezier || "default";
                        targetStyle = targetRow.modelData.style || "";
                    }
                }

                onAccepted: {
                    AnimationManager.updateTarget(targetName, targetEnabled, targetSpeed, targetCurve, targetStyle);
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: Tokens.spacing.small

                        StyledSwitch {
                            checked: targetRow.targetEnabled
                            onToggled: {
                                targetRow.targetEnabled = checked;
                                AnimationManager.setTargetEnabled(targetRow.targetName, checked);
                            }
                        }
                    }
                }

                content: Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.medium
                        Layout.fillWidth: true

                        StyledSwitch {
                            Layout.fillWidth: true
                            text: qsTr("Enable %1 Animation").arg(targetRow.targetName)
                            checked: targetRow.targetEnabled
                            onToggled: targetRow.targetEnabled = checked
                        }

                        StepperRow {
                            Layout.fillWidth: true
                            first: true
                            last: true
                            label: qsTr("Speed / Duration (deciseconds)")
                            subtext: qsTr("Higher is faster or longer depending on compositor rule")
                            from: 0.5
                            to: 30.0
                            stepSize: 0.5
                            value: targetRow.targetSpeed
                            onMoved: v => targetRow.targetSpeed = v
                        }

                        OptionRow {
                            Layout.fillWidth: true
                            first: true
                            last: true
                            title: qsTr("Bezier Easing Curve")
                            subtext: qsTr("Timing acceleration curve")
                            options: (AnimationManager.bezierCurves || []).map(c => ({ label: c.name, value: c.name }))
                            currentValue: targetRow.targetCurve
                            onOptionSelected: (val, lbl) => {
                                targetRow.targetCurve = val;
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Animation Style (e.g. popin, slide, slidevert, loop)")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Optional style flag (e.g. popin 80%, slide)")
                                text: targetRow.targetStyle
                                onTextEdited: targetRow.targetStyle = text
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
