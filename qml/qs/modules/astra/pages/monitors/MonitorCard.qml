import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

ColumnLayout {
    id: root

    property var cardModelData: ({})
    property int cardIndex: 0

    property bool isExpanded: false
    property bool minLumLocked: true
    property bool maxLumLocked: true

    readonly property var mon: root.cardModelData || ({})
    readonly property int index: root.cardIndex
    readonly property string connectorName: mon.name || mon.output || ""
    readonly property string displayName: {
        var make = (mon.make || "").replace(/ Technologies| Electronics| Corporation| Inc\.| LLC/gi, "").trim();
        var model = mon.model || "";
        if (make.length > 0 && model.length > 0) {
            return make + " " + model;
        }
        if (model.length > 0) return model;
        if (mon.description && mon.description.length > 0) return mon.description;
        return connectorName;
    }

    readonly property bool isDisabled: mon.disabled ?? false
    readonly property var availableModes: mon.availableModes || []

    // 1. Available unique resolutions (WIDTHxHEIGHT)
    readonly property var availableResolutions: {
        var resList = [];
        var seen = {};
        for (var i = 0; i < availableModes.length; i++) {
            var m = availableModes[i];
            var parts = m.split("@");
            if (parts.length >= 1) {
                var res = parts[0].trim();
                if (!seen[res]) {
                    seen[res] = true;
                    resList.push(res);
                }
            }
        }
        return resList;
    }

    // 2. Current selected resolution
    readonly property string currentResolution: {
        var w = mon.width || 1920;
        var h = mon.height || 1080;
        return w + "x" + h;
    }

    // 3. Available refresh rates for current resolution
    readonly property var availableRatesForCurrentRes: {
        var curRes = currentResolution;
        var rates = [];
        var seen = {};
        for (var i = 0; i < availableModes.length; i++) {
            var m = availableModes[i];
            var parts = m.split("@");
            if (parts.length === 2 && parts[0].trim() === curRes) {
                var hzStr = parts[1].replace(/Hz/gi, "").trim();
                var hzVal = parseFloat(hzStr);
                var hzLabel = (Math.round(hzVal * 100) / 100) + " Hz";
                if (!seen[hzLabel]) {
                    seen[hzLabel] = true;
                    rates.push({ val: hzVal, label: hzLabel, raw: m });
                }
            }
        }
        rates.sort(function(a, b) { return b.val - a.val; });
        return rates;
    }

    Component {
        id: menuItemComp
        MenuItem {}
    }

    function updateMon(key, val) {
        var copy = Object.assign({}, mon);
        copy[key] = val;
        copy.output = connectorName;
        if (!copy.mode && mon.width && mon.height) {
            copy.mode = mon.width + "x" + mon.height + "@" + (mon.refreshRate || 60);
        }
        if (!copy.position) {
            copy.position = (mon.x || 0) + "x" + (mon.y || 0);
        }
        MonitorManager.applyMonitor(copy);
    }

    function updateMonMultiple(pairs) {
        var copy = Object.assign({}, mon);
        for (var k in pairs) {
            copy[k] = pairs[k];
        }
        copy.output = connectorName;
        if (!copy.mode && mon.width && mon.height) {
            copy.mode = mon.width + "x" + mon.height + "@" + (mon.refreshRate || 60);
        }
        if (!copy.position) {
            copy.position = (mon.x || 0) + "x" + (mon.y || 0);
        }
        MonitorManager.applyMonitor(copy);
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    // 1. Header with Display Name, Connector, Status, and Enable/Disable Switch
    ToggleRow {
        first: true
        text: (root.index + 1) + ". " + root.displayName + " (" + root.connectorName + ")"
        subtext: root.isDisabled
            ? qsTr("Display is disabled  •  Toggle switch to enable")
            : qsTr("%1x%2 @ %3Hz  •  Pos: (%4, %5)  •  Scale: %6x")
                .arg(root.mon.width || 1920)
                .arg(root.mon.height || 1080)
                .arg(Number(root.mon.refreshRate || 60).toFixed(2).replace(/\.00$/, ""))
                .arg(root.mon.x || 0)
                .arg(root.mon.y || 0)
                .arg(Number(root.mon.scale || 1.0).toFixed(2))
        checked: !root.isDisabled
        onToggled: {
            root.updateMon("disabled", !checked);
        }
    }

    // Capability chips / info banner
    ConnectedRect {
        Layout.fillWidth: true
        implicitHeight: 36
        visible: Boolean(root.mon.supportsHdr || root.mon.supports10Bit || root.mon.supportsVrr)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Capabilities:")
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
            }

            StyledRect {
                visible: !!root.mon.supportsHdr
                implicitWidth: 38
                implicitHeight: 20
                radius: Tokens.rounding.full
                color: Colours.palette.m3primaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "HDR"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onPrimaryContainer
                }
            }

            StyledRect {
                visible: !!root.mon.supports10Bit
                implicitWidth: 44
                implicitHeight: 20
                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "10-bit"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSecondaryContainer
                }
            }

            StyledRect {
                visible: !!root.mon.supportsVrr
                implicitWidth: 38
                implicitHeight: 20
                radius: Tokens.rounding.full
                color: Colours.palette.m3tertiaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "VRR"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onTertiaryContainer
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // 2. Resolution Selector
    SelectRow {
        label: qsTr("Resolution")
        subtext: qsTr("Pixel dimensions for %1").arg(root.connectorName)
        menuItems: {
            var items = [];
            items.push(menuItemComp.createObject(root, { text: "Preferred / Auto", icon: "auto_mode" }));

            var resList = root.availableResolutions;
            for (var i = 0; i < resList.length; i++) {
                items.push(menuItemComp.createObject(root, { text: resList[i], icon: "aspect_ratio" }));
            }
            return items;
        }
        active: {
            var cur = root.currentResolution;
            for (var i = 1; i < menuItems.length; i++) {
                if (menuItems[i].text === cur) {
                    return menuItems[i];
                }
            }
            return menuItems[0];
        }
        onSelected: item => {
            if (item.text === "Preferred / Auto") {
                root.updateMon("mode", "preferred");
            } else {
                var resStr = item.text;
                var p = resStr.split("x");
                if (p.length === 2) {
                    var w = parseInt(p[0]);
                    var h = parseInt(p[1]);
                    var maxHz = 60;
                    for (var i = 0; i < root.availableModes.length; i++) {
                        var m = root.availableModes[i];
                        if (m.indexOf(resStr + "@") === 0) {
                            var hz = parseFloat(m.split("@")[1].replace(/Hz/gi, ""));
                            if (hz > maxHz) maxHz = hz;
                        }
                    }
                    var modeStr = w + "x" + h + "@" + (Math.round(maxHz * 100) / 100) + "Hz";
                    root.updateMonMultiple({ width: w, height: h, refreshRate: maxHz, mode: modeStr });
                }
            }
        }
    }

    // 3. Refresh Rate Selector
    SelectRow {
        label: qsTr("Refresh Rate")
        subtext: qsTr("Display refresh frequency for %1").arg(root.currentResolution)
        menuItems: {
            var items = [];
            items.push(menuItemComp.createObject(root, { text: "Max / Auto", icon: "auto_mode" }));

            var rates = root.availableRatesForCurrentRes;
            for (var i = 0; i < rates.length; i++) {
                items.push(menuItemComp.createObject(root, { text: rates[i].label, icon: "speed" }));
            }
            return items;
        }
        active: {
            var curHz = (Math.round((root.mon.refreshRate || 60) * 100) / 100) + " Hz";
            for (var i = 1; i < menuItems.length; i++) {
                if (menuItems[i].text === curHz) {
                    return menuItems[i];
                }
            }
            return menuItems[0];
        }
        onSelected: item => {
            if (item.text === "Max / Auto") {
                var rates = root.availableRatesForCurrentRes;
                if (rates.length > 0) {
                    var topRate = rates[0].val;
                    var modeStr = root.currentResolution + "@" + (Math.round(topRate * 100) / 100) + "Hz";
                    root.updateMonMultiple({ refreshRate: topRate, mode: modeStr });
                }
            } else {
                var hzVal = parseFloat(item.text.replace(/Hz/gi, "").trim());
                if (hzVal > 0) {
                    var modeStr = root.currentResolution + "@" + (Math.round(hzVal * 100) / 100) + "Hz";
                    root.updateMonMultiple({ refreshRate: hzVal, mode: modeStr });
                }
            }
        }
    }

    // 4. Scale Slider
    SliderRow {
        label: qsTr("Display Scale")
        subtext: qsTr("UI scaling: %1x (%2%)")
            .arg(Number(root.mon.scale || 1.0).toFixed(2))
            .arg(Math.round((root.mon.scale || 1.0) * 100))
        value: root.mon.scale || 1.0
        valueLabel: Number(root.mon.scale || 1.0).toFixed(2) + "x"
        from: 0.5
        to: 3.0
        stepSize: 0.05
        onInteraction: v => {
            var rounded = Math.round(v * 20) / 20;
            root.updateMon("scale", rounded);
        }
    }

    // 5. Orientation (4 cardinal rotations)
    SelectRow {
        label: qsTr("Display Orientation")
        subtext: qsTr("Rotation angle for %1").arg(root.connectorName)
        menuItems: [
            MenuItem {
                text: qsTr("Normal (0°)")
                icon: "crop_portrait"
                onClicked: {
                    var isFlipped = (root.mon.transform ?? 0) >= 4;
                    root.updateMon("transform", (isFlipped ? 4 : 0) + 0);
                }
            },
            MenuItem {
                text: qsTr("90° Portrait")
                icon: "crop_rotate"
                onClicked: {
                    var isFlipped = (root.mon.transform ?? 0) >= 4;
                    root.updateMon("transform", (isFlipped ? 4 : 0) + 1);
                }
            },
            MenuItem {
                text: qsTr("180° Inverted")
                icon: "screen_rotation"
                onClicked: {
                    var isFlipped = (root.mon.transform ?? 0) >= 4;
                    root.updateMon("transform", (isFlipped ? 4 : 0) + 2);
                }
            },
            MenuItem {
                text: qsTr("270° Portrait")
                icon: "crop_rotate"
                onClicked: {
                    var isFlipped = (root.mon.transform ?? 0) >= 4;
                    root.updateMon("transform", (isFlipped ? 4 : 0) + 3);
                }
            }
        ]
        active: {
            var baseRot = (root.mon.transform ?? 0) % 4;
            return (baseRot >= 0 && baseRot < menuItems.length) ? menuItems[baseRot] : menuItems[0];
        }
    }

    // 6. Flip Display Toggle
    ToggleRow {
        text: qsTr("Flip Display Output")
        subtext: qsTr("Horizontally mirror / flip display rendering")
        checked: (root.mon.transform ?? 0) >= 4
        onToggled: {
            var baseRot = (root.mon.transform ?? 0) % 4;
            var newTransform = (checked ? 4 : 0) + baseRot;
            root.updateMon("transform", newTransform);
        }
    }

    // 7. Expand / Collapse Advanced Options Button
    ButtonRow {
        last: !root.isExpanded
        text: root.isExpanded ? qsTr("Hide Advanced Options") : qsTr("Show Advanced Options")
        subtext: qsTr("Configure precise position, mirroring, VRR, bit depth, color management, and HDR")
        icon: root.isExpanded ? "expand_less" : "expand_more"
        actionLabel: ""
        onClicked: root.isExpanded = !root.isExpanded
    }

    // ==========================================
    // ADVANCED SECTION (Animated Collapse/Expand)
    // ==========================================
    Item {
        id: advancedContainer
        Layout.fillWidth: true
        clip: true
        implicitHeight: root.isExpanded ? advancedCol.implicitHeight : 0
        opacity: root.isExpanded ? 1.0 : 0.0
        visible: implicitHeight > 0 || opacity > 0

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: advancedCol
            width: advancedContainer.width
            spacing: Tokens.spacing.extraSmall / 2

            // Precise Position X & Y
            StepperRow {
                label: qsTr("Position X")
                subtext: qsTr("Horizontal pixel coordinate on virtual canvas")
                value: root.mon.x || 0
                from: -32768
                to: 32768
                stepSize: 10
                onMoved: v => {
                    var newPos = Math.round(v) + "x" + (root.mon.y || 0);
                    root.updateMonMultiple({ x: Math.round(v), position: newPos });
                }
            }

            StepperRow {
                label: qsTr("Position Y")
                subtext: qsTr("Vertical pixel coordinate on virtual canvas")
                value: root.mon.y || 0
                from: -32768
                to: 32768
                stepSize: 10
                onMoved: v => {
                    var newPos = (root.mon.x || 0) + "x" + Math.round(v);
                    root.updateMonMultiple({ y: Math.round(v), position: newPos });
                }
            }

            // Mirror display
            SelectRow {
                label: qsTr("Mirror Display")
                subtext: qsTr("Mirror another connected active display")
                menuItems: {
                    var items = [];
                    items.push(menuItemComp.createObject(root, { text: "Off", icon: "visibility_off" }));
                    var mons = MonitorManager.liveMonitors;
                    for (var i = 0; i < mons.length; i++) {
                        var mName = mons[i].name || "";
                        if (mName !== root.connectorName && !mons[i].disabled) {
                            items.push(menuItemComp.createObject(root, { text: mName, icon: "content_copy" }));
                        }
                    }
                    return items;
                }
                active: {
                    var m = root.mon.mirror || root.mon.mirror_of || "none";
                    for (var i = 1; i < menuItems.length; i++) {
                        if (menuItems[i].text === m) return menuItems[i];
                    }
                    return menuItems[0];
                }
                onSelected: item => {
                    if (item.text === "Off") {
                        root.updateMon("mirror", "none");
                    } else {
                        var err = MonitorManager.validateMirror(root.connectorName, item.text);
                        if (err === "") {
                            root.updateMon("mirror", item.text);
                        }
                    }
                }
            }

            // Identify by Description
            ToggleRow {
                text: qsTr("Identify by Description")
                subtext: qsTr("Bind display configuration to description prefix rather than physical connector port")
                checked: !!(root.mon.identify_by_description || root.mon.identifyByDescription)
                onToggled: root.updateMon("identify_by_description", checked)
            }

            // Variable Refresh Rate (VRR)
            SelectRow {
                label: qsTr("Variable Refresh Rate (VRR)")
                subtext: qsTr("Adaptive sync / G-Sync / FreeSync mode")
                menuItems: [
                    MenuItem { text: qsTr("Use global setting"); icon: "settings"; onClicked: root.updateMon("vrr", null) },
                    MenuItem { text: qsTr("Off (0)"); icon: "cancel"; onClicked: root.updateMon("vrr", 0) },
                    MenuItem { text: qsTr("On (1)"); icon: "check_circle"; onClicked: root.updateMon("vrr", 1) },
                    MenuItem { text: qsTr("Fullscreen only (2)"); icon: "fullscreen"; onClicked: root.updateMon("vrr", 2) },
                    MenuItem { text: qsTr("Fullscreen + Gaming (3)"); icon: "sports_esports"; onClicked: root.updateMon("vrr", 3) }
                ]
                active: {
                    var v = root.mon.vrr;
                    if (v === null || v === undefined) return menuItems[0];
                    if (v >= 0 && v + 1 < menuItems.length) return menuItems[v + 1];
                    return menuItems[0];
                }
            }

            // Bit Depth
            SelectRow {
                label: qsTr("Bit Depth")
                subtext: qsTr("Color depth per channel")
                menuItems: [
                    MenuItem { text: qsTr("Auto"); icon: "auto_fix_high"; onClicked: root.updateMon("bitdepth", null) },
                    MenuItem { text: qsTr("8-bit"); icon: "palette"; onClicked: root.updateMon("bitdepth", 8) },
                    MenuItem { text: qsTr("10-bit"); icon: "hdr_on"; onClicked: root.updateMon("bitdepth", 10) }
                ]
                active: {
                    var bd = root.mon.bitdepth || root.mon.bit_depth;
                    if (bd === 8) return menuItems[1];
                    if (bd === 10) return menuItems[2];
                    return menuItems[0];
                }
            }

            // Color Management
            SelectRow {
                last: {
                    var cm = (root.mon.cm || root.mon.colorManagement || "").toLowerCase();
                    return cm !== "hdr" && cm !== "hdredid";
                }
                label: qsTr("Color Management")
                subtext: qsTr("Color space and HDR pipeline mode")
                menuItems: [
                    MenuItem { text: qsTr("Auto / Default"); icon: "tune"; onClicked: root.updateMon("cm", "") },
                    MenuItem { text: qsTr("sRGB"); icon: "palette"; onClicked: root.updateMon("cm", "srgb") },
                    MenuItem { text: qsTr("Adobe RGB"); icon: "palette"; onClicked: root.updateMon("cm", "adobe") },
                    MenuItem { text: qsTr("Display P3 / Wide"); icon: "palette"; onClicked: root.updateMon("cm", "wide") },
                    MenuItem { text: qsTr("EDID profile"); icon: "badge"; onClicked: root.updateMon("cm", "edid") },
                    MenuItem { text: qsTr("HDR"); icon: "hdr_on"; onClicked: root.updateMon("cm", "hdr") },
                    MenuItem { text: qsTr("HDR (EDID)"); icon: "hdr_enhanced_select"; onClicked: root.updateMon("cm", "hdredid") }
                ]
                active: {
                    var cm = (root.mon.cm || root.mon.colorManagement || "").toLowerCase();
                    if (cm === "srgb") return menuItems[1];
                    if (cm === "adobe") return menuItems[2];
                    if (cm === "wide") return menuItems[3];
                    if (cm === "edid") return menuItems[4];
                    if (cm === "hdr") return menuItems[5];
                    if (cm === "hdredid") return menuItems[6];
                    return menuItems[0];
                }
            }

            // HDR Controls Section
            ColumnLayout {
                Layout.fillWidth: true
                visible: {
                    var cm = (root.mon.cm || root.mon.colorManagement || "").toLowerCase();
                    return cm === "hdr" || cm === "hdredid";
                }
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: qsTr("HDR Luminance & Tone Mapping")
                }

                SliderRow {
                    label: qsTr("SDR Brightness Multiplier")
                    subtext: qsTr("SDR brightness boost when operating in HDR mode")
                    value: root.mon.sdrbrightness ?? root.mon.sdrBrightness ?? 1.0
                    valueLabel: Math.round(value * 100) + "%"
                    from: 0.1
                    to: 2.0
                    stepSize: 0.05
                    onInteraction: v => root.updateMon("sdrbrightness", v)
                }

                SliderRow {
                    label: qsTr("SDR Saturation Multiplier")
                    subtext: qsTr("SDR color saturation adjust in HDR mode")
                    value: root.mon.sdrsaturation ?? root.mon.sdrSaturation ?? 1.0
                    valueLabel: Math.round(value * 100) + "%"
                    from: 0.1
                    to: 2.0
                    stepSize: 0.05
                    onInteraction: v => root.updateMon("sdrsaturation", v)
                }

                StepperRow {
                    label: qsTr("Min Luminance (HDR)")
                    subtext: qsTr("Black level floor in cd/m² (EDID: %1 cd/m²)").arg((root.mon.edidMinLuminance || 0).toFixed(2))
                    value: root.mon.min_luminance ?? root.mon.minLuminance ?? root.mon.edidMinLuminance ?? 0
                    from: 0
                    to: 100
                    stepSize: 0.05
                    suffix: " cd/m²"
                    onMoved: v => {
                        if (root.minLumLocked) {
                            root.updateMonMultiple({ min_luminance: v, sdr_min_luminance: v });
                        } else {
                            root.updateMon("min_luminance", v);
                        }
                    }
                }

                StepperRow {
                    label: qsTr("Max Luminance (HDR)")
                    subtext: qsTr("Peak white level in cd/m² (EDID: %1 cd/m²)").arg(Math.round(root.mon.edidMaxLuminance || 800))
                    value: root.mon.max_luminance ?? root.mon.maxLuminance ?? root.mon.edidMaxLuminance ?? 800
                    from: 50
                    to: 4000
                    stepSize: 10
                    suffix: " cd/m²"
                    onMoved: v => {
                        if (root.maxLumLocked) {
                            root.updateMonMultiple({ max_luminance: v, sdr_max_luminance: v });
                        } else {
                            root.updateMon("max_luminance", v);
                        }
                    }
                }

                StepperRow {
                    label: qsTr("Max Average Luminance")
                    subtext: qsTr("Full frame white level in cd/m² (EDID: %1 cd/m²)").arg(Math.round(root.mon.edidMaxAvgLuminance || 400))
                    value: root.mon.max_avg_luminance ?? root.mon.maxAvgLuminance ?? root.mon.edidMaxAvgLuminance ?? 400
                    from: 50
                    to: 4000
                    stepSize: 10
                    suffix: " cd/m²"
                    onMoved: v => root.updateMon("max_avg_luminance", v)
                }

                ButtonRow {
                    last: true
                    text: qsTr("Reset HDR to Safe Defaults")
                    subtext: qsTr("Restore recommended mastering luminance and brightness")
                    icon: "restart_alt"
                    actionLabel: ""
                    onClicked: {
                        root.updateMonMultiple({
                            sdrbrightness: 1.0,
                            sdrsaturation: 1.0,
                            min_luminance: root.mon.edidMinLuminance || 0,
                            max_luminance: root.mon.edidMaxLuminance || 800,
                            sdr_min_luminance: root.mon.edidMinLuminance || 0,
                            sdr_max_luminance: root.mon.edidMaxLuminance || 800,
                            max_avg_luminance: root.mon.edidMaxAvgLuminance || 400
                        });
                    }
                }
            }
        }
    }
}
