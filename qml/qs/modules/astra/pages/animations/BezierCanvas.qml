import QtQuick
import Helm.Config
import qs.components
import qs.services

Item {
    id: root

    property real x1: 0.25
    property real y1: 0.1
    property real x2: 0.25
    property real y2: 1.0

    signal pointsChanged(real px1, real py1, real px2, real py2)

    implicitWidth: 320
    implicitHeight: 260

    readonly property real pad: 28
    readonly property real plotW: width - pad * 2
    readonly property real plotH: height - pad * 2

    function toScreenX(bx) {
        return root.pad + bx * root.plotW;
    }

    function toScreenY(by) {
        return root.height - root.pad - by * root.plotH;
    }

    function fromScreenX(sx) {
        return Math.max(0.0, Math.min(1.0, (sx - root.pad) / root.plotW));
    }

    function fromScreenY(sy) {
        return Math.max(-0.5, Math.min(1.5, (root.height - root.pad - sy) / root.plotH));
    }

    onX1Changed: canvas.requestPaint()
    onY1Changed: canvas.requestPaint()
    onX2Changed: canvas.requestPaint()
    onY2Changed: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var p0x = root.toScreenX(0);
            var p0y = root.toScreenY(0);
            var p1x = root.toScreenX(root.x1);
            var p1y = root.toScreenY(root.y1);
            var p2x = root.toScreenX(root.x2);
            var p2y = root.toScreenY(root.y2);
            var p3x = root.toScreenX(1);
            var p3y = root.toScreenY(1);

            // Grid background box
            ctx.fillStyle = Colours.palette.m3surfaceContainerLow;
            ctx.fillRect(root.pad, root.toScreenY(1), root.plotW, root.plotH);

            // Grid lines (0.25, 0.5, 0.75)
            ctx.strokeStyle = Colours.palette.m3outlineVariant;
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (var g = 0.25; g < 1.0; g += 0.25) {
                var gx = root.toScreenX(g);
                var gy = root.toScreenY(g);
                ctx.moveTo(gx, root.toScreenY(0));
                ctx.lineTo(gx, root.toScreenY(1));
                ctx.moveTo(root.toScreenX(0), gy);
                ctx.lineTo(root.toScreenX(1), gy);
            }
            ctx.stroke();

            // Diagonal reference
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
            ctx.setLineDash([4, 4]);
            ctx.beginPath();
            ctx.moveTo(p0x, p0y);
            ctx.lineTo(p3x, p3y);
            ctx.stroke();
            ctx.setLineDash([]);

            // Handle line 1
            ctx.strokeStyle = Colours.palette.m3primary;
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(p0x, p0y);
            ctx.lineTo(p1x, p1y);
            ctx.stroke();

            // Handle line 2
            ctx.strokeStyle = Colours.palette.m3tertiary;
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(p3x, p3y);
            ctx.lineTo(p2x, p2y);
            ctx.stroke();

            // Bezier curve
            ctx.strokeStyle = Colours.palette.m3onSurface;
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.moveTo(p0x, p0y);
            ctx.bezierCurveTo(p1x, p1y, p2x, p2y, p3x, p3y);
            ctx.stroke();
        }
    }

    // Handle 1 (P1)
    Rectangle {
        id: handle1
        x: root.toScreenX(root.x1) - width / 2
        y: root.toScreenY(root.y1) - height / 2
        width: 18
        height: 18
        radius: 9
        color: Colours.palette.m3primary
        border.width: 2
        border.color: Colours.palette.m3onPrimary
        z: 10

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            drag.target: parent
            drag.axis: Drag.XAndYAxis

            onPositionChanged: {
                if (drag.active) {
                    root.x1 = Math.round(root.fromScreenX(handle1.x + handle1.width / 2) * 100) / 100;
                    root.y1 = Math.round(root.fromScreenY(handle1.y + handle1.height / 2) * 100) / 100;
                    root.pointsChanged(root.x1, root.y1, root.x2, root.y2);
                }
            }
        }
    }

    // Handle 2 (P2)
    Rectangle {
        id: handle2
        x: root.toScreenX(root.x2) - width / 2
        y: root.toScreenY(root.y2) - height / 2
        width: 18
        height: 18
        radius: 9
        color: Colours.palette.m3tertiary
        border.width: 2
        border.color: Colours.palette.m3onTertiary
        z: 10

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            drag.target: parent
            drag.axis: Drag.XAndYAxis

            onPositionChanged: {
                if (drag.active) {
                    root.x2 = Math.round(root.fromScreenX(handle2.x + handle2.width / 2) * 100) / 100;
                    root.y2 = Math.round(root.fromScreenY(handle2.y + handle2.height / 2) * 100) / 100;
                    root.pointsChanged(root.x1, root.y1, root.x2, root.y2);
                }
            }
        }
    }
}
