import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Layer rules")

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Layer Rule Management")
        }

        // Add Layer Rule via DialogRowButton (always rounded with first: true, last: true)
        DialogRowButton {
            id: addLayerBtn
            rootParent: root.modalOverlay
            first: true
            last: true
            icon: "add_circle"
            label: qsTr("Add Layer Rule")
            header: qsTr("Add New Layer Rule")
            acceptLabel: qsTr("Save Rule")
            separateContent: true
            horizontalContentMargin: -Tokens.padding.small
            openWidth: Math.min((rootParent ? rootParent.width : 560) * 0.95, 540)
            customOpenHeight: Math.min((rootParent ? rootParent.height : 700) * 0.95, 620)

            property string targetNamespace: ""
            property bool isBlur: true
            property bool isDimAround: false
            property bool isIgnoreAlpha: false
            property bool isBlurPopups: false
            property bool isNoAnim: false
            property bool isXRay: false
            property string animType: "None"
            property int popinPercent: 80

            acceptAllowed: targetNamespace.trim() !== ""

            function resetFields() {
                targetNamespace = "";
                isBlur = true;
                isDimAround = false;
                isIgnoreAlpha = false;
                isBlurPopups = false;
                isNoAnim = false;
                isXRay = false;
                animType = "None";
                popinPercent = 80;
            }

            onAccepted: {
                if (targetNamespace.trim() !== "") {
                    var ruleMap = {
                        "namespace": targetNamespace.trim(),
                        "blur": isBlur,
                        "dimaround": isDimAround,
                        "ignorealpha": isIgnoreAlpha
                    };
                    if (isBlurPopups) ruleMap["blurpopups"] = true;
                    if (isNoAnim) ruleMap["noanim"] = true;
                    if (isXRay) ruleMap["xray"] = true;

                    if (animType !== "None" && animType.trim() !== "") {
                        if (animType === "popin") {
                            ruleMap["animation"] = "popin " + popinPercent + "%";
                        } else {
                            ruleMap["animation"] = animType;
                        }
                    }
                    FlightDeckWriter.addLayerRule(ruleMap);
                    FlightDeckWriter.save();
                    resetFields();
                }
            }

            content: Component {
                VerticalFadeFlickable {
                    id: addLayerFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: addLayerCol.implicitHeight
                    topMargin: Tokens.padding.medium
                    bottomMargin: Tokens.padding.medium
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: addLayerCol
                        width: addLayerFlick.width
                        spacing: Tokens.spacing.medium

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
                                subtext: qsTr("Apply background blur behind layer surface")
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
                                text: qsTr("Ignore Alpha")
                                subtext: qsTr("Treat transparent layer pixels as blurred")
                                checked: addLayerBtn.isIgnoreAlpha
                                onToggled: addLayerBtn.isIgnoreAlpha = checked
                            }

                            ToggleRow {
                                text: qsTr("Blur Popups")
                                subtext: qsTr("Apply blur to popups spawned above this surface")
                                checked: addLayerBtn.isBlurPopups
                                onToggled: addLayerBtn.isBlurPopups = checked
                            }

                            ToggleRow {
                                text: qsTr("No Animations")
                                subtext: qsTr("Disable open and close animations for this layer")
                                checked: addLayerBtn.isNoAnim
                                onToggled: addLayerBtn.isNoAnim = checked
                            }

                            ToggleRow {
                                last: true
                                text: qsTr("X-Ray Blur")
                                subtext: qsTr("Enable see-through background blur")
                                checked: addLayerBtn.isXRay
                                onToggled: addLayerBtn.isXRay = checked
                            }
                        }

                        StyledText {
                            text: qsTr("Animation Style")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            SelectRow {
                                first: true
                                last: addLayerBtn.animType !== "popin"
                                menuOnTop: true
                                label: qsTr("Animation Type")
                                subtext: qsTr("Layer entrance and exit motion effect")
                                menuItems: [
                                    MenuItem { text: qsTr("None"); icon: "block"; onClicked: addLayerBtn.animType = "None" },
                                    MenuItem { text: qsTr("popin"); icon: "open_in_full"; onClicked: addLayerBtn.animType = "popin" },
                                    MenuItem { text: qsTr("fade"); icon: "gradient"; onClicked: addLayerBtn.animType = "fade" },
                                    MenuItem { text: qsTr("slide"); icon: "slideshow"; onClicked: addLayerBtn.animType = "slide" },
                                    MenuItem { text: qsTr("slide top"); icon: "arrow_upward"; onClicked: addLayerBtn.animType = "slide top" },
                                    MenuItem { text: qsTr("slide bottom"); icon: "arrow_downward"; onClicked: addLayerBtn.animType = "slide bottom" },
                                    MenuItem { text: qsTr("slide left"); icon: "arrow_back"; onClicked: addLayerBtn.animType = "slide left" },
                                    MenuItem { text: qsTr("slide right"); icon: "arrow_forward"; onClicked: addLayerBtn.animType = "slide right" }
                                ]
                                active: {
                                    for (var i = 0; i < menuItems.length; i++) {
                                        if (menuItems[i].text === addLayerBtn.animType) return menuItems[i];
                                    }
                                    return menuItems[0];
                                }
                            }

                            SliderRow {
                                visible: addLayerBtn.animType === "popin"
                                first: false
                                last: true
                                label: qsTr("Popin Percentage")
                                subtext: qsTr("Initial starting scale ratio for popin animation")
                                value: addLayerBtn.popinPercent
                                valueLabel: addLayerBtn.popinPercent + "%"
                                from: 0
                                to: 100
                                stepSize: 5
                                onMoved: v => addLayerBtn.popinPercent = Math.round(v)
                                onInteraction: v => addLayerBtn.popinPercent = Math.round(v)
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configured Layer Rules (%1)").arg(FlightDeckWriter.layerRules.length)
        }

        // Each Configured Layer Rule is its own DialogRowButton
        Repeater {
            model: FlightDeckWriter.layerRules

            delegate: DialogRowButton {
                id: editLayerRow
                required property var modelData
                required property int index

                readonly property bool isReadOnly: editLayerRow.modelData ? (editLayerRow.modelData.isReadOnly || false) : false

                rootParent: root.modalOverlay
                first: index === 0
                last: index === FlightDeckWriter.layerRules.length - 1
                icon: editLayerRow.isReadOnly ? "tune" : "layers"

                label: editLayerRow.modelData.namespace ? ("Namespace: " + editLayerRow.modelData.namespace) : ("Layer Rule " + (editLayerRow.index + 1))

                subtext: {
                    var props = [];
                    if (editLayerRow.modelData.blur) props.push("blur");
                    if (editLayerRow.modelData.dimaround || editLayerRow.modelData.dim_around) props.push("dimaround");
                    if (editLayerRow.modelData.ignorealpha || editLayerRow.modelData.ignore_alpha) props.push("ignorealpha");
                    if (editLayerRow.modelData.blurpopups || editLayerRow.modelData.blur_popups) props.push("blurpopups");
                    if (editLayerRow.modelData.noanim || editLayerRow.modelData.no_anim) props.push("noanim");
                    if (editLayerRow.modelData.xray) props.push("xray");
                    if (editLayerRow.modelData.animation) props.push("anim: " + editLayerRow.modelData.animation);
                    var txt = props.length > 0 ? props.join(" • ") : qsTr("Default layer behavior");
                    if (editLayerRow.isReadOnly) {
                        txt += " • " + qsTr("System default");
                    }
                    return txt;
                }

                header: editLayerRow.isReadOnly ? qsTr("Override Layer Rule") : qsTr("Edit Layer Rule")
                acceptLabel: editLayerRow.isReadOnly ? qsTr("Save Override") : qsTr("Save Changes")
                separateContent: true
                horizontalContentMargin: -Tokens.padding.small
                openWidth: Math.min((rootParent ? rootParent.width : 560) * 0.95, 540)
                customOpenHeight: Math.min((rootParent ? rootParent.height : 700) * 0.95, 620)

                property string targetNamespace: editLayerRow.modelData.namespace || ""
                property bool isBlur: !!editLayerRow.modelData.blur
                property bool isDimAround: !!(editLayerRow.modelData.dimaround || editLayerRow.modelData.dim_around)
                property bool isIgnoreAlpha: !!(editLayerRow.modelData.ignorealpha || editLayerRow.modelData.ignore_alpha)
                property bool isBlurPopups: !!(editLayerRow.modelData.blurpopups || editLayerRow.modelData.blur_popups)
                property bool isNoAnim: !!(editLayerRow.modelData.noanim || editLayerRow.modelData.no_anim)
                property bool isXRay: !!editLayerRow.modelData.xray

                property string animType: {
                    var a = editLayerRow.modelData.animation || "";
                    if (!a) return "None";
                    if (a.startsWith("popin")) return "popin";
                    return a;
                }
                property int popinPercent: {
                    var a = editLayerRow.modelData.animation || "";
                    if (a.startsWith("popin")) {
                        var m = a.match(/\d+/);
                        if (m) return parseInt(m[0]);
                    }
                    return 80;
                }

                acceptAllowed: targetNamespace.trim() !== ""

                onOpenChanged: {
                    if (open && editLayerRow.modelData) {
                        var m = editLayerRow.modelData;
                        targetNamespace = m.namespace || "";
                        isBlur = !!m.blur;
                        isDimAround = !!(m.dimaround || m.dim_around);
                        isIgnoreAlpha = !!(m.ignorealpha || m.ignore_alpha);
                        isBlurPopups = !!(m.blurpopups || m.blur_popups);
                        isNoAnim = !!(m.noanim || m.no_anim);
                        isXRay = !!m.xray;

                        var a = m.animation || "";
                        if (!a) {
                            animType = "None";
                            popinPercent = 80;
                        } else if (a.startsWith("popin")) {
                            animType = "popin";
                            var match = a.match(/\d+/);
                            popinPercent = match ? parseInt(match[0]) : 80;
                        } else {
                            animType = a;
                            popinPercent = 80;
                        }
                    }
                }

                onAccepted: {
                    if (targetNamespace.trim() !== "") {
                        var ruleMap = {
                            "namespace": targetNamespace.trim(),
                            "blur": isBlur,
                            "dimaround": isDimAround,
                            "ignorealpha": isIgnoreAlpha
                        };
                        if (isBlurPopups) ruleMap["blurpopups"] = true;
                        if (isNoAnim) ruleMap["noanim"] = true;
                        if (isXRay) ruleMap["xray"] = true;

                        if (animType !== "None" && animType.trim() !== "") {
                            if (animType === "popin") {
                                ruleMap["animation"] = "popin " + popinPercent + "%";
                            } else {
                                ruleMap["animation"] = animType;
                            }
                        }
                        FlightDeckWriter.updateLayerRule(editLayerRow.index, ruleMap);
                        FlightDeckWriter.save();
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            visible: !editLayerRow.isReadOnly
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                FlightDeckWriter.removeLayerRule(editLayerRow.index);
                                FlightDeckWriter.save();
                            }
                        }
                    }
                }

            content: Component {
                VerticalFadeFlickable {
                    id: editLayerFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: editLayerCol.implicitHeight
                    topMargin: Tokens.padding.medium
                    bottomMargin: Tokens.padding.medium
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: editLayerCol
                        width: editLayerFlick.width
                        spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Layer Surface Namespace")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("e.g. rofi, waybar, notifications, caelestia-.*")
                                text: editLayerRow.targetNamespace
                                onTextEdited: editLayerRow.targetNamespace = text
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
                                    subtext: qsTr("Apply background blur behind layer surface")
                                    checked: editLayerRow.isBlur
                                    onToggled: editLayerRow.isBlur = checked
                                }

                                ToggleRow {
                                    text: qsTr("Dim Around")
                                    subtext: qsTr("Darken remainder of the screen behind layer")
                                    checked: editLayerRow.isDimAround
                                    onToggled: editLayerRow.isDimAround = checked
                                }

                                ToggleRow {
                                    text: qsTr("Ignore Alpha")
                                    subtext: qsTr("Treat transparent layer pixels as blurred")
                                    checked: editLayerRow.isIgnoreAlpha
                                    onToggled: editLayerRow.isIgnoreAlpha = checked
                                }

                                ToggleRow {
                                    text: qsTr("Blur Popups")
                                    subtext: qsTr("Apply blur to popups spawned above this surface")
                                    checked: editLayerRow.isBlurPopups
                                    onToggled: editLayerRow.isBlurPopups = checked
                                }

                                ToggleRow {
                                    text: qsTr("No Animations")
                                    subtext: qsTr("Disable open and close animations for this layer")
                                    checked: editLayerRow.isNoAnim
                                    onToggled: editLayerRow.isNoAnim = checked
                                }

                                ToggleRow {
                                    last: true
                                    text: qsTr("X-Ray Blur")
                                    subtext: qsTr("Enable see-through background blur")
                                    checked: editLayerRow.isXRay
                                    onToggled: editLayerRow.isXRay = checked
                                }
                            }

                            StyledText {
                                text: qsTr("Animation Style")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                SelectRow {
                                    first: true
                                    last: editLayerRow.animType !== "popin"
                                    menuOnTop: true
                                    label: qsTr("Animation Type")
                                    subtext: qsTr("Layer entrance and exit motion effect")
                                    menuItems: [
                                        MenuItem { text: qsTr("None"); icon: "block"; onClicked: editLayerRow.animType = "None" },
                                        MenuItem { text: qsTr("popin"); icon: "open_in_full"; onClicked: editLayerRow.animType = "popin" },
                                        MenuItem { text: qsTr("fade"); icon: "gradient"; onClicked: editLayerRow.animType = "fade" },
                                        MenuItem { text: qsTr("slide"); icon: "slideshow"; onClicked: editLayerRow.animType = "slide" },
                                        MenuItem { text: qsTr("slide top"); icon: "arrow_upward"; onClicked: editLayerRow.animType = "slide top" },
                                        MenuItem { text: qsTr("slide bottom"); icon: "arrow_downward"; onClicked: editLayerRow.animType = "slide bottom" },
                                        MenuItem { text: qsTr("slide left"); icon: "arrow_back"; onClicked: editLayerRow.animType = "slide left" },
                                        MenuItem { text: qsTr("slide right"); icon: "arrow_forward"; onClicked: editLayerRow.animType = "slide right" }
                                    ]
                                    active: {
                                        for (var i = 0; i < menuItems.length; i++) {
                                            if (menuItems[i].text === editLayerRow.animType) return menuItems[i];
                                        }
                                        return menuItems[0];
                                    }
                                }

                                SliderRow {
                                    visible: editLayerRow.animType === "popin"
                                    first: false
                                    last: true
                                    label: qsTr("Popin Percentage")
                                    subtext: qsTr("Initial starting scale ratio for popin animation")
                                    value: editLayerRow.popinPercent
                                    valueLabel: editLayerRow.popinPercent + "%"
                                    from: 0
                                    to: 100
                                    stepSize: 5
                                    onMoved: v => editLayerRow.popinPercent = Math.round(v)
                                    onInteraction: v => editLayerRow.popinPercent = Math.round(v)
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: FlightDeckWriter.layerRules.length === 0
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
