import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property real x1: 0.25
    property real y1: 0.1
    property real x2: 0.25
    property real y2: 1.0

    implicitWidth: 320
    implicitHeight: 20

    property real progress: 0.0
    readonly property real easedVal: ease(progress)
    readonly property real gap: 4

    function sampleBezier(t, p0, p1, p2, p3) {
        var u = 1 - t;
        return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3;
    }

    function solveBezier(xTarget, p1x, p2x) {
        // Simple bisection for bezier x -> t
        var lo = 0.0, hi = 1.0, t = xTarget;
        for (var i = 0; i < 16; i++) {
            var currX = sampleBezier(t, 0.0, p1x, p2x, 1.0);
            if (Math.abs(currX - xTarget) < 0.001) break;
            if (currX < xTarget) lo = t;
            else hi = t;
            t = (lo + hi) * 0.5;
        }
        return t;
    }

    function ease(x) {
        var t = solveBezier(Math.max(0, Math.min(1, x)), root.x1, root.x2);
        return Math.max(0.0, Math.min(1.0, sampleBezier(t, 0.0, root.y1, root.y2, 1.0)));
    }

    function restart() {
        progress = 0.0;
        loopAnim.restart();
    }

    SequentialAnimation {
        id: loopAnim
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: root
            property: "progress"
            from: 0.0
            to: 1.0
            duration: 1200
            easing.type: Easing.Linear
        }

        PauseAnimation {
            duration: 600
        }

        ScriptAction {
            script: root.progress = 0.0
        }
    }

    Item {
        id: trackContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        height: 8

        StyledRect {
            id: activeIndicator
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            radius: height / 2
            color: Colours.palette.m3primary
            visible: width > 0
            width: {
                if (root.easedVal <= 0.0) return 0;
                if (root.easedVal >= 1.0) return trackContainer.width;
                return Math.max(0, Math.min(trackContainer.width, trackContainer.width * root.easedVal - root.gap / 2));
            }
        }

        StyledRect {
            id: inactiveTrack
            anchors.left: activeIndicator.visible && activeIndicator.width > 0 ? activeIndicator.right : parent.left
            anchors.leftMargin: activeIndicator.visible && activeIndicator.width > 0 ? root.gap : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            radius: height / 2
            color: Colours.palette.m3secondaryContainer
            visible: width >= height / 2

            StyledRect {
                id: stopDot
                anchors.right: parent.right
                anchors.rightMargin: (parent.height - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: 4
                radius: Tokens.rounding.full
                color: Colours.palette.m3primary
                visible: parent.width >= 12
            }
        }
    }
}
