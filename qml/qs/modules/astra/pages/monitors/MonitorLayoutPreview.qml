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
    implicitHeight: 300

    readonly property var monitors: MonitorManager.liveMonitors
    property int selectedIndex: 0

    readonly property real pad: 40
    readonly property real canvasW: Math.max(100, width - pad * 2)
    readonly property real canvasH: Math.max(100, height - pad * 2 - (hasGapWarning ? 32 : 0))

    property real minX: 0
    property real minY: 0
    property real totalW: 3840
    property real totalH: 2160
    property real scaleFactor: 0.08
    property bool hasGapWarning: false

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

    function checkGaps() {
        if (!monitors || monitors.length <= 1) {
            hasGapWarning = false;
            return;
        }

        var active = [];
        for (var i = 0; i < monitors.length; i++) {
            if (!monitors[i].disabled) {
                var m = monitors[i];
                active.push({
                    x: m.x || 0,
                    y: m.y || 0,
                    w: getEffW(m),
                    h: getEffH(m)
                });
            }
        }

        if (active.length <= 1) {
            hasGapWarning = false;
            return;
        }

        // Check if graph of overlapping/touching bounding boxes is connected
        var visited = new Set();
        var queue = [0];
        visited.add(0);

        while (queue.length > 0) {
            var currIdx = queue.shift();
            var c = active[currIdx];

            for (var j = 0; j < active.length; j++) {
                if (visited.has(j)) continue;
                var o = active[j];

                // Check if c and o touch or overlap (within 2px tolerance)
                var touchesX = (c.x <= o.x + o.w + 2) && (c.x + c.w + 2 >= o.x);
                var touchesY = (c.y <= o.y + o.h + 2) && (c.y + c.h + 2 >= o.y);

                if (touchesX && touchesY) {
                    visited.add(j);
                    queue.push(j);
                }
            }
        }

        hasGapWarning = (visited.size < active.length);
    }

    function updateBounds() {
        if (!monitors || monitors.length === 0) return;
        var minX_ = 99999, minY_ = 99999, maxX_ = -99999, maxY_ = -99999;
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
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

        checkGaps();
    }

    focus: true
    activeFocusOnTab: true

    function snapPosition(targetIdx, proposedX, proposedY, currentEffW, currentEffH) {
        var snapThreshold = 40;
        var finalX = proposedX;
        var finalY = proposedY;
        var snappedX = false;
        var snappedY = false;

        for (var i = 0; i < root.monitors.length; i++) {
            if (i === targetIdx) continue;
            var other = root.monitors[i];
            if (other.disabled) continue;

            var otherEffW = root.getEffW(other);
            var otherEffH = root.getEffH(other);
            var ox = other.x || 0;
            var oy = other.y || 0;

            // X-axis alignment
            if (!snappedX) {
                if (Math.abs(proposedX - ox) < snapThreshold) {
                    finalX = ox;
                    snappedX = true;
                } else if (Math.abs(proposedX - (ox + otherEffW)) < snapThreshold) {
                    finalX = ox + otherEffW;
                    snappedX = true;
                } else if (Math.abs(proposedX + currentEffW - ox) < snapThreshold) {
                    finalX = ox - currentEffW;
                    snappedX = true;
                } else if (Math.abs(proposedX + currentEffW - (ox + otherEffW)) < snapThreshold) {
                    finalX = ox + otherEffW - currentEffW;
                    snappedX = true;
                } else if (Math.abs(proposedX + currentEffW / 2 - (ox + otherEffW / 2)) < snapThreshold) {
                    finalX = Math.round(ox + (otherEffW - currentEffW) / 2);
                    snappedX = true;
                }
            }

            // Y-axis alignment
            if (!snappedY) {
                if (Math.abs(proposedY - oy) < snapThreshold) {
                    finalY = oy;
                    snappedY = true;
                } else if (Math.abs(proposedY - (oy + otherEffH)) < snapThreshold) {
                    finalY = oy + otherEffH;
                    snappedY = true;
                } else if (Math.abs(proposedY + currentEffH - oy) < snapThreshold) {
                    finalY = oy - currentEffH;
                    snappedY = true;
                } else if (Math.abs(proposedY + currentEffH - (oy + otherEffH)) < snapThreshold) {
                    finalY = oy + otherEffH - currentEffH;
                    snappedY = true;
                } else if (Math.abs(proposedY + currentEffH / 2 - (oy + otherEffH / 2)) < snapThreshold) {
                    finalY = Math.round(oy + (otherEffH - currentEffH) / 2);
                    snappedY = true;
                }
            }
        }
        return { x: finalX, y: finalY };
    }

    function moveSelected(dx, dy) {
        if (!monitors || selectedIndex < 0 || selectedIndex >= monitors.length) return;
        var m = monitors[selectedIndex];
        if (m.disabled) return;

        var newX = (m.x || 0) + dx;
        var newY = (m.y || 0) + dy;

        var monCopy = Object.assign({}, m);
        monCopy.x = newX;
        monCopy.y = newY;
        monCopy.output = m.name;
        monCopy.position = newX + "x" + newY;
        if (!monCopy.mode && m.width && m.height) {
            monCopy.mode = m.width + "x" + m.height + "@" + (m.refreshRate || 60);
        }

        MonitorManager.applyMonitor(monCopy);
        updateBounds();
    }

    Keys.onPressed: (event) => {
        var delta = 1;
        if (event.modifiers & Qt.ShiftModifier) {
            delta = 50;
        } else if (event.modifiers & Qt.ControlModifier) {
            delta = 10;
        }

        if (event.key === Qt.Key_Left) {
            moveSelected(-delta, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            moveSelected(delta, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            moveSelected(0, -delta);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            moveSelected(0, delta);
            event.accepted = true;
        }
    }

    onMonitorsChanged: updateBounds()
    onWidthChanged: updateBounds()
    onHeightChanged: updateBounds()

    Component.onCompleted: updateBounds()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.small

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

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

                        readonly property var mon: modelData || ({})
                        readonly property bool portrait: root.isPortrait(mon)
                        readonly property real effW: root.getEffW(mon)
                        readonly property real effH: root.getEffH(mon)
                        readonly property bool isSelected: root.selectedIndex === monBox.index

                        x: ((mon.x || 0) - root.minX) * root.scaleFactor
                        y: ((mon.y || 0) - root.minY) * root.scaleFactor
                        width: Math.max(60, effW * root.scaleFactor)
                        height: Math.max(45, effH * root.scaleFactor)

                        visible: true
                        opacity: monBox.mon.disabled ? 0.45 : 1.0

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.medium
                            color: monBox.mon.disabled
                                   ? Colours.palette.m3surfaceContainerLowest
                                   : (monBox.isSelected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerLow)
                            border.width: monBox.isSelected ? 2 : 1
                            border.color: monBox.mon.disabled
                                          ? (monBox.isSelected ? Colours.palette.m3primary : Colours.palette.m3outline)
                                          : (monBox.isSelected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant)

                            // Number badge
                            StyledRect {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 4
                                width: 20
                                height: 20
                                radius: Tokens.rounding.full
                                color: monBox.isSelected ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                                StyledText {
                                    anchors.centerIn: parent
                                    text: (monBox.index + 1).toString()
                                    font: Tokens.font.label.small
                                    color: monBox.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                }
                            }

                            // Mirror / Disabled badge
                            RowLayout {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 4
                                spacing: 2

                                MaterialIcon {
                                    visible: !!(monBox.mon.mirror && monBox.mon.mirror !== "none")
                                    text: "content_copy"
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3secondary
                                }

                                MaterialIcon {
                                    visible: !!monBox.mon.disabled
                                    text: "visibility_off"
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3outline
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: monBox.portrait ? "smartphone" : "desktop_windows"
                                    color: monBox.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: monBox.mon.name || ""
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurface
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: monBox.mon.disabled ? qsTr("(Disabled)") : (Math.round(monBox.effW) + "x" + Math.round(monBox.effH))
                                    font: Tokens.font.label.small
                                    color: monBox.mon.disabled ? Colours.palette.m3outline : Colours.palette.m3outline
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: !monBox.mon.disabled
                                    text: "(" + (monBox.mon.x || 0) + ", " + (monBox.mon.y || 0) + ")"
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

                        onPressed: {
                            root.selectedIndex = monBox.index;
                            root.forceActiveFocus();
                        }

                        onReleased: {
                            if (root.scaleFactor > 0) {
                                var newX = Math.round(root.minX + monBox.x / root.scaleFactor);
                                var newY = Math.round(root.minY + monBox.y / root.scaleFactor);

                                var snapped = root.snapPosition(monBox.index, newX, newY, monBox.effW, monBox.effH);
                                newX = snapped.x;
                                newY = snapped.y;

                                var monCopy = Object.assign({}, monBox.mon);
                                monCopy.x = newX;
                                monCopy.y = newY;
                                monCopy.output = monBox.mon.name || "";
                                monCopy.position = newX + "x" + newY;
                                if (!monCopy.mode && monBox.mon.width && monBox.mon.height) {
                                    monCopy.mode = monBox.mon.width + "x" + monBox.mon.height + "@" + (monBox.mon.refreshRate || 60);
                                }

                                MonitorManager.applyMonitor(monCopy);
                                root.updateBounds();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Gap warning banner
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            visible: root.hasGapWarning
            radius: Tokens.rounding.small
            color: Colours.palette.m3errorContainer

            RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "warning"
                    color: Colours.palette.m3onErrorContainer
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: qsTr("Displays are disconnected by a gap — cursor cannot cross between them.")
                    color: Colours.palette.m3onErrorContainer
                    font: Tokens.font.label.small
                }
            }
        }
    }
}
