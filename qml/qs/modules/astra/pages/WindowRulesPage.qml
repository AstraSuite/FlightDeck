pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    property int editingIndex: -1
    property var editingRule: null

    Item {
        id: container
        anchors.fill: parent

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.cappedWidth
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: true
                text: qsTr("Window Rules")
            }

            RowButton {
                first: true
                last: (AstraHelmWriter.windowRules || []).length === 0
                icon: "add_circle"
                label: qsTr("Add Window Rule")
                onClicked: {
                    root.editingIndex = -1;
                    root.editingRule = null;
                    ruleModal.open();
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
                                text: {
                                    var r = ruleRow.modelData;
                                    var acts = [];
                                    if (r.float) acts.push(qsTr("Float window"));
                                    if (r.opaque) acts.push(qsTr("Force opaque"));
                                    if (r.pin) acts.push(qsTr("Pin window"));
                                    if (r.center) acts.push(qsTr("Center window"));
                                    if (r.noblur) acts.push(qsTr("No blur"));
                                    if (r.fullscreen) acts.push(qsTr("Fullscreen"));
                                    if (r.workspace) acts.push(qsTr("Open on workspace: %1").arg(r.workspace));
                                    return acts.length > 0 ? acts.join(" + ") : (r.name || qsTr("Window Rule"));
                                }
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: {
                                    var r = ruleRow.modelData;
                                    var conds = [];
                                    if (r.match) {
                                        for (var k in r.match) {
                                            conds.push(k + ": " + r.match[k]);
                                        }
                                    }
                                    return conds.length > 0 ? conds.join(" • ") : qsTr("Default matching");
                                }
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                root.editingIndex = ruleRow.index;
                                root.editingRule = ruleRow.modelData;
                                ruleModal.open();
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

        // Add / Edit Window Rule Modal Overlay
        Item {
            id: ruleModal
            anchors.fill: parent
            z: 9999
            visible: false

            property string ruleName: ""
            property bool ruleEnabled: true
            property var conditions: [{ "key": "class", "value": "" }]
            property var actions: [{ "action": "float", "value": "" }]

            function resetFields() {
                ruleName = "";
                ruleEnabled = true;
                conditions = [{ "key": "class", "value": "" }];
                actions = [{ "action": "float", "value": "" }];
            }

            function open() {
                if (root.editingIndex >= 0 && root.editingRule) {
                    var r = root.editingRule;
                    ruleName = r.name || "";
                    ruleEnabled = r.enabled !== false;

                    var conds = [];
                    if (r.match) {
                        for (var k in r.match) {
                            conds.push({ "key": k, "value": r.match[k] });
                        }
                    }
                    if (conds.length === 0) conds.push({ "key": "class", "value": "" });
                    conditions = conds;

                    var acts = [];
                    if (r.float) acts.push({ "action": "float", "value": "" });
                    if (r.opaque) acts.push({ "action": "opaque", "value": "" });
                    if (r.pin) acts.push({ "action": "pin", "value": "" });
                    if (r.center) acts.push({ "action": "center", "value": "" });
                    if (r.noblur) acts.push({ "action": "noblur", "value": "" });
                    if (r.fullscreen) acts.push({ "action": "fullscreen", "value": "" });
                    if (r.workspace) acts.push({ "action": "workspace", "value": r.workspace });
                    if (r.opacity) acts.push({ "action": "opacity", "value": String(r.opacity) });
                    if (acts.length === 0) acts.push({ "action": "float", "value": "" });
                    actions = acts;
                } else {
                    resetFields();
                }
                visible = true;
            }

            function close() {
                visible = false;
            }

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                opacity: ruleModal.visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ruleModal.close()
                }
            }

            // Modal Card
            StyledRect {
                id: card
                width: Math.min(540, root.width - 32)
                height: Math.min(640, root.height - 32)
                anchors.centerIn: parent

                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                scale: ruleModal.visible ? 1.0 : 0.9
                opacity: ruleModal.visible ? 1 : 0

                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                MouseArea {
                    anchors.fill: parent
                }

                VerticalFadeFlickable {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    contentWidth: width
                    contentHeight: modalLayout.implicitHeight

                    ColumnLayout {
                        id: modalLayout
                        width: parent.width
                        spacing: Tokens.spacing.medium

                        // Top Header Bar
                        RowLayout {
                            Layout.fillWidth: true

                            TextButton {
                                text: qsTr("Cancel")
                                type: TextButton.Outlined
                                onClicked: ruleModal.close()
                            }

                            StyledText {
                                text: root.editingIndex >= 0 ? qsTr("Edit Window Rule") : qsTr("Add Window Rule")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Button {
                                id: applyBtn
                                text: qsTr("Apply")
                                enabled: ruleModal.conditions.length > 0 && ruleModal.conditions[0].value.trim() !== ""

                                background: StyledRect {
                                    radius: Tokens.rounding.medium
                                    color: applyBtn.enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.12)
                                }

                                contentItem: StyledText {
                                    text: applyBtn.text
                                    font: Tokens.font.label.large
                                    color: applyBtn.enabled ? Colours.palette.m3onPrimary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    var matchMap = {};
                                    for (var i = 0; i < ruleModal.conditions.length; ++i) {
                                        var c = ruleModal.conditions[i];
                                        if (c.value.trim() !== "") {
                                            matchMap[c.key] = c.value.trim();
                                        }
                                    }

                                    var ruleMap = {
                                        "match": matchMap,
                                        "enabled": ruleModal.ruleEnabled
                                    };
                                    if (ruleModal.ruleName.trim() !== "") {
                                        ruleMap["name"] = ruleModal.ruleName.trim();
                                    }

                                    for (var j = 0; j < ruleModal.actions.length; ++j) {
                                        var a = ruleModal.actions[j];
                                        if (a.action === "float") ruleMap["float"] = true;
                                        else if (a.action === "opaque") ruleMap["opaque"] = true;
                                        else if (a.action === "pin") ruleMap["pin"] = true;
                                        else if (a.action === "center") ruleMap["center"] = true;
                                        else if (a.action === "noblur") ruleMap["noblur"] = true;
                                        else if (a.action === "fullscreen") ruleMap["fullscreen"] = true;
                                        else if (a.action === "workspace" && a.value) ruleMap["workspace"] = a.value.trim();
                                        else if (a.action === "opacity" && a.value) ruleMap["opacity"] = a.value.trim();
                                    }

                                    if (root.editingIndex >= 0) {
                                        AstraHelmWriter.updateWindowRule(root.editingIndex, ruleMap);
                                    } else {
                                        AstraHelmWriter.addWindowRule(ruleMap);
                                    }
                                    AstraHelmWriter.save();
                                    ruleModal.close();
                                }
                            }

                            IconButton {
                                icon: "close"
                                type: IconButton.Text
                                onClicked: ruleModal.close()
                            }
                        }

                        // Name (optional) Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Name (optional)")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            StyledText {
                                text: qsTr("Naming a rule lets you enable / disable it at runtime via Hyprland's Lua API or hyprctl. Anonymous rules are written as the compact one-line form.")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            ConnectedRect {
                                first: true
                                last: false
                                Layout.fillWidth: true
                                implicitHeight: 56

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.medium

                                    StyledText {
                                        text: qsTr("Name")
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3onSurface
                                    }

                                    StyledTextField {
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("Rule name (optional)")
                                        text: ruleModal.ruleName
                                        onTextEdited: ruleModal.ruleName = text
                                    }
                                }
                            }

                            ConnectedRect {
                                first: false
                                last: true
                                Layout.fillWidth: true
                                implicitHeight: 64

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.medium

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            text: qsTr("Enabled")
                                            font: Tokens.font.body.small
                                            color: Colours.palette.m3onSurface
                                        }

                                        StyledText {
                                            text: qsTr("Uncheck to keep the rule defined but inactive on next reload.")
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3outline
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Switch {
                                        checked: ruleModal.ruleEnabled
                                        onToggled: ruleModal.ruleEnabled = checked
                                    }
                                }
                            }
                        }

                        // Match windows where... Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    text: qsTr("Match windows where...")
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3onSurface
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    icon: "search"
                                    type: IconButton.Filled
                                    onClicked: clientPicker.open()
                                }

                                IconButton {
                                    icon: "add"
                                    type: IconButton.Filled
                                    onClicked: {
                                        var conds = [...ruleModal.conditions];
                                        conds.push({ "key": "title", "value": "" });
                                        ruleModal.conditions = conds;
                                    }
                                }
                            }

                            StyledText {
                                text: qsTr("Add one or more conditions. Hyprland matches windows where ALL conditions apply.")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Repeater {
                                model: ruleModal.conditions

                                delegate: ConnectedRect {
                                    id: condRow
                                    required property var modelData
                                    required property int index

                                    first: condRow.index === 0
                                    last: condRow.index === ruleModal.conditions.length - 1
                                    Layout.fillWidth: true
                                    implicitHeight: 56

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.medium
                                        anchors.leftMargin: Tokens.padding.largeIncreased
                                        anchors.rightMargin: Tokens.padding.largeIncreased
                                        spacing: Tokens.spacing.small

                                        OptionRow {
                                            first: true
                                            last: true
                                            Layout.preferredWidth: 150
                                            implicitHeight: 40
                                            options: [
                                                { label: qsTr("Window class"), value: "class" },
                                                { label: qsTr("Window title"), value: "title" },
                                                { label: qsTr("Initial class"), value: "initialClass" },
                                                { label: qsTr("Initial title"), value: "initialTitle" },
                                                { label: qsTr("Floating"), value: "floating" }
                                            ]
                                            currentValue: condRow.modelData.key === "class" ? qsTr("Window class") : (condRow.modelData.key === "title" ? qsTr("Window title") : condRow.modelData.key)
                                            onOptionSelected: (val, lbl) => {
                                                var conds = [...ruleModal.conditions];
                                                conds[condRow.index].key = val;
                                                ruleModal.conditions = conds;
                                            }
                                        }

                                        StyledTextField {
                                            Layout.fillWidth: true
                                            placeholderText: qsTr("e.g. ^(zen)$ or regex")
                                            text: condRow.modelData.value || ""
                                            onTextEdited: {
                                                var conds = [...ruleModal.conditions];
                                                conds[condRow.index].value = text;
                                                ruleModal.conditions = conds;
                                            }
                                        }

                                        IconButton {
                                            icon: "delete"
                                            type: IconButton.Text
                                            visible: ruleModal.conditions.length > 1
                                            onClicked: {
                                                var conds = [...ruleModal.conditions];
                                                conds.splice(condRow.index, 1);
                                                ruleModal.conditions = conds;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Apply these actions Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    text: qsTr("Apply these actions")
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3onSurface
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    icon: "add"
                                    type: IconButton.Filled
                                    onClicked: {
                                        var acts = [...ruleModal.actions];
                                        acts.push({ "action": "opaque", "value": "" });
                                        ruleModal.actions = acts;
                                    }
                                }
                            }

                            StyledText {
                                text: qsTr("Pick what Hyprland should do when a matching window opens.")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                            }

                            Repeater {
                                model: ruleModal.actions

                                delegate: ConnectedRect {
                                    id: actRow
                                    required property var modelData
                                    required property int index

                                    first: actRow.index === 0
                                    last: actRow.index === ruleModal.actions.length - 1
                                    Layout.fillWidth: true
                                    implicitHeight: 56

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.medium
                                        anchors.leftMargin: Tokens.padding.largeIncreased
                                        anchors.rightMargin: Tokens.padding.largeIncreased
                                        spacing: Tokens.spacing.small

                                        OptionRow {
                                            first: true
                                            last: true
                                            Layout.fillWidth: true
                                            implicitHeight: 40
                                            options: [
                                                { label: qsTr("Float window"), value: "float" },
                                                { label: qsTr("Force opaque"), value: "opaque" },
                                                { label: qsTr("Pin window"), value: "pin" },
                                                { label: qsTr("Center window"), value: "center" },
                                                { label: qsTr("No blur"), value: "noblur" },
                                                { label: qsTr("Fullscreen"), value: "fullscreen" }
                                            ]
                                            currentValue: {
                                                var map = { "float": qsTr("Float window"), "opaque": qsTr("Force opaque"), "pin": qsTr("Pin window"), "center": qsTr("Center window"), "noblur": qsTr("No blur"), "fullscreen": qsTr("Fullscreen") };
                                                return map[actRow.modelData.action] || actRow.modelData.action;
                                            }
                                            onOptionSelected: (val, lbl) => {
                                                var acts = [...ruleModal.actions];
                                                acts[actRow.index].action = val;
                                                ruleModal.actions = acts;
                                            }
                                        }

                                        IconButton {
                                            icon: "delete"
                                            type: IconButton.Text
                                            visible: ruleModal.actions.length > 1
                                            onClicked: {
                                                var acts = [...ruleModal.actions];
                                                acts.splice(actRow.index, 1);
                                                ruleModal.actions = acts;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Preview Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            StyledText {
                                text: qsTr("Preview")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ConnectedRect {
                                first: true
                                last: true
                                Layout.fillWidth: true
                                implicitHeight: 50
                                color: Colours.palette.m3surfaceContainerLowest

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    spacing: Tokens.spacing.medium

                                    StyledText {
                                        text: {
                                            var actList = [];
                                            for (var i = 0; i < ruleModal.actions.length; ++i) {
                                                var a = ruleModal.actions[i];
                                                if (a.action === "float") actList.push(qsTr("Float window"));
                                                else if (a.action === "opaque") actList.push(qsTr("Force opaque"));
                                                else if (a.action === "pin") actList.push(qsTr("Pin window"));
                                                else if (a.action === "center") actList.push(qsTr("Center window"));
                                                else if (a.action === "noblur") actList.push(qsTr("No blur"));
                                                else if (a.action === "fullscreen") actList.push(qsTr("Fullscreen"));
                                            }
                                            var condList = [];
                                            for (var j = 0; j < ruleModal.conditions.length; ++j) {
                                                var c = ruleModal.conditions[j];
                                                if (c.value) condList.push(c.key + ": " + c.value);
                                            }
                                            return (actList.join(" + ") || qsTr("Default")) + (condList.length > 0 ? " | " + condList.join(" & ") : "");
                                        }
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3primary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ClientPickerDialog {
            id: clientPicker
            onClientSelected: (winClass, winTitle, initialClass, initialTitle) => {
                if (ruleModal.visible) {
                    var conds = [...ruleModal.conditions];
                    if (conds.length > 0) {
                        conds[0] = { "key": "class", "value": "^(" + winClass + ")$" };
                    } else {
                        conds.push({ "key": "class", "value": "^(" + winClass + ")$" });
                    }
                    ruleModal.conditions = conds;
                }
            }
        }
    }
}
