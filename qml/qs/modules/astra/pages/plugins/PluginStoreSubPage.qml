pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common
import FlightDeck.Managers 1.0

PageBase {
    id: root

    title: qsTr("Plugin Store")
    isSubPage: true

    property string searchQuery: ""
    property int selectedFilter: 0 // 0: All, 1: Installed, 2: Available
    property bool showCustomDialog: false
    property bool showConsole: false

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.medium

        CustomRepoDialog {
            id: customDialog
            visible: root.showCustomDialog
            onClosed: root.showCustomDialog = false
        }

        // Top Store Toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                Layout.fillWidth: true
                placeholderText: qsTr("Search plugins by name, description, author...")
                text: root.searchQuery
                onTextEdited: root.searchQuery = text
            }

            TextButton {
                type: TextButton.Filled
                text: qsTr("Update All")
                enabled: !HyprpmManager.isBusy
                onClicked: {
                    root.showConsole = true;
                    HyprpmManager.updateAll(true);
                }
            }

            TextButton {
                type: TextButton.Outlined
                text: qsTr("Reload")
                enabled: !HyprpmManager.isBusy
                onClicked: HyprpmManager.reloadPlugins()
            }

            TextButton {
                type: TextButton.Outlined
                text: qsTr("Add Custom")
                onClicked: root.showCustomDialog = true
            }
        }

        // Filter Tabs
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ButtonBase {
                implicitHeight: 32
                implicitWidth: allTxt.implicitWidth + 24
                radius: Tokens.rounding.full
                color: root.selectedFilter === 0 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    anchors.fill: parent
                    onClicked: root.selectedFilter = 0
                }

                StyledText {
                    id: allTxt
                    anchors.centerIn: parent
                    text: qsTr("All (%1)").arg(HyprpmManager.allPlugins.length)
                    font: Tokens.font.label.medium
                    color: root.selectedFilter === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }

            ButtonBase {
                implicitHeight: 32
                implicitWidth: instTxt.implicitWidth + 24
                radius: Tokens.rounding.full
                color: root.selectedFilter === 1 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    anchors.fill: parent
                    onClicked: root.selectedFilter = 1
                }

                StyledText {
                    id: instTxt
                    anchors.centerIn: parent
                    text: qsTr("Installed (%1)").arg(HyprpmManager.installedCount)
                    font: Tokens.font.label.medium
                    color: root.selectedFilter === 1 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }

            ButtonBase {
                implicitHeight: 32
                implicitWidth: availTxt.implicitWidth + 24
                radius: Tokens.rounding.full
                color: root.selectedFilter === 2 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    anchors.fill: parent
                    onClicked: root.selectedFilter = 2
                }

                StyledText {
                    id: availTxt
                    anchors.centerIn: parent
                    text: qsTr("Available (%1)").arg(HyprpmManager.availableCount)
                    font: Tokens.font.label.medium
                    color: root.selectedFilter === 2 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }

            Item { Layout.fillWidth: true }

            TextButton {
                visible: HyprpmManager.logOutput.length > 0 || HyprpmManager.isBusy
                type: TextButton.Text
                text: root.showConsole ? qsTr("Hide Build Logs") : qsTr("Show Build Logs")
                onClicked: root.showConsole = !root.showConsole
            }
        }

        // Live Build Status / Output Console
        StyledRect {
            visible: root.showConsole || HyprpmManager.isBusy
            Layout.fillWidth: true
            implicitHeight: Math.min(260, consoleCol.implicitHeight + Tokens.padding.medium * 2)
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerLowest
            border.width: 1
            border.color: HyprpmManager.isBusy ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

            ColumnLayout {
                id: consoleCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    MaterialIcon {
                        text: HyprpmManager.isBusy ? "sync" : "terminal"
                        color: HyprpmManager.isBusy ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: HyprpmManager.statusMessage.length > 0 ? HyprpmManager.statusMessage : qsTr("Build & Installation Logs")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    TextButton {
                        visible: HyprpmManager.isBusy
                        type: TextButton.Outlined
                        text: qsTr("Cancel")
                        onClicked: HyprpmManager.cancelCurrentOperation()
                    }

                    IconButton {
                        icon: "clear_all"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: HyprpmManager.clearLogs()
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: logArea
                        readOnly: true
                        text: HyprpmManager.logOutput
                        font.family: "Monospace"
                        font.pixelSize: 11
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WrapAnywhere
                        background: null
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Plugin Catalog")
        }

        // Plugin Cards List
        Repeater {
            model: {
                let list = HyprpmManager.allPlugins;
                if (root.selectedFilter === 1) list = HyprpmManager.installedPlugins;
                else if (root.selectedFilter === 2) list = HyprpmManager.availablePlugins;

                const q = root.searchQuery.trim().toLowerCase();
                if (q === "") return list;

                return list.filter(p => {
                    const name = (p.name || "").toLowerCase();
                    const label = (p.label || "").toLowerCase();
                    const desc = (p.description || "").toLowerCase();
                    const author = (p.author || "").toLowerCase();
                    return name.includes(q) || label.includes(q) || desc.includes(q) || author.includes(q);
                });
            }

            ConnectedRect {
                id: card
                required property var modelData
                required property int index

                first: index === 0
                last: index === parent.count - 1
                Layout.fillWidth: true
                implicitHeight: cardContent.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: cardContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: card.modelData.icon ?? "extension"
                            color: card.modelData.isEnabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: card.modelData.label ?? card.modelData.name
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3onSurface
                                }

                                StyledRect {
                                    implicitHeight: 20
                                    implicitWidth: badgeText.implicitWidth + 12
                                    radius: Tokens.rounding.full
                                    color: card.modelData.isInstalled
                                           ? (card.modelData.isEnabled ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh)
                                           : Colours.palette.m3surfaceContainerLowest
                                    border.width: card.modelData.isInstalled ? 0 : 1
                                    border.color: Colours.palette.m3outlineVariant

                                    StyledText {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: card.modelData.statusText ?? ""
                                        font: Tokens.font.label.small
                                        color: card.modelData.isInstalled
                                               ? (card.modelData.isEnabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant)
                                               : Colours.palette.m3outline
                                    }
                                }
                            }

                            StyledText {
                                visible: card.modelData.author !== undefined && card.modelData.author !== ""
                                text: qsTr("By %1").arg(card.modelData.author)
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        // Actions for each plugin state
                        RowLayout {
                            spacing: Tokens.spacing.small

                            // If available / not installed:
                            TextButton {
                                visible: !card.modelData.isInstalled
                                type: TextButton.Filled
                                text: qsTr("Install")
                                enabled: !HyprpmManager.isBusy
                                onClicked: {
                                    root.showConsole = true;
                                    HyprpmManager.installPlugin(card.modelData.repository ?? card.modelData.name);
                                }
                            }

                            // If installed & disabled:
                            TextButton {
                                visible: card.modelData.isInstalled && !card.modelData.isEnabled
                                type: TextButton.Filled
                                text: qsTr("Enable")
                                enabled: !HyprpmManager.isBusy
                                onClicked: HyprpmManager.enablePlugin(card.modelData.name)
                            }

                            // If installed & enabled:
                            TextButton {
                                visible: card.modelData.isInstalled && card.modelData.isEnabled
                                type: TextButton.Filled
                                text: qsTr("Configure")
                                onClicked: {
                                    if (card.modelData.id === "hypr-dynamic-cursors" || card.modelData.name === "dynamic-cursors") {
                                        root.nState.openSubPage(1);
                                    } else {
                                        root.nState.openSubPage(2);
                                    }
                                }
                            }

                            TextButton {
                                visible: card.modelData.isInstalled && card.modelData.isEnabled
                                type: TextButton.Outlined
                                text: qsTr("Disable")
                                enabled: !HyprpmManager.isBusy
                                onClicked: HyprpmManager.disablePlugin(card.modelData.name)
                            }

                            IconButton {
                                visible: card.modelData.isInstalled
                                icon: "delete"
                                type: IconButton.Text
                                font: Tokens.font.icon.small
                                enabled: !HyprpmManager.isBusy
                                onClicked: HyprpmManager.removePlugin(card.modelData.name)
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: card.modelData.description ?? ""
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
