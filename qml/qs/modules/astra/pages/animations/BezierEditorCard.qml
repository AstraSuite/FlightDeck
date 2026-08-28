import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Helm.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import Helm.Managers 1.0

ConnectedRect {
    id: root

    first: true
    last: true

    property string curveName: "custom"
    property real x1: 0.25
    property real y1: 0.1
    property real x2: 0.25
    property real y2: 1.0

    implicitHeight: col.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledTextField {
            Layout.fillWidth: true
            placeholderText: qsTr("Curve Name (e.g. md3_decel, custom)")
            text: root.curveName
            onTextEdited: root.curveName = text
        }

        BezierCanvas {
            id: canvas
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            x1: root.x1
            y1: root.y1
            x2: root.x2
            y2: root.y2

            onPointsChanged: (px1, py1, px2, py2) => {
                root.x1 = px1;
                root.y1 = py1;
                root.x2 = px2;
                root.y2 = py2;
            }
        }

        BezierPreview {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            x1: root.x1
            y1: root.y1
            x2: root.x2
            y2: root.y2
        }

        // Stepper coordinate inputs
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: "P1 (x, y)"
                from: 0.0
                to: 1.0
                stepSize: 0.05
                value: root.x1
                onMoved: v => root.x1 = Math.round(v * 100) / 100
            }

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: "P2 (x, y)"
                from: 0.0
                to: 1.0
                stepSize: 0.05
                value: root.x2
                onMoved: v => root.x2 = Math.round(v * 100) / 100
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: qsTr("Test Curve")
                onClicked: {
                    AnimationManager.testCurve(root.curveName, root.x1, root.y1, root.x2, root.y2);
                }
            }

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: qsTr("Save Curve")
                onClicked: {
                    AnimationManager.addBezierCurve(root.curveName, root.x1, root.y1, root.x2, root.y2);
                }
            }
        }
    }
}
