pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Blobs
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.astra.common

Item {
    id: root

    required property Item rootParent
    required property string icon
    required property string label
    required property string header
    required property Component content
    required property string acceptLabel
    property string subtext: ""
    property string varKey: ""
    property bool showReset: false
    property Component trailingActions: null
    property bool first: false
    property bool last: false
    property bool acceptAllowed: true
    property bool openAllowed: true
    property bool rowDisabled: false
    property bool separateContent
    property int horizontalContentMargin: 0
    property real customOpenHeight: 0
    property real openWidth: Math.min((rootParent ? rootParent.width : 600) * 0.9, Tokens.sizes?.astra?.maxDialogWidth ?? 580)
    property real maxOpenHeight: Math.min((rootParent ? rootParent.height : 600) * 0.88, Tokens.sizes?.astra?.maxDialogHeight ?? 650)
    property real openHeight: {
        if (customOpenHeight > 0) {
            return Math.min(customOpenHeight, maxOpenHeight);
        }
        if (separateContent) {
            return Math.min(500, maxOpenHeight);
        }
        if (dialogContent && dialogContent.item && dialogContent.item.dialogLayout) {
            var layoutH = dialogContent.item.dialogLayout.implicitHeight;
            if (layoutH > 0) {
                var contentH = layoutH + (Tokens.padding?.extraLarge ?? 28) + (Tokens.padding?.largeIncreased ?? 20);
                return Math.min(Math.max(280, contentH), maxOpenHeight);
            }
        }
        return Math.min(500, maxOpenHeight);
    }
    property bool open

    signal accepted
    signal cancelled
    signal reset

    function reparentWrapper(): void {
        const newParent = (open && rootParent) ? rootParent : root;
        if (!newParent || !dialogWrapper) return;
        const pos = dialogWrapper.mapToItem(newParent, 0, 0);
        dialogWrapper.parent = newParent;
        dialogWrapper.x = pos.x;
        dialogWrapper.y = pos.y;
    }

    Layout.fillWidth: true
    implicitHeight: openButton.implicitHeight
    z: open || dialogTransition.running ? 2 : 0

    BlobGroup {
        id: blobGroup

        color: root.open ? Colours.palette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }
    }

    MouseArea {
        id: backdrop

        anchors.fill: parent
        parent: (root.open && root.rootParent) ? root.rootParent : root
        enabled: false
        hoverEnabled: enabled
        onClicked: root.open = false
    }

    Item {
        id: dialogWrapper

        z: 1
        width: root.width
        height: openButton.implicitHeight

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                backdrop.enabled: true
                elevation.opacity: 1
                openButton.opacity: 0
                dialogContent.opacity: 1
                dialogBg.radius: Tokens.rounding?.extraLargeIncreased ?? 32
                dialogBg.topLeftRadius: Tokens.rounding?.extraLargeIncreased ?? 32
                dialogBg.topRightRadius: Tokens.rounding?.extraLargeIncreased ?? 32
                dialogBg.bottomLeftRadius: Tokens.rounding?.extraLargeIncreased ?? 32
                dialogBg.bottomRightRadius: Tokens.rounding?.extraLargeIncreased ?? 32
                dialogWrapper.x: root.rootParent ? (root.rootParent.width - root.openWidth) / 2 : 0
                dialogWrapper.y: root.rootParent ? (root.rootParent.height - root.openHeight) / 2 : 0
                dialogWrapper.width: root.openWidth
                dialogWrapper.height: root.openHeight
            }
        }

        transitions: Transition {
            id: dialogTransition

            SequentialAnimation {
                ScriptAction {
                    script: root.reparentWrapper()
                }
                Anim {
                    properties: "x,y"
                }
            }
            PropertyAction {
                property: "enabled"
            }
            Anim {
                properties: "opacity,radius,topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                type: Anim.DefaultEffects
            }
            Anim {
                properties: "width,height"
            }
        }

        Elevation {
            id: elevation

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent
            radius: dialogBg.radius
            topLeftRadius: dialogBg.topLeftRadius
            topRightRadius: dialogBg.topRightRadius
            bottomLeftRadius: dialogBg.bottomLeftRadius
            bottomRightRadius: dialogBg.bottomRightRadius
            level: 4
            opacity: 0
        }

        BlobRect {
            id: dialogBg

            anchors.fill: parent

            deformScale: 0.00005
            group: blobGroup
            opacity: blobGroup.color.a

            radius: Tokens.rounding?.extraSmall ?? 4
            topLeftRadius: root.first ? (Tokens.rounding?.extraLarge ?? 28) : (Tokens.rounding?.extraSmall ?? 4)
            topRightRadius: root.first ? (Tokens.rounding?.extraLarge ?? 28) : (Tokens.rounding?.extraSmall ?? 4)
            bottomLeftRadius: root.last ? (Tokens.rounding?.extraLarge ?? 28) : (Tokens.rounding?.extraSmall ?? 4)
            bottomRightRadius: root.last ? (Tokens.rounding?.extraLarge ?? 28) : (Tokens.rounding?.extraSmall ?? 4)
        }

        RowButton {
            id: openButton

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(implicitHeight, parent.height) // Clamp to parent height due to overshoot anim
            color: "transparent"

            first: root.first
            last: root.last
            icon: root.icon
            text: root.label
            subtext: root.subtext
            varKey: root.varKey
            showReset: root.showReset
            onReset: root.reset()
            trailingActions: root.trailingActions
            disabled: root.rowDisabled
            onClicked: {
                if (root.openAllowed) {
                    root.open = true;
                }
            }
        }

        Loader {
            id: dialogContent

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent

            opacity: 0
            active: root.open || opacity > 0
            asynchronous: false

            sourceComponent: MouseArea {
                id: contentMouseArea
                property var host: root
                readonly property alias dialogLayout: dialogLayout

                onWheel: event => event.accepted = true

                ColumnLayout {
                    id: dialogLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding?.extraLarge ?? 28
                    anchors.bottomMargin: Tokens.padding?.largeIncreased ?? 20
                    spacing: 0

                    StyledText {
                        text: contentMouseArea.host.header
                        font: Tokens.font.title.builders.large.weight(Font.Normal).build()
                    }

                    Loader {
                        Layout.topMargin: Tokens.spacing?.medium ?? 12
                        Layout.fillWidth: true
                        active: contentMouseArea.host.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: contentMouseArea.host.horizontalContentMargin
                        Layout.rightMargin: contentMouseArea.host.horizontalContentMargin
                        sourceComponent: contentMouseArea.host.content
                    }

                    Loader {
                        Layout.bottomMargin: Tokens.spacing?.medium ?? 12
                        Layout.fillWidth: true
                        active: contentMouseArea.host.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Tokens.spacing?.extraSmall ?? 4

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding?.largeIncreased ?? 20
                            verticalPadding: Tokens.padding?.medium ?? 12
                            text: qsTr("Cancel")
                            onClicked: {
                                contentMouseArea.host.cancelled();
                                contentMouseArea.host.open = false;
                            }
                        }

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding?.largeIncreased ?? 20
                            verticalPadding: Tokens.padding?.medium ?? 12
                            disabled: !contentMouseArea.host.acceptAllowed
                            text: contentMouseArea.host.acceptLabel
                            onClicked: {
                                contentMouseArea.host.accepted();
                                contentMouseArea.host.open = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
