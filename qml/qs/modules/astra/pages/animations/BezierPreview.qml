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
    implicitHeight: 48

    property real progress: 0.0

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

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.medium
        color: Colours.palette.m3surfaceContainerLow

        StyledSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.large
            implicitHeight: 12
            circleHandle: true
            from: 0.0
            to: 1.0
            value: root.ease(root.progress)
            enabled: false
        }
    }
}
