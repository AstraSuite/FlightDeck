import QtQuick
import QtQuick.Layouts
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

    title: qsTr("Workspace rules")

    headerContent: Component {
        SearchBar {
            topPadding: Tokens.padding.small
            bottomPadding: Tokens.padding.small

            placeholderText: qsTr("Search workspace rules")
            font: Tokens.font.body.medium

            bg.color: Colours.tPalette.m3surfaceContainerLowest
            bg.border.color: Colours.palette.m3outlineVariant
            searchIcon.fontStyle: Tokens.font.icon.medium
            searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
            clearIcon.font: Tokens.font.icon.medium
            clearIcon.padding: Tokens.padding.extraSmall

            onTextChanged: root.searchText = text
        }
    }
    headerContentWidth: 260

    property string searchText: ""

    function getGapsValue(val) {
        if (val === undefined || val === null) return undefined;
        if (typeof val === "number") return val;
        if (typeof val === "string") {
            var num = parseInt(val);
            return isNaN(num) ? val : num;
        }
        if (val.length !== undefined && val.length > 0) return val[0];
        return undefined;
    }

    function formatWorkspaceTitle(m) {
        if (!m) return qsTr("Workspace Rule");
        var ws = m.workspace || m.workspaceString || "";
        var s = String(ws).trim();
        if (!s) return qsTr("Workspace Rule");

        if (s.indexOf("w[") !== -1) {
            return qsTr("Single Window (Smart Gaps)");
        }
        if (s.indexOf("f[") !== -1) {
            return qsTr("Fullscreen (Smart Gaps)");
        }
        return "Workspace " + s;
    }

    function formatWorkspaceIcon(m) {
        if (!m) return "space_dashboard";
        var ws = m.workspace || m.workspaceString || "";
        var s = String(ws).trim();
        if (s.indexOf("w[") !== -1) return "auto_awesome";
        if (s.indexOf("f[") !== -1) return "fit_screen";
        return "space_dashboard";
    }

    function formatWorkspaceSubtext(m) {
        if (!m) return qsTr("Default workspace behavior");
        var ws = m.workspace || m.workspaceString || "";
        var s = String(ws).trim();
        var parts = [];

        if (s.indexOf("w[") !== -1) {
            parts.push(qsTr("When only 1 window is visible"));
        } else if (s.indexOf("f[") !== -1) {
            parts.push(qsTr("When window is fullscreen"));
        }

        if (m.monitor) parts.push(qsTr("Monitor: %1").arg(m.monitor));
        if (m.default) parts.push(qsTr("Default"));
        if (m.persistent) parts.push(qsTr("Persistent"));

        var gi = root.getGapsValue(m.gapsin ?? m.gapsIn ?? m.gaps_in);
        var go = root.getGapsValue(m.gapsout ?? m.gapsOut ?? m.gaps_out);
        if (gi !== undefined && go !== undefined) {
            parts.push(qsTr("Gaps: %1 / %2 px").arg(gi).arg(go));
        } else if (go !== undefined) {
            parts.push(qsTr("Outer Gaps: %1 px").arg(go));
        } else if (gi !== undefined) {
            parts.push(qsTr("Inner Gaps: %1 px").arg(gi));
        }

        if (m.border === false) {
            parts.push(qsTr("No border"));
        } else if (m.bordersize !== undefined || m.borderSize !== undefined) {
            parts.push(qsTr("Border: %1 px").arg(m.bordersize !== undefined ? m.bordersize : m.borderSize));
        }

        if (m.rounding !== undefined) {
            parts.push(qsTr("Rounding: %1 px").arg(m.rounding));
        }

        if (m.layout) {
            parts.push(qsTr("Layout: %1").arg(m.layout));
        }

        if (m.on_created_empty || m["on-created-empty"]) {
            parts.push(qsTr("On empty: %1").arg(m.on_created_empty || m["on-created-empty"]));
        }

        if (m.isReadOnly) {
            parts.push(qsTr("System default"));
        }

        if (parts.length === 0) {
            return qsTr("Default workspace behavior");
        }
        return parts.join(" • ");
    }

    function workspaceRuleMatches(r) {
        const q = root.searchText.trim().toLowerCase();
        if (q === "") return true;
        const terms = q.split(/\s+/).filter(t => t.length > 0);

        let props = [];
        if (r.workspace) props.push("workspace " + r.workspace);
        if (r.workspaceString) props.push("workspace " + r.workspaceString);
        props.push(root.formatWorkspaceTitle(r));
        props.push(root.formatWorkspaceSubtext(r));
        if (r.monitor) props.push("monitor " + r.monitor);
        if (r.default) props.push("default");
        if (r.persistent) props.push("persistent");
        if (r.border !== undefined) props.push("border " + r.border);
        if (r.bordersize !== undefined || r.borderSize !== undefined) props.push("bordersize " + (r.bordersize !== undefined ? r.bordersize : r.borderSize));
        if (r.rounding !== undefined) props.push("rounding " + r.rounding);
        if (r.decorate !== undefined) props.push("decorate " + r.decorate);
        if (r.shadow !== undefined) props.push("shadow " + r.shadow);
        var gi = r.gapsin !== undefined ? r.gapsin : (r.gapsIn !== undefined ? (Array.isArray(r.gapsIn) ? r.gapsIn[0] : r.gapsIn) : undefined);
        var go = r.gapsout !== undefined ? r.gapsout : (r.gapsOut !== undefined ? (Array.isArray(r.gapsOut) ? r.gapsOut[0] : r.gapsOut) : undefined);
        if (gi !== undefined) props.push("gapsin " + gi);
        if (go !== undefined) props.push("gapsout " + go);
        if (r.on_created_empty || r["on-created-empty"]) props.push("on_created_empty " + (r.on_created_empty || r["on-created-empty"]));
        if (r.layout) props.push("layout " + r.layout);
        if (r.sourcePath) props.push(r.sourcePath);
        if (r.isReadOnly) props.push("system readonly default");

        const hay = props.join(" ").toLowerCase();
        for (let i = 0; i < terms.length; i++) {
            if (hay.indexOf(terms[i]) === -1) return false;
        }
        return true;
    }

    readonly property var filteredWorkspaceRules: {
        const q = root.searchText.trim();
        const src = FlightDeckWriter.workspaceRules;
        if (q === "") return src;
        const out = [];
        for (let i = 0; i < src.length; i++) {
            if (root.workspaceRuleMatches(src[i])) {
                out.push(src[i]);
            }
        }
        return out;
    }

    function findMasterWorkspaceRuleIndex(ruleData) {
        if (!ruleData) return -1;
        const list = FlightDeckWriter.workspaceRules;
        const targetStr = JSON.stringify(ruleData);
        for (let i = 0; i < list.length; i++) {
            if (list[i] === ruleData || JSON.stringify(list[i]) === targetStr) return i;
        }
        var targetWs = ruleData.workspace || ruleData.workspaceString || "";
        if (targetWs) {
            for (let i = 0; i < list.length; i++) {
                var itemWs = list[i].workspace || list[i].workspaceString || "";
                if (itemWs === targetWs) return i;
            }
        }
        return -1;
    }

    // Monitor options helper
    readonly property var availableMonitors: {
        const list = ["Any / Unspecified"];
        const mons = FlightDeckWriter.monitors;
        for (let i = 0; i < mons.length; i++) {
            const out = mons[i].output;
            if (out && list.indexOf(out) === -1) {
                list.push(out);
            }
        }
        return list;
    }

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        Component {
            id: menuItemComp
            MenuItem {}
        }

        SectionHeader {
            first: true
            visible: root.searchText.trim() === "" || root.filteredWorkspaceRules.length > 0
            text: qsTr("Workspace Rule Management")
        }

        // Add Workspace Rule Button
        DialogRowButton {
            id: addWorkspaceBtn
            rootParent: root.modalOverlay
            visible: root.searchText.trim() === ""
            first: true
            last: FlightDeckWriter.workspaceRules.length === 0
            icon: "add_circle"
            label: qsTr("Add Workspace Rule")
            header: qsTr("Add New Workspace Rule")
            acceptLabel: qsTr("Save Rule")
            separateContent: true
            horizontalContentMargin: -Tokens.padding.small
            openWidth: Math.min((rootParent ? rootParent.width : 580) * 0.95, 560)
            customOpenHeight: Math.min((rootParent ? rootParent.height : 720) * 0.95, 660)

            property string targetWorkspace: ""
            property string targetMonitor: "Any / Unspecified"
            property bool isDefault: false
            property bool isPersistent: false
            property bool hasBorderOverride: false
            property bool borderEnabled: true
            property int borderSize: 2
            property bool hasRoundingOverride: false
            property int roundingRadius: 10
            property bool hasDecorateOverride: false
            property bool decorateEnabled: true
            property bool hasShadowOverride: false
            property bool shadowEnabled: true
            property bool hasGapsOverride: false
            property int gapsInVal: 5
            property int gapsOutVal: 10
            property string layoutMode: "None"
            property string onCreatedEmptyCmd: ""

            acceptAllowed: targetWorkspace.trim() !== ""

            function resetFields() {
                targetWorkspace = "";
                targetMonitor = "Any / Unspecified";
                isDefault = false;
                isPersistent = false;
                hasBorderOverride = false;
                borderEnabled = true;
                borderSize = 2;
                hasRoundingOverride = false;
                roundingRadius = 10;
                hasDecorateOverride = false;
                decorateEnabled = true;
                hasShadowOverride = false;
                shadowEnabled = true;
                hasGapsOverride = false;
                gapsInVal = 5;
                gapsOutVal = 10;
                layoutMode = "None";
                onCreatedEmptyCmd = "";
            }

            onAccepted: {
                if (targetWorkspace.trim() !== "") {
                    var ruleMap = {
                        "workspace": targetWorkspace.trim()
                    };
                    if (targetMonitor !== "Any / Unspecified" && targetMonitor.trim() !== "") {
                        ruleMap["monitor"] = targetMonitor.trim();
                    }
                    if (isDefault) ruleMap["default"] = true;
                    if (isPersistent) ruleMap["persistent"] = true;
                    if (hasBorderOverride) {
                        ruleMap["border"] = borderEnabled;
                        if (borderEnabled) ruleMap["bordersize"] = borderSize;
                    }
                    if (hasRoundingOverride) {
                        ruleMap["rounding"] = roundingRadius;
                    }
                    if (hasDecorateOverride) {
                        ruleMap["decorate"] = decorateEnabled;
                    }
                    if (hasShadowOverride) {
                        ruleMap["shadow"] = shadowEnabled;
                    }
                    if (hasGapsOverride) {
                        ruleMap["gapsin"] = gapsInVal;
                        ruleMap["gapsout"] = gapsOutVal;
                    }
                    if (layoutMode !== "None" && layoutMode.trim() !== "") {
                        ruleMap["layout"] = layoutMode.trim();
                    }
                    if (onCreatedEmptyCmd.trim() !== "") {
                        ruleMap["on_created_empty"] = onCreatedEmptyCmd.trim();
                    }

                    FlightDeckWriter.addWorkspaceRule(ruleMap);
                    FlightDeckWriter.save();
                    resetFields();
                }
            }

            content: Component {
                VerticalFadeFlickable {
                    id: addWorkspaceFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: addWorkspaceCol.implicitHeight
                    topMargin: Tokens.padding.medium
                    bottomMargin: Tokens.padding.medium
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: addWorkspaceCol
                        width: parent.width
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Workspace Target")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            TextFieldRow {
                                first: true
                                last: true
                                label: qsTr("Target Workspace")
                                subtext: qsTr("Number (1-10), named, scratchpad, or smart gaps rule")
                                placeholderText: qsTr("e.g. 1, special:scratchpad, name:coding, w[tv1]s[false]")
                                value: addWorkspaceBtn.targetWorkspace
                                onValueEdited: val => addWorkspaceBtn.targetWorkspace = val
                            }
                        }

                        // Preset chips
                        Flow {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall

                            Repeater {
                                model: [
                                    { label: "1", val: "1" },
                                    { label: "2", val: "2" },
                                    { label: "3", val: "3" },
                                    { label: "4", val: "4" },
                                    { label: qsTr("Scratchpad"), val: "special:scratchpad" },
                                    { label: qsTr("Named Workspace"), val: "name:coding" },
                                    { label: qsTr("Smart Gaps (Single)"), val: "w[tv1]s[false]" },
                                    { label: qsTr("Smart Gaps (Fullscreen)"), val: "f[1]s[false]" }
                                ]
                                delegate: TextButton {
                                    required property var modelData
                                    text: modelData.label
                                    type: (addWorkspaceBtn.targetWorkspace === modelData.val) ? TextButton.Filled : TextButton.Tonal
                                    font: Tokens.font.label.small
                                    verticalPadding: Tokens.padding.extraSmall
                                    horizontalPadding: Tokens.padding.small
                                    onClicked: addWorkspaceBtn.targetWorkspace = modelData.val
                                }
                            }
                        }

                        StyledText {
                            text: qsTr("Display & Behavior")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            SelectRow {
                                first: true
                                last: false
                                label: qsTr("Assigned Monitor")
                                subtext: qsTr("Pin this workspace to a specific display output")
                                menuItems: {
                                    var items = [];
                                    for (var i = 0; i < root.availableMonitors.length; i++) {
                                        var mName = root.availableMonitors[i];
                                        items.push(menuItemComp.createObject(root, {
                                            text: mName,
                                            icon: mName === "Any / Unspecified" ? "desktop_windows" : "monitor"
                                        }));
                                    }
                                    return items;
                                }
                                active: {
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].text === addWorkspaceBtn.targetMonitor) return menuItems[i];
                                    }
                                    return menuItems[0];
                                }
                                onSelected: item => addWorkspaceBtn.targetMonitor = item.text
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Default on Monitor")
                                subtext: qsTr("Make this the default active workspace when compositor starts")
                                checked: addWorkspaceBtn.isDefault
                                onToggled: addWorkspaceBtn.isDefault = checked
                            }

                            ToggleRow {
                                first: false
                                last: true
                                text: qsTr("Persistent Workspace")
                                subtext: qsTr("Keep workspace active and visible in status bars even when empty")
                                checked: addWorkspaceBtn.isPersistent
                                onToggled: addWorkspaceBtn.isPersistent = checked
                            }
                        }

                        StyledText {
                            text: qsTr("Layout & Automation")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            SelectRow {
                                first: true
                                last: false
                                label: qsTr("Workspace Layout Engine")
                                subtext: qsTr("Override default tiling algorithm for this workspace")
                                menuItems: {
                                    var items = [];
                                    items.push(menuItemComp.createObject(root, { text: qsTr("None"), icon: "block" }));
                                    items.push(menuItemComp.createObject(root, { text: "dwindle", icon: "view_quilt" }));
                                    items.push(menuItemComp.createObject(root, { text: "master", icon: "view_column" }));
                                    items.push(menuItemComp.createObject(root, { text: "scrolling", icon: "view_stream" }));
                                    items.push(menuItemComp.createObject(root, { text: "monocle", icon: "fullscreen" }));
                                    return items;
                                }
                                active: {
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].text === addWorkspaceBtn.layoutMode) return menuItems[i];
                                    }
                                    return menuItems[0];
                                }
                                onSelected: item => addWorkspaceBtn.layoutMode = item.text
                            }

                            TextFieldRow {
                                first: false
                                last: true
                                label: qsTr("On Created Empty")
                                subtext: qsTr("Command to run when workspace is created empty")
                                placeholderText: qsTr("e.g. kitty, firefox")
                                value: addWorkspaceBtn.onCreatedEmptyCmd
                                onValueEdited: val => addWorkspaceBtn.onCreatedEmptyCmd = val
                            }
                        }

                        StyledText {
                            text: qsTr("Gaps & Appearance Overrides")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            ToggleRow {
                                first: true
                                last: false
                                text: qsTr("Override Gaps")
                                subtext: qsTr("Customize inner and outer gaps for windows on this workspace")
                                checked: addWorkspaceBtn.hasGapsOverride
                                onToggled: addWorkspaceBtn.hasGapsOverride = checked
                            }

                            SliderRow {
                                visible: addWorkspaceBtn.hasGapsOverride
                                first: false
                                last: false
                                label: qsTr("Inner Gaps (gapsin)")
                                subtext: qsTr("Gaps between adjacent windows in pixels")
                                value: addWorkspaceBtn.gapsInVal
                                valueLabel: addWorkspaceBtn.gapsInVal + " px"
                                from: 0
                                to: 40
                                stepSize: 1
                                onMoved: v => addWorkspaceBtn.gapsInVal = Math.round(v)
                                onInteraction: v => addWorkspaceBtn.gapsInVal = Math.round(v)
                            }

                            SliderRow {
                                visible: addWorkspaceBtn.hasGapsOverride
                                first: false
                                last: false
                                label: qsTr("Outer Gaps (gapsout)")
                                subtext: qsTr("Gaps between windows and screen edge in pixels")
                                value: addWorkspaceBtn.gapsOutVal
                                valueLabel: addWorkspaceBtn.gapsOutVal + " px"
                                from: 0
                                to: 60
                                stepSize: 1
                                onMoved: v => addWorkspaceBtn.gapsOutVal = Math.round(v)
                                onInteraction: v => addWorkspaceBtn.gapsOutVal = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Override Window Rounding")
                                subtext: qsTr("Custom corner rounding radius for this workspace")
                                checked: addWorkspaceBtn.hasRoundingOverride
                                onToggled: addWorkspaceBtn.hasRoundingOverride = checked
                            }

                            SliderRow {
                                visible: addWorkspaceBtn.hasRoundingOverride
                                first: false
                                last: false
                                label: qsTr("Corner Rounding Radius")
                                subtext: qsTr("Corner radius in pixels")
                                value: addWorkspaceBtn.roundingRadius
                                valueLabel: addWorkspaceBtn.roundingRadius + " px"
                                from: 0
                                to: 30
                                stepSize: 1
                                onMoved: v => addWorkspaceBtn.roundingRadius = Math.round(v)
                                onInteraction: v => addWorkspaceBtn.roundingRadius = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Override Window Borders")
                                subtext: qsTr("Toggle or customize window borders on this workspace")
                                checked: addWorkspaceBtn.hasBorderOverride
                                onToggled: addWorkspaceBtn.hasBorderOverride = checked
                            }

                            ToggleRow {
                                visible: addWorkspaceBtn.hasBorderOverride
                                first: false
                                last: false
                                text: qsTr("Enable Borders")
                                subtext: qsTr("Draw outline borders around tiled and floating windows")
                                checked: addWorkspaceBtn.borderEnabled
                                onToggled: addWorkspaceBtn.borderEnabled = checked
                            }

                            SliderRow {
                                visible: addWorkspaceBtn.hasBorderOverride && addWorkspaceBtn.borderEnabled
                                first: false
                                last: false
                                label: qsTr("Border Width")
                                subtext: qsTr("Thickness of window borders in pixels")
                                value: addWorkspaceBtn.borderSize
                                valueLabel: addWorkspaceBtn.borderSize + " px"
                                from: 1
                                to: 10
                                stepSize: 1
                                onMoved: v => addWorkspaceBtn.borderSize = Math.round(v)
                                onInteraction: v => addWorkspaceBtn.borderSize = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Window Decorations Override")
                                subtext: qsTr("Force enable or disable all window decorations")
                                checked: addWorkspaceBtn.hasDecorateOverride
                                onToggled: addWorkspaceBtn.hasDecorateOverride = checked
                            }

                            ToggleRow {
                                visible: addWorkspaceBtn.hasDecorateOverride
                                first: false
                                last: false
                                text: qsTr("Enable Window Decorations")
                                subtext: qsTr("Draw blur, shadows, and borders")
                                checked: addWorkspaceBtn.decorateEnabled
                                onToggled: addWorkspaceBtn.decorateEnabled = checked
                            }

                            ToggleRow {
                                first: false
                                last: !addWorkspaceBtn.hasShadowOverride
                                text: qsTr("Window Shadow Override")
                                subtext: qsTr("Control drop shadows for windows on this workspace")
                                checked: addWorkspaceBtn.hasShadowOverride
                                onToggled: addWorkspaceBtn.hasShadowOverride = checked
                            }

                            ToggleRow {
                                visible: addWorkspaceBtn.hasShadowOverride
                                first: false
                                last: true
                                text: qsTr("Enable Window Shadows")
                                subtext: qsTr("Render soft drop shadow behind windows")
                                checked: addWorkspaceBtn.shadowEnabled
                                onToggled: addWorkspaceBtn.shadowEnabled = checked
                            }
                        }
                    }
                }
            }
        }

        // Configured Workspace Rules List
        Repeater {
            model: root.filteredWorkspaceRules

            delegate: DialogRowButton {
                id: editWsRow
                required property var modelData
                required property int index

                readonly property bool isReadOnly: editWsRow.modelData ? (editWsRow.modelData.isReadOnly || false) : false

                rootParent: root.modalOverlay
                first: index === 0 && root.searchText.trim() !== ""
                last: index === root.filteredWorkspaceRules.length - 1
                icon: root.formatWorkspaceIcon(editWsRow.modelData)

                label: root.formatWorkspaceTitle(editWsRow.modelData)
                subtext: root.formatWorkspaceSubtext(editWsRow.modelData)

                header: editWsRow.isReadOnly ? qsTr("Override Workspace Rule") : qsTr("Edit Workspace Rule")
                acceptLabel: editWsRow.isReadOnly ? qsTr("Save Override") : qsTr("Save Changes")
                separateContent: true
                horizontalContentMargin: -Tokens.padding.small
                openWidth: Math.min((rootParent ? rootParent.width : 580) * 0.95, 560)
                customOpenHeight: Math.min((rootParent ? rootParent.height : 720) * 0.95, 660)

                property string targetWorkspace: ""
                property string targetMonitor: "Any / Unspecified"
                property bool isDefault: false
                property bool isPersistent: false
                property bool hasBorderOverride: false
                property bool borderEnabled: true
                property int borderSize: 2
                property bool hasRoundingOverride: false
                property int roundingRadius: 10
                property bool hasDecorateOverride: false
                property bool decorateEnabled: true
                property bool hasShadowOverride: false
                property bool shadowEnabled: true
                property bool hasGapsOverride: false
                property int gapsInVal: 5
                property int gapsOutVal: 10
                property string layoutMode: "None"
                property string onCreatedEmptyCmd: ""

                acceptAllowed: targetWorkspace.trim() !== ""

                onOpenChanged: {
                    if (open && editWsRow.modelData) {
                        var m = editWsRow.modelData;
                        targetWorkspace = m.workspace || m.workspaceString || "";
                        targetMonitor = m.monitor || "Any / Unspecified";
                        isDefault = !!m.default;
                        isPersistent = !!m.persistent;
                        hasBorderOverride = (m.border !== undefined || m.bordersize !== undefined || m.borderSize !== undefined);
                        borderEnabled = (m.border !== undefined) ? !!m.border : true;
                        borderSize = (m.bordersize !== undefined) ? m.bordersize : (m.borderSize !== undefined ? m.borderSize : 2);
                        hasRoundingOverride = (m.rounding !== undefined);
                        roundingRadius = (m.rounding !== undefined) ? m.rounding : 10;
                        hasDecorateOverride = (m.decorate !== undefined);
                        decorateEnabled = (m.decorate !== undefined) ? !!m.decorate : true;
                        hasShadowOverride = (m.shadow !== undefined);
                        shadowEnabled = (m.shadow !== undefined) ? !!m.shadow : true;
                        var gi = m.gapsin !== undefined ? m.gapsin : (m.gapsIn !== undefined ? (Array.isArray(m.gapsIn) ? m.gapsIn[0] : m.gapsIn) : undefined);
                        var go = m.gapsout !== undefined ? m.gapsout : (m.gapsOut !== undefined ? (Array.isArray(m.gapsOut) ? m.gapsOut[0] : m.gapsOut) : undefined);
                        hasGapsOverride = (gi !== undefined || go !== undefined);
                        gapsInVal = (gi !== undefined) ? gi : 5;
                        gapsOutVal = (go !== undefined) ? go : 10;
                        layoutMode = m.layout || "None";
                        onCreatedEmptyCmd = m.on_created_empty || m["on-created-empty"] || "";
                    }
                }

                onAccepted: {
                    if (targetWorkspace.trim() !== "") {
                        var ruleMap = {
                            "workspace": targetWorkspace.trim()
                        };
                        if (targetMonitor !== "Any / Unspecified" && targetMonitor.trim() !== "") {
                            ruleMap["monitor"] = targetMonitor.trim();
                        }
                        if (isDefault) ruleMap["default"] = true;
                        if (isPersistent) ruleMap["persistent"] = true;
                        if (hasBorderOverride) {
                            ruleMap["border"] = borderEnabled;
                            if (borderEnabled) ruleMap["bordersize"] = borderSize;
                        }
                        if (hasRoundingOverride) {
                            ruleMap["rounding"] = roundingRadius;
                        }
                        if (hasDecorateOverride) {
                            ruleMap["decorate"] = decorateEnabled;
                        }
                        if (hasShadowOverride) {
                            ruleMap["shadow"] = shadowEnabled;
                        }
                        if (hasGapsOverride) {
                            ruleMap["gapsin"] = gapsInVal;
                            ruleMap["gapsout"] = gapsOutVal;
                        }
                        if (layoutMode !== "None" && layoutMode.trim() !== "") {
                            ruleMap["layout"] = layoutMode.trim();
                        }
                        if (onCreatedEmptyCmd.trim() !== "") {
                            ruleMap["on_created_empty"] = onCreatedEmptyCmd.trim();
                        }

                        var masterIdx = root.findMasterWorkspaceRuleIndex(editWsRow.modelData);
                        if (masterIdx !== -1) {
                            FlightDeckWriter.updateWorkspaceRule(masterIdx, ruleMap);
                            FlightDeckWriter.save();
                        }
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            visible: !editWsRow.isReadOnly
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                var masterIdx = root.findMasterWorkspaceRuleIndex(editWsRow.modelData);
                                if (masterIdx !== -1) {
                                    FlightDeckWriter.removeWorkspaceRule(masterIdx);
                                    FlightDeckWriter.save();
                                }
                            }
                        }
                    }
                }

                content: Component {
                    VerticalFadeFlickable {
                        id: editWsFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: editWsCol.implicitHeight
                        topMargin: Tokens.padding.medium
                        bottomMargin: Tokens.padding.medium
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: editWsCol
                            width: parent.width
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Workspace Target")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                TextFieldRow {
                                    first: true
                                    last: true
                                    label: qsTr("Target Workspace")
                                    subtext: qsTr("Number (1-10), named, scratchpad, or smart gaps rule")
                                    placeholderText: qsTr("e.g. 1, special:scratchpad, name:coding, w[tv1]s[false]")
                                    value: editWsRow.targetWorkspace
                                    onValueEdited: val => editWsRow.targetWorkspace = val
                                }
                            }

                            // Preset chips
                            Flow {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall

                                Repeater {
                                    model: [
                                        { label: "1", val: "1" },
                                        { label: "2", val: "2" },
                                        { label: "3", val: "3" },
                                        { label: "4", val: "4" },
                                        { label: qsTr("Scratchpad"), val: "special:scratchpad" },
                                        { label: qsTr("Named Workspace"), val: "name:coding" },
                                        { label: qsTr("Smart Gaps (Single)"), val: "w[tv1]s[false]" },
                                        { label: qsTr("Smart Gaps (Fullscreen)"), val: "f[1]s[false]" }
                                    ]
                                    delegate: TextButton {
                                        required property var modelData
                                        text: modelData.label
                                        type: (editWsRow.targetWorkspace === modelData.val) ? TextButton.Filled : TextButton.Tonal
                                        font: Tokens.font.label.small
                                        verticalPadding: Tokens.padding.extraSmall
                                        horizontalPadding: Tokens.padding.small
                                        onClicked: editWsRow.targetWorkspace = modelData.val
                                    }
                                }
                            }

                            StyledText {
                                text: qsTr("Display & Behavior")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                SelectRow {
                                    first: true
                                    last: false
                                    label: qsTr("Assigned Monitor")
                                    subtext: qsTr("Pin this workspace to a specific display output")
                                    menuItems: {
                                        var items = [];
                                        for (var i = 0; i < root.availableMonitors.length; i++) {
                                            var mName = root.availableMonitors[i];
                                            items.push(menuItemComp.createObject(root, {
                                                text: mName,
                                                icon: mName === "Any / Unspecified" ? "desktop_windows" : "monitor"
                                            }));
                                        }
                                        return items;
                                    }
                                    active: {
                                        for (var i = 0; i < menuItems.length; i++) {
                                            if (menuItems[i].text === editWsRow.targetMonitor) return menuItems[i];
                                        }
                                        return menuItems[0];
                                    }
                                    onSelected: item => editWsRow.targetMonitor = item.text
                                }

                                ToggleRow {
                                    first: false
                                    last: false
                                    text: qsTr("Default on Monitor")
                                    subtext: qsTr("Make this the default active workspace when compositor starts")
                                    checked: editWsRow.isDefault
                                    onToggled: editWsRow.isDefault = checked
                                }

                                ToggleRow {
                                    first: false
                                    last: true
                                    text: qsTr("Persistent Workspace")
                                    subtext: qsTr("Keep workspace active and visible in status bars even when empty")
                                    checked: editWsRow.isPersistent
                                    onToggled: editWsRow.isPersistent = checked
                                }
                            }

                            StyledText {
                                text: qsTr("Layout & Automation")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                SelectRow {
                                    first: true
                                    last: false
                                    label: qsTr("Workspace Layout Engine")
                                    subtext: qsTr("Override default tiling algorithm for this workspace")
                                    menuItems: {
                                        var items = [];
                                        items.push(menuItemComp.createObject(root, { text: qsTr("None"), icon: "block" }));
                                        items.push(menuItemComp.createObject(root, { text: "dwindle", icon: "view_quilt" }));
                                        items.push(menuItemComp.createObject(root, { text: "master", icon: "view_column" }));
                                        items.push(menuItemComp.createObject(root, { text: "scrolling", icon: "view_stream" }));
                                        items.push(menuItemComp.createObject(root, { text: "monocle", icon: "fullscreen" }));
                                        return items;
                                    }
                                    active: {
                                        for (var i = 0; i < menuItems.length; i++) {
                                            if (menuItems[i].text === editWsRow.layoutMode) return menuItems[i];
                                        }
                                        return menuItems[0];
                                    }
                                    onSelected: item => editWsRow.layoutMode = item.text
                                }

                            TextFieldRow {
                                first: false
                                last: true
                                label: qsTr("On Created Empty")
                                subtext: qsTr("Command to run when workspace is created empty")
                                placeholderText: qsTr("e.g. kitty, firefox")
                                value: editWsRow.onCreatedEmptyCmd
                                onValueEdited: val => editWsRow.onCreatedEmptyCmd = val
                            }
                        }

                        StyledText {
                            text: qsTr("Gaps & Appearance Overrides")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            ToggleRow {
                                first: true
                                last: false
                                text: qsTr("Override Gaps")
                                subtext: qsTr("Customize inner and outer gaps for windows on this workspace")
                                checked: editWsRow.hasGapsOverride
                                onToggled: editWsRow.hasGapsOverride = checked
                            }

                            SliderRow {
                                visible: editWsRow.hasGapsOverride
                                first: false
                                last: false
                                label: qsTr("Inner Gaps (gapsin)")
                                subtext: qsTr("Gaps between adjacent windows in pixels")
                                value: editWsRow.gapsInVal
                                valueLabel: editWsRow.gapsInVal + " px"
                                from: 0
                                to: 40
                                stepSize: 1
                                onMoved: v => editWsRow.gapsInVal = Math.round(v)
                                onInteraction: v => editWsRow.gapsInVal = Math.round(v)
                            }

                            SliderRow {
                                visible: editWsRow.hasGapsOverride
                                first: false
                                last: false
                                label: qsTr("Outer Gaps (gapsout)")
                                subtext: qsTr("Gaps between windows and screen edge in pixels")
                                value: editWsRow.gapsOutVal
                                valueLabel: editWsRow.gapsOutVal + " px"
                                from: 0
                                to: 60
                                stepSize: 1
                                onMoved: v => editWsRow.gapsOutVal = Math.round(v)
                                onInteraction: v => editWsRow.gapsOutVal = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Override Window Rounding")
                                subtext: qsTr("Custom corner rounding radius for this workspace")
                                checked: editWsRow.hasRoundingOverride
                                onToggled: editWsRow.hasRoundingOverride = checked
                            }

                            SliderRow {
                                visible: editWsRow.hasRoundingOverride
                                first: false
                                last: false
                                label: qsTr("Corner Rounding Radius")
                                subtext: qsTr("Corner radius in pixels")
                                value: editWsRow.roundingRadius
                                valueLabel: editWsRow.roundingRadius + " px"
                                from: 0
                                to: 30
                                stepSize: 1
                                onMoved: v => editWsRow.roundingRadius = Math.round(v)
                                onInteraction: v => editWsRow.roundingRadius = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Override Window Borders")
                                subtext: qsTr("Toggle or customize window borders on this workspace")
                                checked: editWsRow.hasBorderOverride
                                onToggled: editWsRow.hasBorderOverride = checked
                            }

                            ToggleRow {
                                visible: editWsRow.hasBorderOverride
                                first: false
                                last: false
                                text: qsTr("Enable Borders")
                                subtext: qsTr("Draw outline borders around tiled and floating windows")
                                checked: editWsRow.borderEnabled
                                onToggled: editWsRow.borderEnabled = checked
                            }

                            SliderRow {
                                visible: editWsRow.hasBorderOverride && editWsRow.borderEnabled
                                first: false
                                last: false
                                label: qsTr("Border Width")
                                subtext: qsTr("Thickness of window borders in pixels")
                                value: editWsRow.borderSize
                                valueLabel: editWsRow.borderSize + " px"
                                from: 1
                                to: 10
                                stepSize: 1
                                onMoved: v => editWsRow.borderSize = Math.round(v)
                                onInteraction: v => editWsRow.borderSize = Math.round(v)
                            }

                            ToggleRow {
                                first: false
                                last: false
                                text: qsTr("Window Decorations Override")
                                subtext: qsTr("Force enable or disable all window decorations")
                                checked: editWsRow.hasDecorateOverride
                                onToggled: editWsRow.hasDecorateOverride = checked
                            }

                            ToggleRow {
                                visible: editWsRow.hasDecorateOverride
                                first: false
                                last: false
                                text: qsTr("Enable Window Decorations")
                                subtext: qsTr("Draw blur, shadows, and borders")
                                checked: editWsRow.decorateEnabled
                                onToggled: editWsRow.decorateEnabled = checked
                            }

                            ToggleRow {
                                first: false
                                last: !editWsRow.hasShadowOverride
                                text: qsTr("Window Shadow Override")
                                subtext: qsTr("Control drop shadows for windows on this workspace")
                                checked: editWsRow.hasShadowOverride
                                onToggled: editWsRow.hasShadowOverride = checked
                            }

                            ToggleRow {
                                visible: editWsRow.hasShadowOverride
                                first: false
                                last: true
                                text: qsTr("Enable Window Shadows")
                                subtext: qsTr("Render soft drop shadow behind windows")
                                checked: editWsRow.shadowEnabled
                                onToggled: editWsRow.shadowEnabled = checked
                            }
                        }
                        }
                    }
                }
            }
        }

        // Empty state when search yields no matches
        Item {
            visible: root.searchText.trim() !== "" && root.filteredWorkspaceRules.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 160

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search_off"
                    color: Colours.palette.m3outlineVariant
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No workspace rules match \"%1\"").arg(root.searchText)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }
    }
}
