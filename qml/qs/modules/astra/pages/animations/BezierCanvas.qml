import QtQuick
import FlightDeck.Config
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
        return Math.max(0.0, Math.min(1.0, (root.height - root.pad - sy) / root.plotH));
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
        width: 18
        height: 18
        radius: 9
        color: Colours.palette.m3primary
        border.width: 2
        border.color: Colours.palette.m3onPrimary
        z: 10

        x: root.toScreenX(root.x1) - width / 2
        y: root.toScreenY(root.y1) - height / 2

        MouseArea {
            id: ma1
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            property real pressCursorOffsetCanvasX: 0
            property real pressCursorOffsetCanvasY: 0

            onPressed: mouse => {
                root.forceActiveFocus();
                var pressPos = ma1.mapToItem(root, mouse.x, mouse.y);
                pressCursorOffsetCanvasX = pressPos.x - root.toScreenX(root.x1);
                pressCursorOffsetCanvasY = pressPos.y - root.toScreenY(root.y1);
            }

            onPositionChanged: mouse => {
                if (pressed) {
                    var curPos = ma1.mapToItem(root, mouse.x, mouse.y);
                    var targetCanvasX = curPos.x - pressCursorOffsetCanvasX;
                    var targetCanvasY = curPos.y - pressCursorOffsetCanvasY;
                    var nx = Math.round(root.fromScreenX(targetCanvasX) * 100) / 100;
                    var ny = Math.round(root.fromScreenY(targetCanvasY) * 100) / 100;
                    root.pointsChanged(nx, ny, root.x2, root.y2);
                }
            }
        }
    }

    // Handle 2 (P2)
    Rectangle {
        id: handle2
        width: 18
        height: 18
        radius: 9
        color: Colours.palette.m3tertiary
        border.width: 2
        border.color: Colours.palette.m3onTertiary
        z: 10

        x: root.toScreenX(root.x2) - width / 2
        y: root.toScreenY(root.y2) - height / 2

        MouseArea {
            id: ma2
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            property real pressCursorOffsetCanvasX: 0
            property real pressCursorOffsetCanvasY: 0

            onPressed: mouse => {
                root.forceActiveFocus();
                var pressPos = ma2.mapToItem(root, mouse.x, mouse.y);
                pressCursorOffsetCanvasX = pressPos.x - root.toScreenX(root.x2);
                pressCursorOffsetCanvasY = pressPos.y - root.toScreenY(root.y2);
            }

            onPositionChanged: mouse => {
                if (pressed) {
                    var curPos = ma2.mapToItem(root, mouse.x, mouse.y);
                    var targetCanvasX = curPos.x - pressCursorOffsetCanvasX;
                    var targetCanvasY = curPos.y - pressCursorOffsetCanvasY;
                    var nx = Math.round(root.fromScreenX(targetCanvasX) * 100) / 100;
                    var ny = Math.round(root.fromScreenY(targetCanvasY) * 100) / 100;
                    root.pointsChanged(root.x1, root.y1, nx, ny);
                }
            }
        }
    }
}
