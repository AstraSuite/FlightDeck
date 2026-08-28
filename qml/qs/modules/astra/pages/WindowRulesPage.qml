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

    title: qsTr("Window Rules")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Rule Management")
        }

        DialogRowButton {
            id: addRuleBtn
            rootParent: root
            first: true
            last: (AstraHelmWriter.windowRules || []).length === 0
            icon: "add_circle"
            label: qsTr("Add Window Rule")
            header: qsTr("Add New Window Rule")
            acceptLabel: qsTr("Save Rule")

            property string matchKey: "class"
            property string matchValue: ""
            property bool isFloat: true
            property bool isPin: false
            property bool isOpaque: false
            property bool isCenter: false
            property string targetWorkspace: ""
            property bool showClientPicker: false
            property var clientsList: []

            acceptAllowed: matchValue.trim() !== ""

            onAccepted: {
                if (matchValue.trim() !== "") {
                    var ruleMap = {
                        "match": {
                            [matchKey]: matchValue.trim()
                        },
                        "float": isFloat,
                        "pin": isPin,
                        "center": isCenter,
                        "opaque": isOpaque
                    };
                    if (targetWorkspace.trim() !== "") {
                        ruleMap["workspace"] = targetWorkspace.trim();
                    }
                    AstraHelmWriter.addWindowRule(ruleMap);
                    AstraHelmWriter.save();
                    matchValue = "";
                    targetWorkspace = "";
                    showClientPicker = false;
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Match Window (Class Regex)")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.fillWidth: true
                        }

                        TextButton {
                            type: TextButton.Text
                            text: qsTr("Pick Open Window")
                            onClicked: {
                                addRuleBtn.clientsList = AstraHelmWriter.activeHyprlandClients();
                                addRuleBtn.showClientPicker = !addRuleBtn.showClientPicker;
                            }
                        }
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g. ^(kitty)$ or steam_app_.*")
                        text: addRuleBtn.matchValue
                        onTextEdited: addRuleBtn.matchValue = text
                    }

                    // Running Client Picker List
                    VerticalFadeListView {
                        visible: addRuleBtn.showClientPicker
                        Layout.fillWidth: true
                        implicitHeight: Math.min(120, count * 44)
                        clip: true
                        model: addRuleBtn.clientsList

                        delegate: StateLayer {
                            id: clLayer
                            required property var modelData
                            required property int index

                            width: parent ? parent.width : 320
                            implicitHeight: 40
                            radius: Tokens.rounding.small

                            onClicked: {
                                addRuleBtn.matchKey = "class";
                                addRuleBtn.matchValue = "^(" + (modelData.class || "") + ")$";
                                addRuleBtn.showClientPicker = false;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.small
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    text: "web_asset"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    text: clLayer.modelData.class || qsTr("Unknown")
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Window Properties")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        ToggleRow {
                            first: true
                            text: qsTr("Float Window")
                            subtext: qsTr("Open matched windows in floating mode")
                            checked: addRuleBtn.isFloat
                            onToggled: addRuleBtn.isFloat = checked
                        }

                        ToggleRow {
                            text: qsTr("Pin Window")
                            subtext: qsTr("Stay visible across all workspaces")
                            checked: addRuleBtn.isPin
                            onToggled: addRuleBtn.isPin = checked
                        }

                        ToggleRow {
                            text: qsTr("Center on Screen")
                            subtext: qsTr("Center floating window upon creation")
                            checked: addRuleBtn.isCenter
                            onToggled: addRuleBtn.isCenter = checked
                        }

                        ToggleRow {
                            last: true
                            text: qsTr("Force Opaque")
                            subtext: qsTr("Disable transparency for this application")
                            checked: addRuleBtn.isOpaque
                            onToggled: addRuleBtn.isOpaque = checked
                        }
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Assign Workspace (e.g. 1, 2, special:magic)")
                        text: addRuleBtn.targetWorkspace
                        onTextEdited: addRuleBtn.targetWorkspace = text
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configured Rules (%1)").arg(AstraHelmWriter.windowRules.length)
        }

        Repeater {
            model: AstraHelmWriter.windowRules

            delegate: ConnectedRect {
                id: ruleRow
                required property var modelData
                required property int index

                first: index === 0
                last: index === AstraHelmWriter.windowRules.length - 1
                Layout.fillWidth: true
                implicitHeight: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "web_asset"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: ruleRow.modelData.match ? (ruleRow.modelData.match.class ? "Class: " + ruleRow.modelData.match.class : (ruleRow.modelData.match.title ? "Title: " + ruleRow.modelData.match.title : "Match Criteria")) : "Rule " + (ruleRow.index + 1)
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: {
                                var props = [];
                                if (ruleRow.modelData.float) props.push("float");
                                if (ruleRow.modelData.opaque) props.push("opaque");
                                if (ruleRow.modelData.pin) props.push("pin");
                                if (ruleRow.modelData.center) props.push("center");
                                if (ruleRow.modelData.workspace) props.push("ws: " + ruleRow.modelData.workspace);
                                return props.length > 0 ? props.join(" • ") : qsTr("Default behavior");
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
                            AstraHelmWriter.removeWindowRule(ruleRow.index);
                            AstraHelmWriter.save();
                        }
                    }
                }
            }
        }

        Item {
            visible: AstraHelmWriter.windowRules.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No custom window rules defined yet.")
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
