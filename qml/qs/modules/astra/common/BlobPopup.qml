import QtQuick
import QtQuick.Controls
import Helm.Config
import qs.components
import qs.services

Item {
    id: root

    property alias icon: icon.text
    property color color: Colours.palette.m3surfaceContainerHighest
    readonly property alias hovered: btn.containsMouse
    property bool open: popup.visible
    property bool pressOverride: false
    property bool hoverOverride: false
    default property Item content

    implicitWidth: 36
    implicitHeight: 36

    // Button Background
    StyledRect {
        id: btnBg
        anchors.fill: parent
        radius: root.open ? root.Tokens.rounding.large : root.Tokens.rounding.medium
        color: root.open || btn.containsMouse || root.hoverOverride ? Colours.palette.m3secondaryContainer : root.color

        Behavior on color {
            CAnim {}
        }
        Behavior on radius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    MouseArea {
        id: btn
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            if (popup.visible) popup.close();
            else popup.open();
        }

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            text: "view_apps"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }
    }

    Popup {
        id: popup
        parent: root
        x: -width + root.width
        y: root.height + 6
        width: 360
        height: 280

        padding: root.Tokens.padding.small
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutQuad }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InQuad }
        }

        background: StyledRect {
            radius: root.Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            border.width: 1
            border.color: Colours.palette.m3outlineVariant
        }

        contentItem: Item {
            id: containerItem
            anchors.fill: parent

            Component.onCompleted: {
                if (root.content) {
                    root.content.parent = containerItem;
                    root.content.anchors.fill = containerItem;
                }
            }
        }
    }
}
