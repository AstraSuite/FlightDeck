pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Helm.Blobs
import Helm.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    property Item rootParent: null
    property bool first: false
    property bool last: false
    property string icon: "add"
    property string label: qsTr("Add Entry")
    property string header: qsTr("Add New Entry")
    property Component content: null
    property string acceptLabel: qsTr("Add")
    property bool acceptAllowed: true
    property bool separateContent: false
    property int horizontalContentMargin: 0

    property real openWidth: 540
    property real openHeight: 480
    property bool open: false

    signal accepted()
    signal cancelled()

    function getTargetParent(): Item {
        if (rootParent) return rootParent.modalOverlay ? rootParent.modalOverlay : rootParent;
        let p = root.parent;
        while (p) {
            if (p.modalOverlay) return p.modalOverlay;
            p = p.parent;
        }
        return root.Window.contentItem ? root.Window.contentItem : root;
    }

    onOpenChanged: {
        if (open) {
            modalWrapper.parent = getTargetParent();
        } else {
            modalWrapper.parent = root;
        }
    }

    Layout.fillWidth: true
    implicitHeight: openButton.implicitHeight

    ButtonRow {
        id: openButton
        anchors.fill: parent
        first: root.first
        last: root.last
        icon: root.icon
        text: root.label
        onClicked: root.open = true
    }

    // Modal Wrapper (reparented into page overlayLayer on open)
    Item {
        id: modalWrapper
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.open ? 1.0 : 0.0
        z: 99999

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }

        // Dimmed backdrop scrim
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.cancelled();
                    root.open = false;
                }
            }
        }

        // Dialog Card
        StyledRect {
            id: dialogCard
            anchors.centerIn: parent
            width: Math.min(root.openWidth, parent.width - 40)
            height: Math.min(root.openHeight, parent.height - 40)
            radius: Tokens.rounding.extraLargeIncreased
            color: Colours.palette.m3surfaceContainerHighest
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            scale: root.open ? 1.0 : 0.92

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
            }

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside dialog card
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraLarge
                anchors.bottomMargin: Tokens.padding.largeIncreased
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: root.header
                        font: Tokens.font.title.medium
                        color: Colours.palette.m3onSurface
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: "close"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: {
                            root.cancelled();
                            root.open = false;
                        }
                    }
                }

                Loader {
                    Layout.topMargin: Tokens.spacing.medium
                    Layout.fillWidth: true
                    active: root.separateContent
                    visible: active
                    sourceComponent: StyledRect {
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Tokens.spacing.small
                    Layout.bottomMargin: Tokens.spacing.small
                    Layout.leftMargin: root.horizontalContentMargin
                    Layout.rightMargin: root.horizontalContentMargin
                    active: root.open
                    sourceComponent: root.content
                }

                Loader {
                    Layout.bottomMargin: Tokens.spacing.medium
                    Layout.fillWidth: true
                    active: root.separateContent
                    visible: active
                    sourceComponent: StyledRect {
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.small

                    TextButton {
                        type: TextButton.Text
                        isRound: true
                        horizontalPadding: Tokens.padding.largeIncreased
                        verticalPadding: Tokens.padding.medium
                        text: qsTr("Cancel")
                        onClicked: {
                            root.cancelled();
                            root.open = false;
                        }
                    }

                    TextButton {
                        type: TextButton.Filled
                        isRound: true
                        horizontalPadding: Tokens.padding.largeIncreased
                        verticalPadding: Tokens.padding.medium
                        disabled: !root.acceptAllowed
                        text: root.acceptLabel
                        onClicked: {
                            root.accepted();
                            root.open = false;
                        }
                    }
                }
            }
        }
    }
}
