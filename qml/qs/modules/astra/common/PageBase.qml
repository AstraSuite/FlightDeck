pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Helm.Config
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

    function scrollToItem(targetKey: string): void {
        if (!root.contentChild || !targetKey) return;
        var foundY = -1;
        var matchedItem = null;

        function searchChildren(parentItem) {
            if (!parentItem || !parentItem.children) return;
            for (var i = 0; i < parentItem.children.length; i++) {
                var child = parentItem.children[i];
                if (!child) continue;
                var match = false;
                if (child.title && child.title.toLowerCase().indexOf(targetKey.toLowerCase()) !== -1) match = true;
                if (child.text && child.text.toLowerCase().indexOf(targetKey.toLowerCase()) !== -1) match = true;
                if (child.varKey && child.varKey.toLowerCase() === targetKey.toLowerCase()) match = true;
                if (match) {
                    var mapPt = child.mapToItem(root.contentChild, 0, 0);
                    foundY = mapPt.y;
                    matchedItem = child;
                    return;
                }
                searchChildren(child);
                if (foundY !== -1) return;
            }
        }

        searchChildren(root.contentChild);

        if (foundY >= 0) {
            flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, foundY - Tokens.padding.large));

            if (matchedItem) {
                rippleTimer.targetItem = matchedItem;
                rippleTimer.restart();
            }
        }
    }

    Timer {
        id: rippleTimer
        interval: 220
        repeat: false
        property var targetItem: null
        onTriggered: {
            if (!targetItem) return;
            var sl = targetItem.stateLayer;
            if (!sl) {
                for (var i = 0; i < targetItem.children.length; i++) {
                    var c = targetItem.children[i];
                    if (c && c.press !== undefined) {
                        sl = c;
                        break;
                    }
                }
            }
            if (sl && sl.press) {
                sl.press(targetItem.width / 2, targetItem.height / 2);
            }
            targetItem = null;
        }
    }

    Connections {
        target: root.nState
        function onScrollToRequested(target: string) {
            Qt.callLater(() => root.scrollToItem(target));
        }
    }

    Component.onCompleted: {
        if (root.nState.scrollToTarget !== "") {
            Qt.callLater(() => {
                root.scrollToItem(root.nState.scrollToTarget);
                root.nState.scrollToTarget = "";
            });
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Tokens.spacing.extraLargeIncreased

        MouseArea {
            z: 1
            implicitWidth: header.implicitWidth
            implicitHeight: header.implicitHeight - Layout.bottomMargin
            Layout.bottomMargin: -flickable.topMargin
            onClicked: focus = true

            RowLayout {
                id: header

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
