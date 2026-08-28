import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Window Rules")

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Window Rules")
        }

        // Add Window Rule via DialogRowButton (always rounded with first: true, last: true)
        DialogRowButton {
            id: addRuleBtn
            rootParent: root.modalOverlay
            first: true
            last: true
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
            property bool isNoBlur: false
            property string targetWorkspace: ""

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
                    if (isNoBlur) ruleMap["noblur"] = true;
                    if (targetWorkspace.trim() !== "") {
                        ruleMap["workspace"] = targetWorkspace.trim();
                    }
                    FlightDeckWriter.addWindowRule(ruleMap);
                    FlightDeckWriter.save();
                    matchValue = "";
                    targetWorkspace = "";
                }
            }

            content: Component {
                ColumnLayout {
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Window Match Criteria")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        OptionRow {
                            first: true
                            last: false
                            Layout.preferredWidth: 160
                            implicitHeight: 44
                            title: ""
                            options: [
                                { label: qsTr("Window class"), value: "class" },
                                { label: qsTr("Window title"), value: "title" },
                                { label: qsTr("Initial class"), value: "initialClass" },
                                { label: qsTr("Initial title"), value: "initialTitle" }
                            ]
                            currentValue: {
                                if (addRuleBtn.matchKey === "class") return qsTr("Window class");
                                if (addRuleBtn.matchKey === "title") return qsTr("Window title");
                                return addRuleBtn.matchKey;
                            }
                            onOptionSelected: (val, lbl) => addRuleBtn.matchKey = val
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. ^(zen)$ or regex")
                            text: addRuleBtn.matchValue
                            onTextEdited: addRuleBtn.matchValue = text
                        }

                        ClientPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                            onClientSelected: (winClass, winTitle) => {
                                addRuleBtn.matchKey = "class";
                                addRuleBtn.matchValue = "^(" + winClass + ")$";
                            }
                        }
                    }

                    StyledText {
                        text: qsTr("Window Actions & Effects")
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
                            text: qsTr("Center Window")
                            subtext: qsTr("Center floating window upon creation")
                            checked: addRuleBtn.isCenter
                            onToggled: addRuleBtn.isCenter = checked
                        }

                        ToggleRow {
                            text: qsTr("Force Opaque")
                            subtext: qsTr("Disable transparency for this application")
                            checked: addRuleBtn.isOpaque
                            onToggled: addRuleBtn.isOpaque = checked
                        }

                        ToggleRow {
                            last: true
                            text: qsTr("No Blur")
                            subtext: qsTr("Disable blur behind window")
                            checked: addRuleBtn.isNoBlur
                            onToggled: addRuleBtn.isNoBlur = checked
                        }
                    }

                    StyledTextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Assign Workspace (Optional, e.g. 1, 2, special:sysmon)")
                        text: addRuleBtn.targetWorkspace
                        onTextEdited: addRuleBtn.targetWorkspace = text
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configured Rules (%1)").arg(FlightDeckWriter.windowRules.length)
        }

        // Each Configured Rule is its own DialogRowButton so editing morphs the entire button row!
        Repeater {
            model: FlightDeckWriter.windowRules

            delegate: DialogRowButton {
                id: editRuleRow
                required property var modelData
                required property int index

                rootParent: root.modalOverlay
                first: index === 0
                last: index === FlightDeckWriter.windowRules.length - 1
                icon: "web_asset"

                label: {
                    var r = editRuleRow.modelData;
                    var acts = [];
                    if (r.float) acts.push(qsTr("Float window"));
                    if (r.opaque) acts.push(qsTr("Force opaque"));
                    if (r.pin) acts.push(qsTr("Pin window"));
                    if (r.center) acts.push(qsTr("Center window"));
                    if (r.noblur) acts.push(qsTr("No blur"));
                    if (r.fullscreen) acts.push(qsTr("Fullscreen"));
                    if (r.workspace) acts.push(qsTr("Workspace %1").arg(r.workspace));
                    return acts.length > 0 ? acts.join(" + ") : (r.name || qsTr("Window Rule"));
                }

                subtext: {
                    var r = editRuleRow.modelData;
                    var conds = [];
                    if (r.match) {
                        for (var k in r.match) {
                            conds.push(k + ": " + r.match[k]);
                        }
                    }
                    return conds.length > 0 ? conds.join(" • ") : qsTr("Default matching");
                }

                header: qsTr("Edit Window Rule")
                acceptLabel: qsTr("Save Changes")

                property string matchKey: {
                    var r = editRuleRow.modelData;
                    if (r.match) {
                        for (var k in r.match) return k;
                    }
                    return "class";
                }
                property string matchValue: {
                    var r = editRuleRow.modelData;
                    if (r.match) {
                        for (var k in r.match) return r.match[k];
                    }
                    return "";
                }
                property bool isFloat: !!editRuleRow.modelData.float
                property bool isPin: !!editRuleRow.modelData.pin
                property bool isOpaque: !!editRuleRow.modelData.opaque
                property bool isCenter: !!editRuleRow.modelData.center
                property bool isNoBlur: !!editRuleRow.modelData.noblur
                property string targetWorkspace: editRuleRow.modelData.workspace || ""

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
                        if (isNoBlur) ruleMap["noblur"] = true;
                        if (targetWorkspace.trim() !== "") {
                            ruleMap["workspace"] = targetWorkspace.trim();
                        }
                        FlightDeckWriter.updateWindowRule(editRuleRow.index, ruleMap);
                        FlightDeckWriter.save();
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: editRuleRow.open = true
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                FlightDeckWriter.removeWindowRule(editRuleRow.index);
                                FlightDeckWriter.save();
                            }
                        }
                    }
                }

                content: Component {
                    ColumnLayout {
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: qsTr("Window Match Criteria")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            OptionRow {
                                first: true
                                last: false
                                Layout.preferredWidth: 160
                                implicitHeight: 44
                                title: ""
                                options: [
                                    { label: qsTr("Window class"), value: "class" },
                                    { label: qsTr("Window title"), value: "title" },
                                    { label: qsTr("Initial class"), value: "initialClass" },
                                    { label: qsTr("Initial title"), value: "initialTitle" }
                                ]
                                currentValue: {
                                    if (editRuleRow.matchKey === "class") return qsTr("Window class");
                                    if (editRuleRow.matchKey === "title") return qsTr("Window title");
                                    return editRuleRow.matchKey;
                                }
                                onOptionSelected: (val, lbl) => editRuleRow.matchKey = val
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("e.g. ^(zen)$ or regex")
                                text: editRuleRow.matchValue
                                onTextEdited: editRuleRow.matchValue = text
                            }

                            ClientPickerPopup {
                            Layout.alignment: Qt.AlignVCenter
                            rootParent: root.modalOverlay
                                onClientSelected: (winClass, winTitle) => {
                                    editRuleRow.matchKey = "class";
                                    editRuleRow.matchValue = "^(" + winClass + ")$";
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Window Actions & Effects")
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
                                checked: editRuleRow.isFloat
                                onToggled: editRuleRow.isFloat = checked
                            }

                            ToggleRow {
                                text: qsTr("Pin Window")
                                subtext: qsTr("Stay visible across all workspaces")
                                checked: editRuleRow.isPin
                                onToggled: editRuleRow.isPin = checked
                            }

                            ToggleRow {
                                text: qsTr("Center Window")
                                subtext: qsTr("Center floating window upon creation")
                                checked: editRuleRow.isCenter
                                onToggled: editRuleRow.isCenter = checked
                            }

                            ToggleRow {
                                text: qsTr("Force Opaque")
                                subtext: qsTr("Disable transparency for this application")
                                checked: editRuleRow.isOpaque
                                onToggled: editRuleRow.isOpaque = checked
                            }

                            ToggleRow {
                                last: true
                                text: qsTr("No Blur")
                                subtext: qsTr("Disable blur behind window")
                                checked: editRuleRow.isNoBlur
                                onToggled: editRuleRow.isNoBlur = checked
                            }
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Assign Workspace (Optional, e.g. 1, 2, special:sysmon)")
                            text: editRuleRow.targetWorkspace
                            onTextEdited: editRuleRow.targetWorkspace = text
                        }
                    }
                }
            }
        }

        Item {
            visible: FlightDeckWriter.windowRules.length === 0
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
