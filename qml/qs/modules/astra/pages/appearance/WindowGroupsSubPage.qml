pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Window groups & tabs")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Group Tabs (Groupbar)")
        }

        ToggleRow {
            first: true
            varKey: "groupbarEnabled"
            text: qsTr("Enable Groupbar Tabs")
            subtext: qsTr("Render visual tab bar headers above grouped windows")
        }

        ToggleRow {
            varKey: "groupbarRenderTitles"
            text: qsTr("Render Window Titles in Tabs")
            subtext: qsTr("Display application and window titles on tab indicators")
        }

        ToggleRow {
            varKey: "groupbarGradients"
            text: qsTr("Tabbar Gradients")
            subtext: qsTr("Draw smooth accent gradient lighting on active group tabs")
        }

        ToggleRow {
            varKey: "groupbarStacked"
            text: qsTr("Stacked Vertical Tabs")
            subtext: qsTr("Render tabs vertically stacked instead of side-by-side horizontal tabs")
        }

        ToggleRow {
            last: true
            varKey: "groupbarScrolling"
            text: qsTr("Scroll Wheel Tab Switching")
            subtext: qsTr("Switch active tab using mouse wheel scroll over the groupbar")
        }

        SectionHeader {
            text: qsTr("Tab Dimensions")
        }

        SliderRow {
            first: true
            varKey: "groupbarHeight"
            label: qsTr("Groupbar Height")
            subtext: qsTr("Height of the window tab header bar in pixels")
            valueLabel: Math.round(value) + " px"
            from: 8
            to: 40
            stepSize: 1
        }

        SliderRow {
            last: true
            varKey: "groupbarIndicatorHeight"
            label: qsTr("Active Indicator Height")
            subtext: qsTr("Thickness of the active tab highlight strip in pixels")
            valueLabel: Math.round(value) + " px"
            from: 1
            to: 10
            stepSize: 1
        }

        SectionHeader {
            text: qsTr("Group Spawning & Dragging")
        }

        ToggleRow {
            first: true
            varKey: "groupInsertAfterCurrent"
            text: qsTr("Insert After Active Window")
            subtext: qsTr("Spawn new windows directly next to the active tab rather than at the group tail")
        }

        ToggleRow {
            varKey: "groupFocusRemovedWindow"
            text: qsTr("Focus Removed Window")
            subtext: qsTr("Automatically focus a window when it is dragged out of the group")
        }

        ToggleRow {
            last: true
            varKey: "groupMergeGroupsOnDrag"
            text: qsTr("Merge Groups On Drag")
            subtext: qsTr("Combine two separate window groups into one when dragging onto another group")
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
