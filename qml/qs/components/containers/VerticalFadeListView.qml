import QtQuick
import qs.components

StyledListView {
    id: root

    clip: true
    flickableDirection: Flickable.VerticalFlick
    orientation: ListView.Vertical
    boundsBehavior: Flickable.DragAndOvershootBounds
}
