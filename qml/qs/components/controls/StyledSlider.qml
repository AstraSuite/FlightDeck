pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Helm.Config
import qs.components
import qs.services

T.Slider {
    id: root

    property int radius: Tokens.rounding.medium
    property bool circleHandle: false
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition
    property real filledWidth: (width - handle.implicitWidth - handle.anchors.leftMargin) * pos

    signal interaction(v: real)
    signal released(v: real)

    implicitWidth: 200
    implicitHeight: 12

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining
            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: parent.height * (parent.height <= 12 ? opacity : Math.min(opacity * 2, 1))
            opacity: Math.min(width, 12) / 12

            radius: root.radius
            topLeftRadius: Tokens.rounding.extraSmall / 2
            bottomLeftRadius: Tokens.rounding.extraSmall / 2
            color: root.bgColour
        }

        StyledRect {
            id: handle
            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitWidth: root.circleHandle ? parent.height * 2.0 : 4
            implicitHeight: root.circleHandle ? parent.height * 2.0 : parent.height * (mouse.pressed ? 2.5 : 2.0)

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }
        }

        StyledRect {
            id: filled
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(0, root.filledWidth)
            implicitHeight: root.height

            radius: root.radius
            topRightRadius: Tokens.rounding.extraSmall / 2
            bottomRightRadius: Tokens.rounding.extraSmall / 2
            color: root.fgColour
        }
    }

    Binding {
        id: posBinding
        target: root
        property: "pos"
        value: Math.max(0, Math.min(1, mouse.pressStartPos + mouse.dragMovement))
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement: 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 24

        preventStealing: true

        onPressed: e => {
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : Math.max(0, Math.min(1, clickPos));
            root.interaction(finalPos);
            root.released(finalPos);
            dragMovement = 0;
        }
    }
}
