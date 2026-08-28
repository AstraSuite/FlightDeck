import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Layer Rules")

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

            property string targetNamespace: ""
            property bool isBlur: true
            property bool isDimAround: false
            property bool isIgnoreAlpha: false
            property string animType: "None"
            property int popinPercent: 80

            acceptAllowed: targetNamespace.trim() !== ""

            onAccepted: {
                if (targetNamespace.trim() !== "") {
                    var ruleMap = {
                        "namespace": targetNamespace.trim(),
                        "blur": isBlur,
                        "dimaround": isDimAround,
                        "ignorealpha": isIgnoreAlpha
                    };
                    if (animType !== "None" && animType.trim() !== "") {
                        if (animType === "popin") {
                            ruleMap["animation"] = "popin " + popinPercent + "%";
                        } else {
                            ruleMap["animation"] = animType;
                        }
                    }
                    FlightDeckWriter.addLayerRule(ruleMap);
                    FlightDeckWriter.save();
                    targetNamespace = "";
                    animType = "None";
                    popinPercent = 80;
                }
            }

            content: Component {
                ColumnLayout {
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

                    StyledText {
                        text: qsTr("Animation Style")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    SelectRow {
                        first: true
                        last: addLayerBtn.animType !== "popin"
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

        SectionHeader {
            text: qsTr("Configured Layer Rules (%1)").arg(FlightDeckWriter.layerRules.length)
        }

        // Each Configured Layer Rule is its own DialogRowButton so editing morphs the entire button row!
        Repeater {
            model: FlightDeckWriter.layerRules

            delegate: DialogRowButton {
                id: editLayerRow
                required property var modelData
                required property int index

                rootParent: root.modalOverlay
                first: index === 0
                last: index === FlightDeckWriter.layerRules.length - 1
                icon: "layers"

                label: editLayerRow.modelData.namespace ? ("Namespace: " + editLayerRow.modelData.namespace) : ("Layer Rule " + (editLayerRow.index + 1))

                subtext: {
                    var props = [];
                    if (editLayerRow.modelData.blur) props.push("blur");
                    if (editLayerRow.modelData.dimaround) props.push("dimaround");
                    if (editLayerRow.modelData.ignorealpha) props.push("ignorealpha");
                    if (editLayerRow.modelData.animation) props.push("anim: " + editLayerRow.modelData.animation);
                    return props.length > 0 ? props.join(" • ") : qsTr("Default layer behavior");
                }

                header: qsTr("Edit Layer Rule")
                acceptLabel: qsTr("Save Changes")

                property string targetNamespace: editLayerRow.modelData.namespace || ""
                property bool isBlur: !!editLayerRow.modelData.blur
                property bool isDimAround: !!editLayerRow.modelData.dimaround
                property bool isIgnoreAlpha: !!editLayerRow.modelData.ignorealpha

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

                onAccepted: {
                    if (targetNamespace.trim() !== "") {
                        var ruleMap = {
                            "namespace": targetNamespace.trim(),
                            "blur": isBlur,
                            "dimaround": isDimAround,
                            "ignorealpha": isIgnoreAlpha
                        };
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
                            icon: "edit"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: editLayerRow.open = true
                        }

                        IconButton {
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
                    ColumnLayout {
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
                                subtext: qsTr("Apply Kawase background blur behind layer surface")
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
                                last: true
                                text: qsTr("Ignore Alpha")
                                subtext: qsTr("Treat transparent layer pixels as blurred")
                                checked: editLayerRow.isIgnoreAlpha
                                onToggled: editLayerRow.isIgnoreAlpha = checked
                            }
                        }

                        StyledText {
                            text: qsTr("Animation Style")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        SelectRow {
                            first: true
                            last: editLayerRow.animType !== "popin"
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
