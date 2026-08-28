pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import FlightDeck.Caelestia 1.0

BlobPopup {
    id: root

    signal clientSelected(string winClass, string winTitle, string initialClass, string initialTitle)

    property string searchQuery: ""
    property var clientsList: []

    icon: "search"
    padding: Tokens.padding?.medium ?? 12
    topMovement: Tokens.padding?.large ?? 16
    bottomMovement: Tokens.padding?.large ?? 16
    implicitWidth: 36
    implicitHeight: 36
    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.minimumWidth: 36
    Layout.maximumWidth: 36
    color: open || hovered ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

    onOpenChanged: {
        if (open) {
            searchQuery = "";
            clientsList = FlightDeckWriter.activeHyprlandClients();
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
                placeholderText: qsTr("Filter open windows...")
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
                    var all = root.clientsList || [];
                    if (!q) return all;
                    return all.filter(c => {
                        return (c.class && c.class.toLowerCase().includes(q)) ||
                               (c.title && c.title.toLowerCase().includes(q)) ||
                               (c.initialClass && c.initialClass.toLowerCase().includes(q));
                    });
                }

                delegate: Item {
                    id: clientItem

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
                            if (clientItem.modelData) {
                                var winClass = clientItem.modelData.class || "";
                                var winTitle = clientItem.modelData.title || "";
                                var initClass = clientItem.modelData.initialClass || winClass;
                                var initTitle = clientItem.modelData.initialTitle || winTitle;
                                root.clientSelected(winClass, winTitle, initClass, initTitle);
                            }
                        }

                        RowLayout {
                            id: itemLayout

                            anchors.fill: parent
                            anchors.margins: Tokens.padding?.medium ?? 12
                            spacing: Tokens.spacing?.medium ?? 12

                            Image {
                                id: appIconImg
                                source: {
                                    var c = clientItem.modelData;
                                    if (!c) return "";
                                    var iconName = c.initialClass || c.class || "";
                                    return iconName ? ("image://icon/" + iconName) : "";
                                }
                                sourceSize.width: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                sourceSize.height: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                Layout.preferredWidth: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                Layout.preferredHeight: Math.round((Tokens.font?.icon?.large?.pointSize ?? 18) * 1.8)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            MaterialIcon {
                                visible: !appIconImg.visible
                                text: "web_asset"
                                fontStyle: Tokens.font?.icon?.medium ?? null
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: clientItem.modelData ? (clientItem.modelData.class || qsTr("Unknown")) : ""
                                    font: Tokens.font?.body?.small ?? null
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: clientItem.modelData ? (clientItem.modelData.title || "") : ""
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
