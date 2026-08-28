import QtQuick
import M3Shapes
import qs.components
import qs.services

MaterialShape {
    id: root

    property list<int> shapes: {
        if (containsIcon)
            return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
        return [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval];
    }
    property int shapeIndex
    property real cRotation
    property real lRotation
    property real thisLRotation
    property bool containsIcon

    property bool animated: true
    property alias rotateAnimDuration: rotateAnim.duration

    implicitSize: 38
    color: Colours.palette.m3primary
    toShape: shapes[0]
    rotation: cRotation + lRotation + thisLRotation

    NumberAnimation {
        id: morphAnim
        target: root
        property: "morphProgress"
        from: 0.0
        to: 1.0
        duration: 500
        easing.type: Easing.OutBack
        easing.overshoot: 1.3
    }

    Timer {
        interval: 650
        repeat: true
        triggeredOnStart: true
        running: root.animated
        onTriggered: {
            root.fromShape = root.toShape;
            root.shapeIndex = (root.shapeIndex + 1) % root.shapes.length;
            root.toShape = root.shapes[root.shapeIndex];
            root.morphProgress = 0.0;
            morphAnim.restart();

            root.lRotation = (root.lRotation + 45) % 360;
        }
    }

    RotationAnimation on cRotation {
        id: rotateAnim

        running: root.animated
        from: 0
        to: 360
        easing.type: Easing.Linear
        loops: Animation.Infinite
        duration: 4666
    }

    Behavior on color {
        CAnim {}
    }
}
