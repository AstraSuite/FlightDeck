pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Popup {
    id: root

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo
    property int attachSideX: Menu.Right
    property int attachSideY: root.opensUpward ? Menu.Top : Menu.Bottom
    property int thisSideX: Menu.Right
    property int thisSideY: root.opensUpward ? Menu.Bottom : Menu.Top
    property real marginX: 0
    property real marginY: 0

    // When true (default), the menu opens upward instead of downward when the
    // attached item runs out of room below it inside the window.
    property bool autoDirection: true
    // Force the menu to always open upward, regardless of available space.
    property bool forceUp: false
    property int __directionDirty: 0

    readonly property bool opensUpward: {
        root.__directionDirty;
        if (root.forceUp) return true;
        if (!root.autoDirection) return false;
        const btn = root.attachTo;
        if (!btn || !btn.window || !btn.window.contentItem) return false;
        const content = btn.window.contentItem;
        if (content.height <= 0) return false;
        const anchor = btn.mapToItem(content, 0, 0);
        if (anchor === null || anchor === undefined) return false;
        const below = content.height - (anchor.y + btn.height);
        return below < anchor.y;
    }

    property list<MenuItem> items
    property MenuItem active: items.length > 0 ? items[0] : null
    property bool expanded: visible
    property real maxHeight: 320

    signal itemSelected(item: MenuItem)

    parent: root.attachTo
    x: {
        if (!root.attachTo) return 0;
        let anchorX = root.attachSideX === Menu.Left ? 0 : root.attachTo.width;
        let selfOffset = root.thisSideX === Menu.Right ? -width : 0;
        return anchorX + selfOffset + root.marginX;
    }
    y: {
        if (!root.attachTo) return 0;
        let anchorY = root.attachSideY === Menu.Top ? 0 : root.attachTo.height;
        let selfOffset = root.thisSideY === Menu.Bottom ? -height : 0;
        return anchorY + selfOffset + root.marginY;
    }

    implicitWidth: menuContainer.implicitWidth
    implicitHeight: menuContainer.implicitHeight

    padding: 0
    margins: 0
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 140; easing.type: Easing.InCubic }
    }

    onOpened: root.expanded = true
    onClosed: root.expanded = false
    onExpandedChanged: {
        if (root.expanded && !root.visible) {
            root.__directionDirty++;
            root.open();
        } else if (!root.expanded && root.visible) {
            root.close();
        }
    }

    background: Item {}

    contentItem: Elevation {
        id: menuContainer

        radius: Tokens.rounding.large
        level: 2

        implicitWidth: Math.max(200, column.implicitWidth + Tokens.padding.extraSmall * 2)
        implicitHeight: Math.min(root.maxHeight, column.implicitHeight + Tokens.padding.extraSmall * 2)

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menuContainer.height : 0

            Behavior on yScale {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            Flickable {
                id: flickable

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true

                interactive: contentHeight > height

                ColumnLayout {
                    id: column

                    width: parent.width
                    spacing: 0

                    Repeater {
                        id: repeater

                        model: root.items

                        StyledRect {
                            id: item

                            required property int index
                            required property MenuItem modelData
                            readonly property bool active: modelData === root?.active

                            Layout.fillWidth: true
                            implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                            radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                            topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                            topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                            bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                            bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                            color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                            Behavior on radius {
                                Anim {}
                            }

                            Behavior on color {
                                CAnim {}
                            }

                            StateLayer {
                                topLeftRadius: parent.topLeftRadius
                                topRightRadius: parent.topRightRadius
                                bottomLeftRadius: parent.bottomLeftRadius
                                bottomRightRadius: parent.bottomRightRadius

                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                onClicked: {
                                    root.itemSelected(item.modelData);
                                    root.active = item.modelData;
                                    if (item.modelData) {
                                        item.modelData.clicked();
                                    }
                                    root.close();
                                }
                            }

                            RowLayout {
                                id: menuOptionRow

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.small

                                StyledRect {
                                    id: menuColorSwatch
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: item.modelData && item.modelData.previewColor !== undefined && item.modelData.previewColor !== Qt.rgba(0,0,0,0) && String(item.modelData.previewColor) !== "#00000000" && String(item.modelData.previewColor) !== "transparent"
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: Tokens.rounding.full
                                    border.width: 1.5
                                    border.color: Colours.palette.m3outline
                                    color: item.modelData ? (item.modelData.previewColor || "transparent") : "transparent"
                                }

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: !menuColorSwatch.visible && item.modelData && item.modelData.icon !== ""
                                    text: item.modelData ? item.modelData.icon : ""
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    text: item.modelData ? item.modelData.text : ""
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                }

                                Loader {
                                    asynchronous: true
                                    Layout.alignment: Qt.AlignVCenter
                                    active: item.modelData && item.modelData.trailingIcon && item.modelData.trailingIcon.length > 0
                                    visible: active

                                    sourceComponent: MaterialIcon {
                                        text: item.modelData ? item.modelData.trailingIcon : ""
                                        color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
