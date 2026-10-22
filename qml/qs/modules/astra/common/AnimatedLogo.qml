import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

// The FlightDeck logo (assets/icons/flightdeck.svg) drawn in the theme's colours: an
// instrument panel with a gauge. On load the panel pops in, the dial sweeps on and the
// needle swings up from rest; clicking revs the needle and lets it settle back.
Item {
    id: root

    readonly property real designSize: 512
    property bool skipIntroAnimation: false

    property real panelProgress: 1.0
    property real dialProgress: 1.0
    // Needle angle in degrees, clockwise from pointing right: 180 points left (rest) and
    // 310 is the logo's reading. Counting up from 180 keeps the swing over the top.
    readonly property real needleReading: 310
    property real needleAngle: needleReading

    readonly property real gaugeX: 256
    readonly property real gaugeY: 300
    readonly property real baseScale: Math.min(width / designSize, height / designSize)

    implicitWidth: 120
    implicitHeight: 120

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!introAnim.running && !revAnim.running)
                revAnim.restart();
        }
    }

    // Click: rev the needle into the red, then let it fall back with a wobble
    SequentialAnimation {
        id: revAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "needleAngle"
                to: 352
                duration: 260
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: logo
                property: "scale"
                to: root.baseScale * 1.08
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "needleAngle"
                to: root.needleReading
                duration: 900
                easing.type: Easing.OutElastic
                easing.amplitude: 1.0
                easing.period: 0.4
            }

            NumberAnimation {
                target: logo
                property: "scale"
                to: root.baseScale
                duration: 450
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            }
        }
    }

    Item {
        id: logo

        width: root.designSize
        height: root.designSize
        anchors.centerIn: parent
        scale: root.baseScale
        transformOrigin: Item.Center

        SequentialAnimation {
            id: introAnim
            running: !root.skipIntroAnimation

            ScriptAction {
                script: {
                    root.panelProgress = 0.0;
                    root.dialProgress = 0.0;
                    root.needleAngle = 180;
                    logo.opacity = 0.0;
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: logo
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 400
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root
                    property: "panelProgress"
                    from: 0.0
                    to: 1.0
                    duration: 700
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                SequentialAnimation {
                    PauseAnimation { duration: 250 }
                    NumberAnimation {
                        target: root
                        property: "dialProgress"
                        from: 0.0
                        to: 1.0
                        duration: 550
                        easing.type: Easing.InOutCubic
                    }
                }

                SequentialAnimation {
                    PauseAnimation { duration: 500 }
                    NumberAnimation {
                        target: root
                        property: "needleAngle"
                        from: 180
                        to: root.needleReading
                        duration: 900
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.6
                    }
                }
            }
        }

        // Instrument panel: outer frame and inner face
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: Math.min(1.0, root.panelProgress * 1.8)

            transform: Scale {
                origin.x: 256
                origin.y: 258
                xScale: 0.7 + 0.3 * root.panelProgress
                yScale: 0.7 + 0.3 * root.panelProgress
            }

            ShapePath {
                fillColor: Colours.palette.m3primary
                strokeColor: "transparent"

                PathSvg {
                    path: "M88 120Q256 84 424 120Q464 128 456 170L420 388Q412 432 368 432H144Q100 432 92 388L56 170Q48 128 88 120Z"
                }
            }

            ShapePath {
                fillColor: Colours.palette.m3primaryContainer
                strokeColor: "transparent"

                PathSvg {
                    path: "M112 160Q256 132 400 160Q424 166 420 190L392 368Q386 396 358 396H154Q126 396 120 368L92 190Q88 166 112 160Z"
                }
            }
        }

        // Dial: the arc sweeps on from the left
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            visible: root.dialProgress > 0

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.palette.m3tertiary
                strokeWidth: 20
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.gaugeX
                    centerY: root.gaugeY
                    radiusX: 100
                    radiusY: 100
                    startAngle: 180
                    sweepAngle: 180 * root.dialProgress
                }
            }
        }

        // Needle and pivot
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: Math.min(1.0, root.dialProgress * 2.0)

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.palette.m3onPrimaryContainer
                strokeWidth: 20
                capStyle: ShapePath.RoundCap
                startX: root.gaugeX
                startY: root.gaugeY

                PathLine {
                    x: root.gaugeX + 80 * Math.cos(root.needleAngle * Math.PI / 180)
                    y: root.gaugeY + 80 * Math.sin(root.needleAngle * Math.PI / 180)
                }
            }

            ShapePath {
                fillColor: Colours.palette.m3onPrimaryContainer
                strokeColor: "transparent"

                PathAngleArc {
                    centerX: root.gaugeX
                    centerY: root.gaugeY
                    radiusX: 22
                    radiusY: 22
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }
}
