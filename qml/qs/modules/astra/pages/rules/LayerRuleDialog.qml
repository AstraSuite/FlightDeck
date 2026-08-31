import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0
import FlightDeck.Managers 1.0

Popup {
    id: root

    property int editingIndex: -1
    property string targetNamespace: ""
    property bool isBlur: true
    property bool isDimAround: false
    property bool isIgnoreAlpha: false
    property real ignoreAlphaValue: 0.5
    property string targetAnimation: ""

    property bool showNamespacePicker: false

    width: Math.min(520, parent.width - 40)
    height: Math.min(540, parent.height - 40)
    anchors.centerIn: parent

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: StyledRect {
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: root.editingIndex >= 0 ? qsTr("Edit Layer Rule") : qsTr("Add Layer Rule")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                onClicked: root.close()
            }
        }

        // Namespace input with picker
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: nsCol.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: nsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Target Layer Namespace:")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    Item { Layout.fillWidth: true }

                    TextButton {
                        implicitHeight: 32
                        text: qsTr("Active Layers")
                        onClicked: root.showNamespacePicker = true
                    }
                }

                StyledTextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("e.g. rofi, waybar, notifications")
                    text: root.targetNamespace
                    onTextEdited: root.targetNamespace = text
                }
            }
        }

        // Action Toggles (Switches)
        StyledText {
            text: qsTr("Layer Effects")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                first: true
                text: qsTr("Enable Blur")
                subtext: qsTr("Apply background blur beneath this layer surface")
                checked: root.isBlur
                onCheckedChanged: root.isBlur = checked
            }

            ToggleRow {
                text: qsTr("Dim Around")
                subtext: qsTr("Dim background elements when this layer is open")
                checked: root.isDimAround
                onCheckedChanged: root.isDimAround = checked
            }

            ToggleRow {
                last: true
                text: qsTr("Ignore Alpha Channel")
                subtext: qsTr("Skip blur on transparent pixels")
                checked: root.isIgnoreAlpha
                onCheckedChanged: root.isIgnoreAlpha = checked
            }
        }

        // Custom Animation Style
        StyledTextField {
            Layout.fillWidth: true
            placeholderText: qsTr("Animation Style (e.g. popin 80%, slide, fade)")
            text: root.targetAnimation
            onTextEdited: root.targetAnimation = text
        }

        Item { Layout.fillHeight: true }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: root.editingIndex >= 0 ? qsTr("Update Rule") : qsTr("Save Layer Rule")
                onClicked: {
                    if (root.targetNamespace.trim() === "") return;

                    var ruleMap = {
                        "match": {
                            "namespace": root.targetNamespace.trim()
                        },
                        "blur": root.isBlur,
                        "dimaround": root.isDimAround
                    };
                    if (root.isIgnoreAlpha) {
                        ruleMap["ignore_alpha"] = root.ignoreAlphaValue;
                    }
                    if (root.targetAnimation.trim() !== "") {
                        ruleMap["animation"] = root.targetAnimation.trim();
                    }

                    if (root.editingIndex >= 0) {
                        FlightDeckWriter.removeLayerRule(root.editingIndex);
                    }
                    FlightDeckWriter.addLayerRule(ruleMap);
                    FlightDeckWriter.save();
                    root.close();
                }
            }
        }
    }

    // Open Layer Client Picker Modal
    Popup {
        id: layerPicker
        visible: root.showNamespacePicker
        onClosed: root.showNamespacePicker = false
        width: 340
        height: 320
        anchors.centerIn: parent
        modal: true
        focus: true

        background: StyledRect {
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            border.width: 1
            border.color: Colours.palette.m3outlineVariant
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Select Active Layer Surface")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: FlightDeckWriter.activeHyprlandLayers()

                delegate: Item {
                    id: nsRow
                    required property string modelData
                    required property int index

                    width: ListView.view ? ListView.view.width : 320
                    implicitHeight: 44

                    StateLayer {
                        radius: Tokens.rounding.small

                        onClicked: {
                            root.targetNamespace = nsRow.modelData;
                            nsPicker.close();
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "layers"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: nsRow.modelData
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
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
