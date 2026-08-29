pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra
import qs.modules.astra.common
import qs.modules.astra.navpane
import "."
import FlightDeck.Caelestia 1.0

VerticalFadeFlickable {
    id: root

    required property AstraState nState
    property string query: ""

    signal resultSelected(var item)

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: contentCol.implicitHeight

    function highlightMatch(text, q) {
        if (!text || !q) return text || "";
        var cleanQ = q.trim();
        if (cleanQ.length === 0) return text;
        var escaped = cleanQ.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        var regex = new RegExp("(" + escaped + ")", "gi");
        var pCol = Colours.palette.m3primary;
        return text.replace(regex, '<font color="' + pCol + '"><b>$1</b></font>');
    }

    readonly property var searchResults: {
        var q = root.query.trim().toLowerCase();
        if (q === "") return [];

        var registryItems = (typeof SettingsSearchRegistry !== "undefined" && SettingsSearchRegistry?.items) ? SettingsSearchRegistry.items : [];
        var terms = q.split(/\s+/).filter(t => t.length > 0);
        var matched = [];

        for (var i = 0; i < registryItems.length; i++) {
            var item = registryItems[i];
            var searchStr = (item.title + " " + item.subtext + " " + item.breadcrumb + " " + item.category + " " + (item.varKey || "")).toLowerCase();
            var allMatch = true;
            for (var t = 0; t < terms.length; t++) {
                if (searchStr.indexOf(terms[t]) === -1) {
                    allMatch = false;
                    break;
                }
            }
            if (allMatch) {
                matched.push(item);
            }
        }

        // Add grouping metadata
        var resultsWithGroup = [];
        for (var k = 0; k < matched.length; k++) {
            var curr = matched[k];
            var isStart = (k === 0) || (matched[k - 1].category !== curr.category);
            var isEnd = (k === matched.length - 1) || (matched[k + 1].category !== curr.category);
            resultsWithGroup.push({
                item: curr,
                isGroupStart: isStart,
                isGroupEnd: isEnd,
                showCategoryHeader: isStart
            });
        }
        return resultsWithGroup;
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        Repeater {
            model: root.searchResults

            delegate: ColumnLayout {
                id: rowCol
                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                // Category Section Header
                SectionHeader {
                    visible: rowCol.modelData.showCategoryHeader
                    first: rowCol.index === 0
                    text: rowCol.modelData.item.category
                }

                ConnectedRect {
                    id: card
                    Layout.fillWidth: true
                    implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2
                    first: rowCol.modelData.isGroupStart
                    last: rowCol.modelData.isGroupEnd

                    StateLayer {
                        id: stateLayer
                        anchors.fill: parent
                        z: 10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var itemData = rowCol.modelData.item;
                            root.nState.scrollToTarget = (itemData.varKey ? itemData.varKey + "|" : "") + (itemData.title || "");
                            root.nState.currentPageIdx = itemData.pageIdx;
                            if (itemData.subPageIdx !== undefined && itemData.subPageIdx > 0) {
                                root.nState.openSubPage(itemData.subPageIdx);
                            }
                            root.nState.scrollToRequested(root.nState.scrollToTarget);
                            root.resultSelected(itemData);
                        }
                    }

                    RowLayout {
                        id: cardLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        StyledRect {
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: rowCol.modelData.item.icon || "settings"
                                color: Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.small
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                visible: !!rowCol.modelData.item.breadcrumb
                                text: rowCol.modelData.item.breadcrumb
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.highlightMatch(rowCol.modelData.item.title, root.query)
                                textFormat: Text.RichText
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: !!rowCol.modelData.item.subtext
                                text: root.highlightMatch(rowCol.modelData.item.subtext, root.query)
                                textFormat: Text.RichText
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }

                        // Right control indicator
                        Loader {
                            active: rowCol.modelData.item.type === "toggle"
                            sourceComponent: StyledSwitch {
                                readonly property string vKey: rowCol.modelData.item.varKey || ""
                                checked: vKey ? (CaelestiaVars.currentVars[vKey] === "true" || CaelestiaVars.currentVars[vKey] === true) : true
                                onToggled: {
                                    if (vKey) {
                                        CaelestiaVars.setVar(vKey, checked);
                                    }
                                }
                            }
                        }

                        MaterialIcon {
                            visible: rowCol.modelData.item.type !== "toggle"
                            text: "arrow_forward"
                            color: Colours.palette.m3outlineVariant
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        // Empty search state
        Item {
            visible: root.query.trim().length > 0 && root.searchResults.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 120

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "search_off"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No settings found for \"%1\"").arg(root.query)
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.medium
                }
            }
        }
    }
}
