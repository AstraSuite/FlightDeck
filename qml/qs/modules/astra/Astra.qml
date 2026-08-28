pragma ComponentBehavior: Bound

import QtQuick
import Helm.Blobs
import Helm.Config
import qs.components
import qs.components.controls
import qs.services
import QtQuick.Controls
import qs.modules.astra

Item {
    id: root

    readonly property AstraState nState: AstraState {
        id: nState

        onClose: root.close()
        onSubPageOpened: root.openSubPages++
        onSubPageClosed: root.openSubPages = Math.max(0, root.openSubPages - 1)
        onCurrentPageIdxChanged: root.openSubPages = 0
    }

    Shortcut {
        sequences: [StandardKey.Find, "Ctrl+F"]
        onActivated: nState.focusSearchRequested()
    }

    Shortcut {
        sequences: [StandardKey.Refresh, "Ctrl+R"]
        onActivated: nState.refreshRequested()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.openSubPages > 0
        onActivated: nState.closeSubPage()
    }

    Shortcut {
        sequences: ["Ctrl+1", "Ctrl+2", "Ctrl+3", "Ctrl+4", "Ctrl+5", "Ctrl+6"]
        onActivated: seq => {
            const index = parseInt(seq.toString().slice(-1), 10) - 1;
            if (index >= 0 && index < PageRegistry.pages.length)
                nState.currentPageIdx = index;
        }
    }
    property color blobColour: Colours.tPalette.m3surfaceContainerLow
    property int openSubPages: 0

    signal close

    implicitWidth: 1040
    implicitHeight: 680

    Component.onCompleted: {
        console.log("Astra blobColour:", root.blobColour);
        console.log("Colours.palette.m3surfaceContainerLow:", Colours.palette.m3surfaceContainerLow);
        console.log("Colours.tPalette.m3surfaceContainerLow:", Colours.tPalette.m3surfaceContainerLow);
    }

    Behavior on blobColour {
        CAnim {}
    }

    TapHandler {
        onTapped: root.focus = true
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.nState.isWindow ? 0 : Tokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
        implicitHeight: windowBtn.implicitHeight + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small)
    }

    IconButton {
        id: windowBtn

        anchors.centerIn: windowBtnRect
        icon: "close"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        onClicked: {
            root.close();
        }

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        nState: nState
        width: Math.min(Tokens.sizes.astra.maxNavWidth, Math.round(root.width / 3))
    }

    Pages {
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: Tokens.padding.extraLarge

        nState: nState
    }
}
