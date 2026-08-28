import QtQuick
import QtQuick.Layouts
import FlightDeck.Blobs
import FlightDeck.Config
import qs.components
import qs.services

Item {
    id: rootPlaceholder

    property string icon: ""
    property alias color: blobGroup.color
    readonly property alias hovered: btn.containsMouse
    property bool open
    property int padding: Tokens.padding?.medium ?? 12
    property int topMovement: Tokens.padding?.large ?? 16
    property int bottomMovement: Tokens.padding?.large ?? 16
    property bool pressOverride
    property bool hoverOverride
    property real animDriver
    property Item rootParent: null
    default required property Item content

    readonly property bool expandingUp: popupItem.expandUp
    readonly property bool expandingLeft: popupItem.expandLeft

    implicitWidth: 36
    implicitHeight: 36

    onOpenChanged: {
        if (open && rootParent) {
            let pos = mapToItem(rootParent, 0, 0);
            popupItem.expandLeft = pos.x > rootParent.width / 2;
            popupItem.expandUp = pos.y > rootParent.height / 2;
        }
    }

    MouseArea {
        id: backdrop
        parent: (rootPlaceholder.open && rootPlaceholder.rootParent) ? rootPlaceholder.rootParent : rootPlaceholder
        anchors.fill: parent
        enabled: rootPlaceholder.open
        hoverEnabled: enabled
        onClicked: rootPlaceholder.open = false
        z: 99
    }

    Item {
        id: popupItem
        z: 100
        
        width: rootPlaceholder.width
        height: rootPlaceholder.height

        property bool expandLeft: false
        property bool expandUp: false
        
        function reparentPopup(): void {
            const newParent = (rootPlaceholder.open && rootPlaceholder.rootParent) ? rootPlaceholder.rootParent : rootPlaceholder;
            if (!newParent) return;
            const pos = rootPlaceholder.mapToItem(newParent, 0, 0);
            
            expandLeft = pos.x > newParent.width / 2;
            expandUp = pos.y > newParent.height / 2;

            popupItem.parent = newParent;
            popupItem.x = pos.x;
            popupItem.y = pos.y;
        }
        
        onParentChanged: {
            if (parent === rootPlaceholder) {
                x = 0;
                y = 0;
            }
        }

        states: State {
            name: "open"
            when: rootPlaceholder.open

            PropertyChanges {
                popupItem.x: rootPlaceholder.rootParent ? rootPlaceholder.mapToItem(rootPlaceholder.rootParent, 0, 0).x : 0
                popupItem.y: rootPlaceholder.rootParent ? rootPlaceholder.mapToItem(rootPlaceholder.rootParent, 0, 0).y : 0
            }
        }

        transitions: Transition {
            SequentialAnimation {
                ScriptAction {
                    script: popupItem.reparentPopup()
                }
                Anim {
                    properties: "x,y"
                }
            }
        }

        Binding {
            target: rootPlaceholder.content
            property: "opacity"
            value: rootPlaceholder.animDriver
        }

        BlobGroup {
            id: blobGroup

            color: Colours.palette.m3surfaceContainerHighest
            smoothing: Tokens.rounding?.medium ?? 12
            cornerFill: false

            Behavior on color {
                CAnim {}
            }
        }

        BlobRect {
            id: btnRect

            anchors.fill: parent
            anchors.margins: (!(btn.pressed || rootPlaceholder.pressOverride) && (btn.containsMouse || rootPlaceholder.hoverOverride) ? -(Tokens.padding?.extraSmall ?? 4) : 0) + (rootPlaceholder.open ? -(Tokens.padding?.extraSmall ?? 4) : 0)
            group: blobGroup
            radius: rootPlaceholder.open ? (Tokens.rounding?.large ?? 16) : (Tokens.rounding?.medium ?? 12)

            Behavior on anchors.margins {
                Anim {}
            }

            Behavior on radius {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        BlobRect {
            id: rect
            
            x: 0
            y: 0
            width: parent.width
            height: parent.height

            group: blobGroup
            radius: Tokens.rounding?.large ?? 16
            deformScale: 0.00001

            states: State {
                name: "open"
                when: rootPlaceholder.open

                PropertyChanges {
                    target: rect
                    width: rootPlaceholder.content.implicitWidth + rootPlaceholder.padding * 2
                    height: rootPlaceholder.content.implicitHeight + rootPlaceholder.padding * 2
                    x: popupItem.expandLeft ? (Tokens.spacing?.small ?? 8) - width : popupItem.width - (Tokens.spacing?.small ?? 8)
                    y: popupItem.expandUp ? popupItem.height + rootPlaceholder.bottomMovement - height : -rootPlaceholder.topMovement
                }
                PropertyChanges {
                    target: rootPlaceholder
                    animDriver: 1
                }
            }

            transitions: Transition {
                Anim {
                    properties: "x,width"
                }
                Anim {
                    properties: "y,height"
                    easing: Tokens.anim?.expressiveFastSpatial ?? Easing.OutCubic
                }
                Anim {
                    property: "animDriver"
                    type: Anim.DefaultEffects
                }
            }

            MouseArea {
                anchors.fill: parent
                clip: true
                children: [rootPlaceholder.content]
            }
        }

        MouseArea {
            id: btn

            anchors.centerIn: parent
            implicitWidth: 36
            implicitHeight: 36
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: rootPlaceholder.open = !rootPlaceholder.open

            MaterialIcon {
                id: iconItem

                anchors.centerIn: parent
                text: rootPlaceholder.icon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font?.icon?.medium ?? null
            }
        }
    }
}
