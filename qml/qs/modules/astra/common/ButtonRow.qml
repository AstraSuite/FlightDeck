pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.controls
import qs.services

ConnectedRect {
    id: root

    property string text
    property alias title: root.text
    property string subtext
    property string icon
    property color iconColor: Colours.palette.m3primary
    property string actionLabel
    readonly property alias stateLayer: stateLayer

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(54, rowLayout.implicitHeight + Tokens.padding.medium * 2)

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        Loader {
            active: !!root.icon
            sourceComponent: MaterialIcon {
                text: root.icon
                color: root.iconColor
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.text
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: Tokens.spacing.small
            visible: root.actionLabel !== ""

            StyledText {
                text: root.actionLabel
                color: Colours.palette.m3primary
                font: Tokens.font.label.medium
            }

            MaterialIcon {
                text: "arrow_forward"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }
        }
    }
}
