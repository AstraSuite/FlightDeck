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
    property string matchKey: "class"
    property string matchValue: ""
    property bool isFloat: true
    property bool isPin: false
    property bool isOpaque: false
    property bool isCenter: false
    property string targetWorkspace: ""
    property string targetOpacity: ""

    property bool showClientPicker: false

    width: Math.min(540, parent.width - 40)
    height: Math.min(600, parent.height - 40)
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
                text: root.editingIndex >= 0 ? qsTr("Edit Window Rule") : qsTr("Add Window Rule")
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

        // Window Matcher
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: matchCol.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerLow

            ColumnLayout {
                id: matchCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Match Criteria:")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    Item { Layout.fillWidth: true }

                    TextButton {
                        implicitHeight: 32
                        text: qsTr("Pick Window")
                        onClicked: root.showClientPicker = true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledRect {
                        implicitWidth: 100
                        implicitHeight: 44
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3surfaceContainerHigh

                        StyledText {
                            anchors.centerIn: parent
                            text: root.matchKey
                            font: Tokens.font.body.small
                            color: Colours.palette.m3primary
                        }
                    }

                    StyledTextField {
                        id: matchInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g. ^(kitty)$ or class regex")
                        text: root.matchValue
                        onTextEdited: root.matchValue = text
                    }
                }
            }
        }

        // Actions & Effects
        StyledText {
            text: qsTr("Rule Actions & Effects")
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
                checked: root.isFloat
                onCheckedChanged: root.isFloat = checked
            }

            ToggleRow {
                text: qsTr("Pin Window")
                subtext: qsTr("Stay visible across all workspaces")
                checked: root.isPin
                onCheckedChanged: root.isPin = checked
            }

            ToggleRow {
                text: qsTr("Center on Screen")
                subtext: qsTr("Center floating window upon creation")
                checked: root.isCenter
                onCheckedChanged: root.isCenter = checked
            }

            ToggleRow {
                last: true
                text: qsTr("Force Opaque")
                subtext: qsTr("Disable transparency for this application")
                checked: root.isOpaque
                onCheckedChanged: root.isOpaque = checked
            }
        }

        // Workspace Assignment
        StyledTextField {
            Layout.fillWidth: true
            placeholderText: qsTr("Assign Workspace (e.g. 1, 2, special:magic)")
            text: root.targetWorkspace
            onTextEdited: root.targetWorkspace = text
        }

        Item { Layout.fillHeight: true }

        // Action Buttons
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
                text: root.editingIndex >= 0 ? qsTr("Update Rule") : qsTr("Save Rule")
                onClicked: {
                    if (root.matchValue.trim() === "") return;

                    var ruleMap = {
                        "match": {
                            [root.matchKey]: root.matchValue
                        },
                        "float": root.isFloat,
                        "pin": root.isPin,
                        "center": root.isCenter,
                        "opaque": root.isOpaque
                    };
                    if (root.targetWorkspace.trim() !== "") {
                        ruleMap["workspace"] = root.targetWorkspace.trim();
                    }

                    if (root.editingIndex >= 0) {
                        FlightDeckWriter.updateWindowRule(root.editingIndex, ruleMap);
                    } else {
                        FlightDeckWriter.addWindowRule(ruleMap);
                    }
                    FlightDeckWriter.save();
                    root.close();
                }
            }
        }
    }

    // Open Window Client Picker Modal
    Popup {
        id: clientPicker
        visible: root.showClientPicker
        onClosed: root.showClientPicker = false
        width: 380
        height: 360
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
                text: qsTr("Select Running Window")
                font: Tokens.font.title.small
                color: Colours.palette.m3onSurface
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: FlightDeckWriter.activeHyprlandClients()

                delegate: Item {
                    id: clientRow
                    required property var modelData
                    required property int index

                    width: ListView.view ? ListView.view.width : 320
                    implicitHeight: 48

                    StateLayer {
                        radius: Tokens.rounding.small

                        onClicked: {
                            root.matchKey = "class";
                            root.matchValue = "^(" + (clientRow.modelData.class || "") + ")$";
                            clientPicker.close();
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

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: clientRow.modelData.class || qsTr("Unknown")
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: clientRow.modelData.title || ""
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
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
}
