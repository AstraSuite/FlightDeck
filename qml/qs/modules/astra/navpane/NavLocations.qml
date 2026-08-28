pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.astra

VerticalFadeFlickable {
    id: root

    required property AstraState nState

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    TapHandler {
        onTapped: root.focus = true
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: list

            model: {
                const arr = [];
                for (let i = 0; i < PageRegistry.pages.length; i++) {
                    const page = PageRegistry.pages[i];
                    if (!page.developerOnly || GlobalConfig.general.developerMode) {
                        arr.push({
                            originalIndex: i,
                            label: page.label,
                            icon: page.icon,
                            description: page.description,
                            category: page.category,
                            noFill: page.noFill ?? false
                        });
                    }
                }
                return arr;
            }

            StyledRect {
                id: item

                required property var modelData
                required property int index

                clip: true

                readonly property bool isCurrentPage: modelData.originalIndex === root.nState.currentPageIdx
                readonly property bool isCategoryStart: index === 0 || list.model[index - 1].category !== modelData.category
                readonly property bool isCategoryEnd: index === list.model.length - 1 || list.model[index + 1].category !== modelData.category

                property real animHeight: 1
                property real animSlide: 1
                property bool isUnlocking: false

                Component.onCompleted: {
                    if (modelData.originalIndex === 2 && root.nState.justUnlockedDevMode) {
                        animHeight = 0;
                        animSlide = 0;
                        heightAnim.start();
                        slideAnim.start();
                        isUnlocking = true;
                        unlockTimer.start();
                    } else if (modelData.originalIndex === 1 && root.nState.justUnlockedDevMode) {
                        isUnlocking = true;
                        unlockTimer.start();
                    }
                }

                Timer {
                    id: unlockTimer
                    interval: 20
                    onTriggered: item.isUnlocking = false
                }

                NumberAnimation {
                    id: heightAnim
                    target: item
                    property: "animHeight"
                    to: 1
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                    onFinished: root.nState.justUnlockedDevMode = false
                }

                NumberAnimation {
                    id: slideAnim
                    target: item
                    property: "animSlide"
                    to: 1
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                Layout.fillWidth: true
                Layout.topMargin: (index !== 0 && isCategoryStart ? Tokens.spacing.medium : 0) * animHeight
                implicitHeight: {
                    const h = layout.implicitHeight + layout.anchors.margins * 2;
                    const targetH = h % 2 === 0 ? h : h + 1;
                    return targetH * animHeight;
                }
                opacity: modelData.originalIndex === 2 ? animSlide : 1.0

                transform: Translate {
                    y: modelData.originalIndex === 2 ? (1 - item.animSlide) * -40 : 0
                }

                color: isCurrentPage ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

                topLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && modelData.originalIndex === 2) ? Tokens.rounding.extraLarge : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                topRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && modelData.originalIndex === 2) ? Tokens.rounding.extraLarge : isCategoryStart ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomLeftRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && modelData.originalIndex === 1) ? Tokens.rounding.extraLarge : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
                bottomRightRadius: stateLayer.pressed ? Tokens.rounding.medium : isCurrentPage ? Tokens.rounding.extraLargeIncreased : (isUnlocking && modelData.originalIndex === 1) ? Tokens.rounding.extraLarge : isCategoryEnd ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall

                RadiusBehavior on topLeftRadius {}
                RadiusBehavior on topRightRadius {}
                RadiusBehavior on bottomLeftRadius {}
                RadiusBehavior on bottomRightRadius {}

                StateLayer {
                    id: stateLayer

                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius

                    onClicked: root.nState.currentPageIdx = item.modelData.originalIndex
                }

                RowLayout {
                    id: layout

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    opacity: modelData.originalIndex === 2 ? item.animSlide : 1.0

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: -1
                        Layout.bottomMargin: -1
                        implicitWidth: height

                        radius: Tokens.rounding.full
                        color: item.isCurrentPage ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1

                            text: item.modelData.icon
                            color: item.isCurrentPage ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                            grade: 25
                            fill: item.modelData.noFill ? 0 : 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.label
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.description
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
