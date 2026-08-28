import QtQuick

ListView {
    id: root

    maximumFlickVelocity: 3000
    boundsBehavior: Flickable.DragAndOvershootBounds
    flickDeceleration: 1500
}
