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

DialogRowButton {
    id: root

    property string varKey: ""

    readonly property string aliasKey: {
        if (root.varKey === "shadowColor") return "shadowColour";
        if (root.varKey === "shadowColour") return "shadowColor";
        if (root.varKey === "inactiveShadowColor") return "inactiveShadowColour";
        if (root.varKey === "inactiveShadowColour") return "inactiveShadowColor";
        if (root.varKey === "activeWindowBorderColor") return "activeWindowBorderColour";
        if (root.varKey === "activeWindowBorderColour") return "activeWindowBorderColor";
        if (root.varKey === "inactiveWindowBorderColor") return "inactiveWindowBorderColour";
        if (root.varKey === "inactiveWindowBorderColour") return "inactiveWindowBorderColor";
        return "";
    }

    readonly property var parsedValue: {
        var raw = CaelestiaVars.pendingVars[root.varKey]
            ?? (root.aliasKey !== "" ? CaelestiaVars.pendingVars[root.aliasKey] : undefined)
            ?? CaelestiaVars.currentVars[root.varKey]
            ?? (root.aliasKey !== "" ? CaelestiaVars.currentVars[root.aliasKey] : undefined)
            ?? CaelestiaVars.getDefault(root.varKey, root.aliasKey !== "" ? CaelestiaVars.getDefault(root.aliasKey, "") : "");
        if (!raw || raw === "") {
            if (root.varKey.toLowerCase().indexOf("shadow") !== -1) {
                raw = "rgba(\" .. scheme.shadow .. \"60)";
            } else {
                raw = "rgba(\" .. scheme.primary .. \"e6)";
            }
        }
        return CaelestiaVars.parseColor(String(raw));
    }

    readonly property color swatchColor: {
        var p = root.parsedValue;
        var a = Math.max(0, Math.min(1, (p.alphaPercent !== undefined ? p.alphaPercent : 100) / 100.0));
        var hex = "";
        if (p.isScheme) {
            hex = CaelestiaVars.getSchemeHex(p.token || "primary");
        } else {
            hex = p.hex || "ffffff";
        }
        if (!hex || hex.length < 6) hex = "ffffff";
        var r = parseInt(hex.substring(0, 2), 16) / 255.0;
        var g = parseInt(hex.substring(2, 4), 16) / 255.0;
        var b = parseInt(hex.substring(4, 6), 16) / 255.0;
        return Qt.rgba(r, g, b, a);
    }

    property bool isSchemeToken: true
    property string selectedToken: (root.varKey.toLowerCase().indexOf("shadow") !== -1) ? "shadow" : "primary"
    property string customHex: ""
    property int alphaPercent: 38

    Binding on isSchemeToken {
        when: !root.open
        value: root.parsedValue.isScheme
    }
    Binding on selectedToken {
        when: !root.open
        value: root.parsedValue.token || ((root.varKey.toLowerCase().indexOf("shadow") !== -1) ? "shadow" : "primary")
    }
    Binding on customHex {
        when: !root.open
        value: root.parsedValue.isScheme ? "" : (root.parsedValue.hex || "")
    }
    Binding on alphaPercent {
        when: !root.open
        value: root.parsedValue.alphaPercent !== undefined ? root.parsedValue.alphaPercent : 100
    }

    readonly property color currentPreviewColor: {
        var a = Math.max(0, Math.min(1, root.alphaPercent / 100.0));
        var hex = "";
        if (root.isSchemeToken) {
            hex = CaelestiaVars.getSchemeHex(root.selectedToken);
        } else {
            hex = (root.customHex && root.customHex.length >= 6) ? root.customHex : CaelestiaVars.getSchemeHex(root.selectedToken || "shadow");
        }
        if (!hex || hex.length < 6) hex = "000000";
        var r = parseInt(hex.substring(0, 2), 16) / 255.0;
        var g = parseInt(hex.substring(2, 4), 16) / 255.0;
        var b = parseInt(hex.substring(4, 6), 16) / 255.0;
        return Qt.rgba(r, g, b, a);
    }

    icon: "palette"
    header: qsTr("Configure Color")
    acceptLabel: qsTr("Save Color")
    subtext: {
        if (root.parsedValue.isScheme) {
            return qsTr("Scheme: %1 (%2% opacity)").arg(root.parsedValue.token).arg(root.parsedValue.alphaPercent);
        }
        return qsTr("Hex: #%1 (%2% opacity)").arg(root.parsedValue.hex).arg(root.parsedValue.alphaPercent);
    }

    onOpenChanged: {
        if (open) {
            var p = root.parsedValue;
            root.isSchemeToken = p.isScheme;
            root.selectedToken = p.token || ((root.varKey.toLowerCase().indexOf("shadow") !== -1) ? "shadow" : "primary");
            root.customHex = p.isScheme ? "" : (p.hex || "");
            root.alphaPercent = p.alphaPercent;
        }
    }

    onAccepted: {
        if (!root.isSchemeToken && root.customHex.trim() === "") {
            CaelestiaVars.resetToDefault(root.varKey);
            if (root.aliasKey !== "") CaelestiaVars.resetToDefault(root.aliasKey);
        } else {
            var target = root.isSchemeToken ? root.selectedToken : root.customHex.trim();
            var formatted = CaelestiaVars.formatColor(root.isSchemeToken, target, root.alphaPercent);
            CaelestiaVars.set(root.varKey, formatted);
            if (root.aliasKey !== "") CaelestiaVars.set(root.aliasKey, formatted);
        }
    }

    trailingActions: Component {
        // Swatch badge on the row button
        StyledRect {
            implicitWidth: 24
            implicitHeight: 24
            radius: Tokens.rounding.full
            border.width: 1.5
            border.color: Colours.palette.m3outline
            color: root.open ? root.currentPreviewColor : root.swatchColor
        }
    }

    content: Component {
        ColumnLayout {
            id: contentCol
            spacing: Tokens.spacing.extraSmall / 2
            Layout.fillWidth: true

            // Row 1: Preview Connected Card Row
            ConnectedRect {
                first: true
                last: false
                Layout.fillWidth: true
                implicitHeight: Math.max(54, previewRowLayout.implicitHeight + Tokens.padding.medium * 2)

                RowLayout {
                    id: previewRowLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Tokens.rounding.full
                        border.width: 1.5
                        border.color: Colours.palette.m3outline
                        color: root.currentPreviewColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: root.isSchemeToken
                                ? qsTr("M3 Token: %1").arg(root.selectedToken)
                                : (root.customHex.trim() !== "" ? qsTr("Custom Hex: #%1").arg(root.customHex) : qsTr("Custom Hex: (Default)"))
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: qsTr("%1% Opacity • %2").arg(root.alphaPercent).arg(
                                (root.isSchemeToken || root.customHex.trim() !== "")
                                    ? CaelestiaVars.formatColor(root.isSchemeToken, root.isSchemeToken ? root.selectedToken : root.customHex, root.alphaPercent)
                                    : qsTr("Default")
                            )
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Row 2: Mode Selector: M3 Theme Token vs Custom Hex
            OptionRow {
                first: false
                last: false
                title: qsTr("Color Source")
                options: [
                    { label: qsTr("Material 3 Theme Token"), value: "scheme" },
                    { label: qsTr("Custom Hex Color"), value: "custom" }
                ]
                currentValue: root.isSchemeToken ? qsTr("Material 3 Theme Token") : qsTr("Custom Hex Color")
                onOptionSelected: (val, lbl) => {
                    root.isSchemeToken = (val === "scheme");
                    if (!root.isSchemeToken && root.parsedValue.isScheme) {
                        root.customHex = "";
                    }
                }
            }

            // Row 3: Scheme token SplitButton picker (if M3 selected)
            SelectRow {
                visible: root.isSchemeToken
                first: false
                last: false
                label: qsTr("M3 Color Token")
                subtext: qsTr("Dynamic token synced from current scheme")
                menuItems: {
                    var colors = CaelestiaVars.schemeColors || [];
                    var items = [];
                    for (var i = 0; i < colors.length; i++) {
                        (function(c) {
                            var hex = c.hex || "ffffff";
                            var r = parseInt(hex.substring(0, 2), 16) / 255.0;
                            var g = parseInt(hex.substring(2, 4), 16) / 255.0;
                            var b = parseInt(hex.substring(4, 6), 16) / 255.0;
                            var item = Qt.createQmlObject('import qs.components.controls; MenuItem { text: "' + c.name + '"; onClicked: root.selectedToken = "' + c.name + '" }', contentCol);
                            item.previewColor = Qt.rgba(r, g, b, 1.0);
                            items.push(item);
                        })(colors[i]);
                    }
                    return items;
                }
                active: {
                    for (var i = 0; i < menuItems.length; i++) {
                        if (menuItems[i].text === root.selectedToken) return menuItems[i];
                    }
                    return menuItems[0] || null;
                }
            }

            // Row 3 (alt): Custom hex input field (if Custom selected)
            TextFieldRow {
                visible: !root.isSchemeToken
                first: false
                last: false
                label: qsTr("Hex Color Code")
                subtext: qsTr("Empty field resets to default")
                placeholderText: qsTr("e.g. FF5500 (empty for default)")
                value: root.customHex
                onValueEdited: val => {
                    var clean = val.trim();
                    if (clean.startsWith("#")) clean = clean.substring(1);
                    root.customHex = clean;
                }
            }

            // Row 4: Opacity slider (0 - 100%)
            SliderRow {
                first: false
                last: true
                label: qsTr("Opacity")
                subtext: qsTr("Alpha transparency level")
                value: root.alphaPercent
                valueLabel: root.alphaPercent + "%"
                from: 0
                to: 100
                stepSize: 1
                onInteraction: v => root.alphaPercent = Math.round(v)
                onMoved: v => root.alphaPercent = Math.round(v)
            }
        }
    }
}
