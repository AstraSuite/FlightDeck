pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

ConnectedRect {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property alias label: label.text
    property alias text: label.text
    property string subtext
    property string value
    property alias placeholderText: input.placeholderText
    property string errorText
    property alias maximumLength: input.maximumLength
    property alias validate: input.validate
    property alias validator: input.validator
    property bool smallField
    readonly property alias field: input

    signal valueEdited(value: string)
    signal editingFinished(value: string)

    function clear(): void {
        input.clear();
    }

    Component.onDestruction: {
        if (value !== input.text)
            editingFinished(input.text);
    }

    Binding on value {
        when: root.varKey !== ""
        value: CaelestiaVars.pendingVars[root.varKey] ?? CaelestiaVars.currentVars[root.varKey] ?? CaelestiaVars.getDefault(root.varKey, "")
        restoreMode: Binding.RestoreBinding
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: rowLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: label
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showReset || (root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars))
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                            root.value = CaelestiaVars.getDefault(root.varKey, "");
                        }
                        root.reset();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext !== ""
                text: input.isError && root.errorText ? root.errorText : root.subtext
                color: input.isError && root.errorText ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledTextField {
            id: input

            Layout.preferredWidth: root.smallField ? 140 : 200
            Layout.maximumWidth: root.width / 2
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: Tokens.padding.small

            text: root.value

            onTextEdited: {
                if (root.varKey !== "") {
                    CaelestiaVars.setVar(root.varKey, text);
                }
                root.valueEdited(text);
            }
            onEditingFinished: {
                if (root.varKey !== "") {
                    CaelestiaVars.setVar(root.varKey, text);
                }
                root.editingFinished(text);
            }
        }
    }
}
