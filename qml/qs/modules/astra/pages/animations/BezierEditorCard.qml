import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

ConnectedRect {
    id: root

    first: true
    last: true

    property string curveName: "custom"
    property real x1: 0.25
    property real y1: 0.1
    property real x2: 0.25
    property real y2: 1.0
    property bool showSavedNotice: false

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
            id: preview
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            x1: root.x1
            y1: root.y1
            x2: root.x2
            y2: root.y2
        }

        Timer {
            id: saveNoticeTimer
            interval: 1600
            onTriggered: root.showSavedNotice = false
        }

        // Stepper coordinate inputs (P1)
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("P1 X")
                from: 0.0
                to: 1.0
                stepSize: 0.02
                value: root.x1
                onMoved: v => {
                    root.x1 = Math.round(v * 100) / 100;
                }
            }

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("P1 Y")
                from: -1.0
                to: 2.0
                stepSize: 0.02
                value: root.y1
                onMoved: v => {
                    root.y1 = Math.round(v * 100) / 100;
                }
            }
        }

        // Stepper coordinate inputs (P2)
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("P2 X")
                from: 0.0
                to: 1.0
                stepSize: 0.02
                value: root.x2
                onMoved: v => {
                    root.x2 = Math.round(v * 100) / 100;
                }
            }

            StepperRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("P2 Y")
                from: -1.0
                to: 2.0
                stepSize: 0.02
                value: root.y2
                onMoved: v => {
                    root.y2 = Math.round(v * 100) / 100;
                }
            }
        }

        TextButton {
            Layout.fillWidth: true
            implicitHeight: 40
            text: root.showSavedNotice ? qsTr("✓ Saved to Config") : qsTr("Save Curve")
            onClicked: {
                AnimationManager.addBezierCurve(root.curveName, root.x1, root.y1, root.x2, root.y2);
                root.showSavedNotice = true;
                saveNoticeTimer.restart();
            }
        }
    }
}
