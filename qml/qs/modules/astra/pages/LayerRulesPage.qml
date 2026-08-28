import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import Helm.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Layer Rules")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Layer Rule Management")
        }

        DialogRowButton {
            id: addLayerBtn
            rootParent: root
            first: true
            last: (AstraHelmWriter.layerRules || []).length === 0
            icon: "add_circle"
            label: qsTr("Add Layer Rule")
            header: qsTr("Add New Layer Rule")
            acceptLabel: qsTr("Save Rule")

            property string targetNamespace: ""
            property bool isBlur: true
            property bool isDimAround: false
            property bool isIgnoreAlpha: false
            property string targetAnimation: ""

            acceptAllowed: targetNamespace.trim() !== ""

            onAccepted: {
                if (targetNamespace.trim() !== "") {
                    var ruleMap = {
                        "namespace": targetNamespace.trim(),
                        "blur": isBlur,
                        "dimaround": isDimAround,
                        "ignorealpha": isIgnoreAlpha
                    };
                    if (targetAnimation.trim() !== "") {
                        ruleMap["animation"] = targetAnimation.trim();
                    }
                    AstraHelmWriter.addLayerRule(ruleMap);
                    AstraHelmWriter.save();
                    targetNamespace = "";
                    targetAnimation = "";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Layer Surface Namespace")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g. rofi, waybar, notifications, caelestia-.*")
                        text: addLayerBtn.targetNamespace
                        onTextEdited: addLayerBtn.targetNamespace = text
                    }

                    StyledText {
                        text: qsTr("Layer Surface Effects")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        ToggleRow {
                            first: true
                            text: qsTr("Blur Surface")
                            subtext: qsTr("Apply Kawase background blur behind layer surface")
                            checked: addLayerBtn.isBlur
                            onToggled: addLayerBtn.isBlur = checked
                        }

                        ToggleRow {
                            text: qsTr("Dim Around")
                            subtext: qsTr("Darken remainder of the screen behind layer")
                            checked: addLayerBtn.isDimAround
                            onToggled: addLayerBtn.isDimAround = checked
                        }

                        ToggleRow {
                            last: true
                            text: qsTr("Ignore Alpha")
                            subtext: qsTr("Treat transparent layer pixels as blurred")
                            checked: addLayerBtn.isIgnoreAlpha
                            onToggled: addLayerBtn.isIgnoreAlpha = checked
                        }
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Animation Style (Optional, e.g. popin 80%)")
                        text: addLayerBtn.targetAnimation
                        onTextEdited: addLayerBtn.targetAnimation = text
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configured Layer Rules (%1)").arg(AstraHelmWriter.layerRules.length)
        }

        Repeater {
            model: AstraHelmWriter.layerRules

            delegate: ConnectedRect {
                id: ruleRow
                required property var modelData
                required property int index

                first: index === 0
                last: index === AstraHelmWriter.layerRules.length - 1
                Layout.fillWidth: true
                implicitHeight: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "layers"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: ruleRow.modelData.namespace ? "Namespace: " + ruleRow.modelData.namespace : "Layer Rule " + (ruleRow.index + 1)
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: {
                                var props = [];
                                if (ruleRow.modelData.blur) props.push("blur");
                                if (ruleRow.modelData.dimaround) props.push("dimaround");
                                if (ruleRow.modelData.ignorealpha) props.push("ignorealpha");
                                if (ruleRow.modelData.animation) props.push("anim: " + ruleRow.modelData.animation);
                                return props.length > 0 ? props.join(" • ") : qsTr("Default layer behavior");
                            }
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: {
                            AstraHelmWriter.removeLayerRule(ruleRow.index);
                            AstraHelmWriter.save();
                        }
                    }
                }
            }
        }

        Item {
            visible: AstraHelmWriter.layerRules.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No custom layer rules defined yet.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
