pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.astra

Item {
    id: root

    required property string title
    required property AstraState nState
    readonly property GlobalConfig targetConfig: GlobalConfig.forScreen(nState.targetScreen)
    readonly property bool isPageBase: true
    property bool isSubPage
    property bool scrollable: true
    readonly property int cappedWidth: Math.min(Tokens.sizes.astra.maxContentWidth, width)
    readonly property alias flickable: flickable
    readonly property alias modalOverlay: overlayLayer

    default property Item contentChild

    function doScrollToItem(targetKey: string): bool {
        if (!root.contentChild || !targetKey || targetKey.trim() === "") return false;

        var targets = targetKey.split("|").map(t => t.trim().toLowerCase()).filter(t => t.length > 0);
        if (targets.length === 0) return false;

        function safeStr(val) {
            if (val === null || val === undefined) return "";
            if (typeof val === "string") return val;
            if (typeof val === "number" || typeof val === "boolean") return String(val);
            return "";
        }

        var allItems = [];
        function collectItems(parentItem) {
            if (!parentItem || !parentItem.children) return;
            for (var i = 0; i < parentItem.children.length; i++) {
                var child = parentItem.children[i];
                if (!child || !child.visible) continue;
                allItems.push(child);
                collectItems(child);
            }
        }
        collectItems(root.contentChild);

        var matchedItem = null;

        // Pass 1: Exact match on varKey, label, title, or text
        for (var i = 0; i < allItems.length; i++) {
            var item = allItems[i];
            var cVarKey = safeStr(item.varKey).toLowerCase().trim();
            var cLabel = safeStr(item.label).toLowerCase().trim();
            var cTitle = safeStr(item.title).toLowerCase().trim();
            var cText = safeStr(item.text).toLowerCase().trim();

            for (var t = 0; t < targets.length; t++) {
                var tk = targets[t];
                if (cVarKey !== "" && cVarKey === tk) { matchedItem = item; break; }
                if (cLabel !== "" && cLabel === tk) { matchedItem = item; break; }
                if (cTitle !== "" && cTitle === tk) { matchedItem = item; break; }
                if (cText !== "" && cText === tk) { matchedItem = item; break; }
            }
            if (matchedItem) break;
        }

        // Pass 2: Substring match (where item's label/title contains the search term)
        if (!matchedItem) {
            for (var j = 0; j < allItems.length; j++) {
                var it2 = allItems[j];
                var cVarKey2 = safeStr(it2.varKey).toLowerCase().trim();
                var cLabel2 = safeStr(it2.label).toLowerCase().trim();
                var cTitle2 = safeStr(it2.title).toLowerCase().trim();
                var cText2 = safeStr(it2.text).toLowerCase().trim();

                for (var t2 = 0; t2 < targets.length; t2++) {
                    var tk2 = targets[t2];
                    if (tk2.length < 3) continue;
                    if (cVarKey2 !== "" && cVarKey2.indexOf(tk2) !== -1) { matchedItem = it2; break; }
                    if (cLabel2 !== "" && cLabel2.indexOf(tk2) !== -1) { matchedItem = it2; break; }
                    if (cTitle2 !== "" && cTitle2.indexOf(tk2) !== -1) { matchedItem = it2; break; }
                    if (cText2 !== "" && cText2.indexOf(tk2) !== -1) { matchedItem = it2; break; }
                }
                if (matchedItem) break;
            }
        }

        if (matchedItem && typeof matchedItem.mapToItem === "function") {
            var mapPt = matchedItem.mapToItem(root.contentChild, 0, 0);
            var foundY = mapPt.y;

            var viewHeight = flickable.height > 0 ? flickable.height : 600;
            var contentH = Math.max(flickable.contentHeight || 0, root.contentChild?.implicitHeight || 0, root.contentChild?.height || 0);
            var minScroll = -flickable.topMargin;
            var maxScroll = Math.max(minScroll, contentH - viewHeight + flickable.bottomMargin);

            if (contentH + flickable.topMargin + flickable.bottomMargin <= viewHeight) {
                flickable.contentY = minScroll;
                rippleTimer.triggerFlash(matchedItem);
                return true;
            }

            var itemCenterY = foundY + (matchedItem.height > 0 ? matchedItem.height / 2 : 24);
            var idealScrollY = itemCenterY - (viewHeight / 2);
            var targetContentY = Math.max(minScroll, Math.min(maxScroll, idealScrollY));

            flickable.contentY = targetContentY;
            rippleTimer.triggerFlash(matchedItem);
            return true;
        }

        return false;
    }

    function scrollToItem(targetKey: string): void {
        scrollRetryTimer.startScroll(targetKey);
    }

    Timer {
        id: scrollRetryTimer
        interval: 60
        repeat: true
        property string targetKey: ""
        property int attempts: 0

        function startScroll(key) {
            targetKey = key;
            attempts = 0;
            restart();
        }

        onTriggered: {
            attempts++;
            var success = root.doScrollToItem(targetKey);
            if (success && attempts >= 2) {
                stop();
            } else if (attempts >= 10) {
                stop();
            }
        }
    }

    Timer {
        id: rippleTimer
        interval: 320
        repeat: true
        property var targetItem: null
        property int flashCount: 0
        property int maxFlashes: 3

        function triggerFlash(item) {
            targetItem = item;
            flashCount = 0;
            restart();
        }

        function findStateLayer(it) {
            if (!it) return null;
            if (it.stateLayer && typeof it.stateLayer.press === "function") return it.stateLayer;
            if (it.press !== undefined && typeof it.press === "function") return it;
            if (it.children) {
                for (var i = 0; i < it.children.length; i++) {
                    var found = findStateLayer(it.children[i]);
                    if (found) return found;
                }
            }
            return null;
        }

        onTriggered: {
            if (!targetItem) {
                stop();
                return;
            }
            var sl = findStateLayer(targetItem);
            if (sl && typeof sl.press === "function") {
                sl.press(targetItem.width / 2, targetItem.height / 2);
            }
            flashCount++;
            if (flashCount >= maxFlashes) {
                stop();
                targetItem = null;
            }
        }
    }

    Connections {
        target: root.nState
        function onScrollToRequested(target: string) {
            root.scrollToItem(target);
        }
    }

    Component.onCompleted: {
        if (root.nState.scrollToTarget !== "") {
            var tgt = root.nState.scrollToTarget;
            root.nState.scrollToTarget = "";
            root.scrollToItem(tgt);
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Tokens.spacing.extraLargeIncreased

        MouseArea {
            z: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.cappedWidth
            implicitWidth: root.cappedWidth
            implicitHeight: header.implicitHeight - Layout.bottomMargin
            Layout.bottomMargin: -flickable.topMargin
            onClicked: focus = true

            RowLayout {
                id: header
                anchors.fill: parent
                spacing: Tokens.spacing.largeIncreased

                Loader {
                    visible: active
                    active: root.isSubPage
                    asynchronous: true
                    sourceComponent: IconButton {
                        icon: "arrow_back"
                        font: Tokens.font.icon.medium
                        type: IconButton.Tonal
                        isRound: true
                        inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: root.nState.closeSubPage()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font: Tokens.font.title.large
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }
            }
        }

        VerticalFadeFlickable {
            id: flickable

            interactive: root.scrollable
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.topMargin: -topMargin
            topMargin: Tokens.padding.large
            bottomMargin: Tokens.padding.extraLarge

            contentHeight: root.scrollable ? (root.contentChild?.implicitHeight ?? 0) : height
            contentItem.children: [root.contentChild]

            Binding {
                target: root.contentChild
                property: "width"
                value: root.cappedWidth
            }

            Binding {
                target: root.contentChild ? root.contentChild.anchors : null
                property: "horizontalCenter"
                value: flickable.contentItem.horizontalCenter
            }

            Behavior on contentY {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            TapHandler {
                onTapped: flickable.focus = true
            }
        }
    }

    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 9999
    }
}
