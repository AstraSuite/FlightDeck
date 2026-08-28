import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

ConnectedRect {
    id: root

    first: true
    last: true
    implicitHeight: 280

    readonly property var monitors: MonitorManager.liveMonitors
    property int selectedIndex: 0

    // Canvas scaling calculations with generous padding
    readonly property real pad: 40
    readonly property real canvasW: Math.max(100, width - pad * 2)
    readonly property real canvasH: Math.max(100, height - pad * 2)

    property real minX: 0
    property real minY: 0
    property real totalW: 3840
    property real totalH: 2160
    property real scaleFactor: 0.08

    function isPortrait(m) {
        if (!m) return false;
        var t = m.transform ?? 0;
        return t === 1 || t === 3 || t === 5 || t === 7;
    }

    function getEffW(m) {
        if (!m) return 1920;
        var rawW = isPortrait(m) ? (m.height || 1080) : (m.width || 1920);
        return rawW / (m.scale || 1.0);
    }

    function getEffH(m) {
        if (!m) return 1080;
        var rawH = isPortrait(m) ? (m.width || 1920) : (m.height || 1080);
        return rawH / (m.scale || 1.0);
    }

    function updateBounds() {
        if (!monitors || monitors.length === 0) return;
        var minX_ = 99999, minY_ = 99999, maxX_ = -99999, maxY_ = -99999;
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
            if (m.disabled) continue;
            var effW = root.getEffW(m);
            var effH = root.getEffH(m);
            minX_ = Math.min(minX_, m.x || 0);
            minY_ = Math.min(minY_, m.y || 0);
            maxX_ = Math.max(maxX_, (m.x || 0) + effW);
            maxY_ = Math.max(maxY_, (m.y || 0) + effH);
        }
        if (minX_ === 99999) {
            minX_ = 0; minY_ = 0; maxX_ = 1920; maxY_ = 1080;
        }
        root.minX = minX_;
        root.minY = minY_;
        root.totalW = Math.max(100, maxX_ - minX_);
        root.totalH = Math.max(100, maxY_ - minY_);

        var sx = root.canvasW / root.totalW;
        var sy = root.canvasH / root.totalH;
        root.scaleFactor = Math.min(sx, sy) * 0.85;
    }

    onMonitorsChanged: updateBounds()
    onWidthChanged: updateBounds()
    onHeightChanged: updateBounds()

    Component.onCompleted: updateBounds()

    Item {
        id: container
        anchors.centerIn: parent
        width: root.totalW * root.scaleFactor
        height: root.totalH * root.scaleFactor

        Repeater {
            model: root.monitors

            delegate: Item {
                id: monBox
                required property var modelData
                required property int index

                readonly property bool portrait: root.isPortrait(modelData)
                readonly property real effW: root.getEffW(modelData)
                readonly property real effH: root.getEffH(modelData)

                x: ((modelData.x || 0) - root.minX) * root.scaleFactor
                y: ((modelData.y || 0) - root.minY) * root.scaleFactor
                width: Math.max(50, effW * root.scaleFactor)
                height: Math.max(40, effH * root.scaleFactor)

                visible: !modelData.disabled

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: root.selectedIndex === monBox.index ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerLow
                    border.width: root.selectedIndex === monBox.index ? 2 : 1
                    border.color: root.selectedIndex === monBox.index ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: monBox.portrait ? "smartphone" : "desktop_windows"
                            color: root.selectedIndex === monBox.index ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: monBox.modelData.name
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Math.round(monBox.effW) + "x" + Math.round(monBox.effH)
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "(" + (monBox.modelData.x || 0) + ", " + (monBox.modelData.y || 0) + ")"
                            font: Tokens.font.label.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: monBox
                    drag.axis: Drag.XAndYAxis

                    property real startMonX: 0
                    property real startMonY: 0

                    onPressed: {
                        root.selectedIndex = monBox.index;
                        startMonX = monBox.modelData.x || 0;
                        startMonY = monBox.modelData.y || 0;
                    }

                    onReleased: {
                        if (root.scaleFactor > 0) {
                            var newX = Math.round(root.minX + monBox.x / root.scaleFactor);
                            var newY = Math.round(root.minY + monBox.y / root.scaleFactor);

                            // Snap to nearest 10px
                            newX = Math.round(newX / 10) * 10;
                            newY = Math.round(newY / 10) * 10;

                            var modeStr = monBox.modelData.width + "x" + monBox.modelData.height + "@" + monBox.modelData.refreshRate;
                            var posStr = newX + "x" + newY;
                            MonitorManager.applyMonitor(monBox.modelData.name, modeStr, posStr, monBox.modelData.scale, monBox.modelData.transform, monBox.modelData.disabled);
                            root.updateBounds();
                        }
                    }
                }
            }
        }
    }
}
