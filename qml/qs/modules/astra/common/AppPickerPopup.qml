pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import FlightDeck.Managers 1.0

BlobPopup {
    id: root

    signal appSelected(string exec, string name, string icon)

    property string searchQuery: ""

    icon: "search"
    padding: Tokens.padding?.medium ?? 12
    topMovement: Tokens.padding?.large ?? 16
    bottomMovement: Tokens.padding?.large ?? 16
    implicitWidth: 36
    implicitHeight: 36
    color: open || hovered ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

    onOpenChanged: {
        if (open) {
            searchQuery = "";
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    content: Item {
        id: contentWrapper
        anchors.centerIn: parent
        implicitWidth: 360
        implicitHeight: Math.max(200, Math.min(450, (root.rootParent ? root.rootParent.height : 450) - 100))

        ColumnLayout {
            anchors.centerIn: parent
            width: contentWrapper.implicitWidth
            height: contentWrapper.implicitHeight
            spacing: Tokens.spacing?.medium ?? 12

            SearchBar {
                id: searchField
                bg.color: Colours.palette.m3surfaceContainerHighest
                bg.border.color: Colours.palette.m3outlineVariant
                searchIcon.fontStyle: Tokens.font?.icon?.medium ?? null
                clearIcon.font: Tokens.font?.icon?.medium ?? null
                Layout.fillWidth: true
                placeholderText: qsTr("Filter apps...")
                onTextChanged: root.searchQuery = text
            }

            VerticalFadeListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                
                model: {
                    var q = root.searchQuery.toLowerCase().trim();
                    var all = AutostartManager.availableApps || [];
                    if (!q) return all;
                    return all.filter(a => {
                        return (a.name && a.name.toLowerCase().includes(q)) ||
                               (a.exec && a.exec.toLowerCase().includes(q)) ||
                               (a.comment && a.comment.toLowerCase().includes(q));
                    });
                }

                delegate: Item {
                    id: appItem

                    required property var modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: list.contentItem.left
                    anchors.right: list.contentItem.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2

                    StateLayer {
                        radius: Tokens.rounding?.small ?? 8

                        onClicked: {
                            root.open = false;
                            if (appItem.modelData) {
                                root.appSelected(appItem.modelData.exec || "", appItem.modelData.name || "", appItem.modelData.icon || "");
                            }
                        }

                        RowLayout {
                            id: itemLayout

                            anchors.fill: parent
                            anchors.margins: Tokens.padding?.medium ?? 12
                            spacing: Tokens.spacing?.medium ?? 12

                            Image {
                                source: (appItem.modelData && appItem.modelData.icon) ? "image://icon/" + appItem.modelData.icon : ""
                                sourceSize.width: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                sourceSize.height: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                Layout.preferredWidth: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                Layout.preferredHeight: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: appItem.modelData && appItem.modelData.icon !== ""
                            }

                            MaterialIcon {
                                visible: !appItem.modelData || !appItem.modelData.icon
                                text: "apps"
                                fontStyle: Tokens.font?.icon?.medium ?? null
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: appItem.modelData ? appItem.modelData.name : ""
                                    font: Tokens.font?.body?.small ?? null
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text
                                    text: appItem.modelData ? (appItem.modelData.comment || appItem.modelData.exec) : ""
                                    color: Colours.palette.m3outline
                                    font: Tokens.font?.label?.small ?? null
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
