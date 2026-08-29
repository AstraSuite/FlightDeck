import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import FlightDeck.Caelestia 1.0

ConnectedRect {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property alias icon: iconLabel.text
    property alias text: labelTextItem.text
    property alias label: labelTextItem.text
    property alias subtext: subLabel.text
    property string trailingIcon
    property Component trailingActions: null
    property alias disabled: stateLayer.disabled

    readonly property alias iconLabel: iconLabel
    readonly property alias labelItem: labelTextItem
    readonly property alias subLabel: subLabel

    signal clicked(event: MouseEvent)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    StateLayer {
        id: stateLayer

        onClicked: e => root.clicked(e)
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.largeIncreased

        spacing: Tokens.spacing.medium
        opacity: root.disabled ? 0.5 : 1

        Behavior on opacity {
            Anim {}
        }

        MaterialIcon {
            id: iconLabel

            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        ColumnLayout {
            id: column

            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: labelTextItem

                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                IconButton {
                    id: resetBtn
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showReset || (root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars))
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                        }
                        root.reset();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                id: subLabel

                Layout.fillWidth: true
                visible: text !== ""
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        Loader {
            asynchronous: true
            active: !!root.trailingIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }

        Loader {
            id: trailingActionsLoader
            active: !!root.trailingActions
            visible: active
            sourceComponent: root.trailingActions
        }
    }
}
