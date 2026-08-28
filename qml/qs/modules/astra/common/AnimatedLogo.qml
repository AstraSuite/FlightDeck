import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

Item {
    id: root

    readonly property real designWidth: 1000
    readonly property real designHeight: 750
    readonly property real designSize: 1000
    property bool skipIntroAnimation: false

    property real outerProgress: 1.0
    property real glyphProgress: 1.0
    property real cogRotation: 0.0

    implicitWidth: 120
    implicitHeight: 120

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!introAnim.running && !clickSpinAnim.running) {
                clickSpinAnim.restart();
            }
        }
    }

    SequentialAnimation {
        id: clickSpinAnim
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "cogRotation"
                from: 0
                to: 360
                duration: 700
                easing.type: Easing.InOutCubic
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: Math.min(root.width / root.designWidth, root.height / root.designHeight)
                    to: Math.min(root.width / root.designWidth, root.height / root.designHeight) * 1.12
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: Math.min(root.width / root.designWidth, root.height / root.designHeight) * 1.12
                    to: Math.min(root.width / root.designWidth, root.height / root.designHeight)
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "glyphProgress"
                    from: 1.0
                    to: 0.6
                    duration: 250
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root
                    property: "glyphProgress"
                    from: 0.6
                    to: 1.0
                    duration: 450
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.6
                }
            }
        }

        ScriptAction {
            script: root.cogRotation = 0
        }
    }

    Item {
        id: logo

        implicitWidth: root.designWidth
        implicitHeight: root.designHeight

        anchors.centerIn: parent
        scale: Math.min(root.width / root.designWidth, root.height / root.designHeight)
        transformOrigin: Item.Center

        rotation: 0.0
        opacity: 1.0

        SequentialAnimation {
            id: introAnim
            running: !root.skipIntroAnimation

            ScriptAction {
                script: {
                    root.outerProgress = 0.0;
                    root.glyphProgress = 0.0;
                    root.cogRotation = 0.0;
                    logo.rotation = -45.0;
                    logo.opacity = 0.0;
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: logo
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 600
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: -45
                    to: 0
                    duration: 900
                    easing.type: Easing.OutCubic
                }

                SequentialAnimation {
                    PauseAnimation { duration: 100 }
                    NumberAnimation {
                        target: logo
                        property: "scale"
                        from: Math.min(root.width / root.designWidth, root.height / root.designHeight) * 0.7
                        to: Math.min(root.width / root.designWidth, root.height / root.designHeight)
                        duration: 800
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                NumberAnimation {
                    target: root
                    property: "outerProgress"
                    from: 0.0
                    to: 1.0
                    duration: 900
                    easing.type: Easing.OutCubic
                }

                SequentialAnimation {
                    PauseAnimation { duration: 300 }
                    NumberAnimation {
                        target: root
                        property: "glyphProgress"
                        from: 0.0
                        to: 1.0
                        duration: 650
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }
            }
        }

        Shape {
            id: shieldShape
            width: root.designWidth
            height: root.designHeight
            z: 1
            preferredRendererType: Shape.CurveRenderer

            opacity: Math.min(1.0, root.outerProgress * 1.8)

            transform: [
                Scale {
                    origin.x: 500
                    origin.y: 375
                    xScale: 0.6 + 0.4 * root.outerProgress
                    yScale: 0.6 + 0.4 * root.outerProgress
                }
            ]

            ShapePath {
                fillColor: Colours.palette.m3primary
                strokeColor: Colours.palette.m3onSurface
                strokeWidth: 50
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: "M500 25C634.878 25 816.792 83.1182 918.125 119.957C947.7 130.709 963.957 162.588 955.495 194.167L826.153 676.825C818.538 705.241 792.787 725 763.368 725H231.77C202.154 725 176.282 704.981 168.85 676.313L43.7754 193.904C35.6199 162.449 51.875 130.873 81.2607 120.181C182.457 83.3592 364.841 25 500 25Z"
                }
            }
        }

        Shape {
            id: gearGlyph
            width: root.designWidth
            height: root.designHeight
            z: 2
            preferredRendererType: Shape.CurveRenderer

            opacity: Math.min(1.0, root.glyphProgress * 1.8)

            transform: [
                Rotation {
                    origin.x: 501.244
                    origin.y: 376
                    angle: (1.0 - root.glyphProgress) * -120 + root.cogRotation
                },
                Scale {
                    origin.x: 501.244
                    origin.y: 376
                    xScale: 0.5 + 0.5 * root.glyphProgress
                    yScale: 0.5 + 0.5 * root.glyphProgress
                }
            ]

            ShapePath {
                fillColor: Colours.palette.m3tertiary
                strokeColor: "transparent"

                PathSvg {
                    path: "M431.592 625L421.642 545.32C416.252 543.245 411.173 540.755 406.405 537.85C401.638 534.945 396.973 531.833 392.413 528.513L318.408 559.638L250 441.363L314.055 392.808C313.64 389.903 313.433 387.101 313.433 384.404V367.596C313.433 364.899 313.64 362.098 314.055 359.193L250 310.638L318.408 192.363L392.413 223.488C396.973 220.168 401.741 217.055 406.716 214.15C411.692 211.245 416.667 208.755 421.642 206.68L431.592 127H568.408L578.358 206.68C583.748 208.755 588.827 211.245 593.595 214.15C598.362 217.055 603.027 220.168 607.587 223.488L681.592 192.363L750 310.638L685.945 359.193C686.36 362.098 686.567 364.899 686.567 367.596V384.404C686.567 387.101 686.153 389.903 685.323 392.808L749.378 441.363L680.97 559.638L607.587 528.513C603.027 531.833 598.259 534.945 593.284 537.85C588.308 540.755 583.333 543.245 578.358 545.32L568.408 625H431.592ZM475.124 575.2H524.254L532.96 509.215C545.813 505.895 557.732 501.019 568.719 494.586C579.706 488.154 589.76 480.373 598.881 471.243L660.448 496.765L684.701 454.435L631.219 413.973C633.292 408.163 634.743 402.041 635.572 395.609C636.401 389.176 636.816 382.64 636.816 376C636.816 369.36 636.401 362.824 635.572 356.391C634.743 349.959 633.292 343.838 631.219 338.028L684.701 297.565L660.448 255.235L598.881 281.38C589.76 271.835 579.706 263.846 568.719 257.414C557.732 250.981 545.813 246.105 532.96 242.785L524.876 176.8H475.746L467.04 242.785C454.187 246.105 442.268 250.981 431.281 257.414C420.294 263.846 410.24 271.628 401.119 280.758L339.552 255.235L315.299 297.565L368.781 337.405C366.708 343.63 365.257 349.855 364.428 356.08C363.599 362.305 363.184 368.945 363.184 376C363.184 382.64 363.599 389.073 364.428 395.298C365.257 401.523 366.708 407.748 368.781 413.973L315.299 454.435L339.552 496.765L401.119 470.62C410.24 480.165 420.294 488.154 431.281 494.586C442.268 501.019 454.187 505.895 467.04 509.215L475.124 575.2ZM501.244 463.15C525.29 463.15 545.813 454.643 562.811 437.628C579.809 420.613 588.308 400.07 588.308 376C588.308 351.93 579.809 331.388 562.811 314.373C545.813 297.358 525.29 288.85 501.244 288.85C476.783 288.85 456.157 297.358 439.366 314.373C422.575 331.388 414.179 351.93 414.179 376C414.179 400.07 422.575 420.613 439.366 437.628C456.157 454.643 476.783 463.15 501.244 463.15Z"
                }
            }
        }
    }
}

