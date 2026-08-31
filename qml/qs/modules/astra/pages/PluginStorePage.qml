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
import qs.modules.astra.pages.plugins
import FlightDeck.Managers 1.0

StackPage {
    id: root

    pages: [
        Component {
            PageBase {
                id: storeMainHub
                title: qsTr("Plugin store & manager")
                nState: root.nState

                property string searchQuery: ""
                property int selectedFilter: 0 // 0: All, 1: Installed, 2: Available
                property bool showCustomDialog: false
                property bool showConsole: false

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: storeMainHub ? storeMainHub.cappedWidth : 800
                    spacing: Tokens.spacing.medium

                    CustomRepoDialog {
                        id: customDialog
                        visible: storeMainHub.showCustomDialog
                        onClosed: storeMainHub.showCustomDialog = false
                    }

                    // Top Store Toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Search plugins by name, description, author...")
                            text: storeMainHub.searchQuery
                            onTextEdited: storeMainHub.searchQuery = text
                        }

                        TextButton {
                            type: TextButton.Filled
                            text: qsTr("Update All")
                            enabled: !HyprpmManager.isBusy
                            onClicked: {
                                storeMainHub.showConsole = true;
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
                            onClicked: storeMainHub.showCustomDialog = true
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
                            color: storeMainHub.selectedFilter === 0 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                            StateLayer {
                                anchors.fill: parent
                                onClicked: storeMainHub.selectedFilter = 0
                            }

                            StyledText {
                                id: allTxt
                                anchors.centerIn: parent
                                text: qsTr("All (%1)").arg(HyprpmManager.allPlugins.length)
                                font: Tokens.font.label.medium
                                color: storeMainHub.selectedFilter === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }

                        ButtonBase {
                            implicitHeight: 32
                            implicitWidth: instTxt.implicitWidth + 24
                            radius: Tokens.rounding.full
                            color: storeMainHub.selectedFilter === 1 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                            StateLayer {
                                anchors.fill: parent
                                onClicked: storeMainHub.selectedFilter = 1
                            }

                            StyledText {
                                id: instTxt
                                anchors.centerIn: parent
                                text: qsTr("Installed (%1)").arg(HyprpmManager.installedCount)
                                font: Tokens.font.label.medium
                                color: storeMainHub.selectedFilter === 1 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }

                        ButtonBase {
                            implicitHeight: 32
                            implicitWidth: availTxt.implicitWidth + 24
                            radius: Tokens.rounding.full
                            color: storeMainHub.selectedFilter === 2 ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                            StateLayer {
                                anchors.fill: parent
                                onClicked: storeMainHub.selectedFilter = 2
                            }

                            StyledText {
                                id: availTxt
                                anchors.centerIn: parent
                                text: qsTr("Available (%1)").arg(HyprpmManager.availableCount)
                                font: Tokens.font.label.medium
                                color: storeMainHub.selectedFilter === 2 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }

                        Item { Layout.fillWidth: true }

                        TextButton {
                            visible: HyprpmManager.logOutput.length > 0 || HyprpmManager.isBusy
                            type: TextButton.Text
                            text: storeMainHub.showConsole ? qsTr("Hide Build Logs") : qsTr("Show Build Logs")
                            onClicked: storeMainHub.showConsole = !storeMainHub.showConsole
                        }
                    }

                    // Live Build Status / Output Console
                    StyledRect {
                        visible: storeMainHub.showConsole || HyprpmManager.isBusy
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

                    // Section 1: Installed Plugins Management
                    SectionHeader {
                        visible: (storeMainHub.selectedFilter === 0 || storeMainHub.selectedFilter === 1) && HyprpmManager.installedCount > 0
                        text: qsTr("Manage Installed Plugins (%1)").arg(HyprpmManager.installedCount)
                    }

                    Repeater {
                        model: {
                            if (storeMainHub.selectedFilter === 2) return [];
                            const q = storeMainHub.searchQuery.trim().toLowerCase();
                            if (q === "") return HyprpmManager.installedPlugins;
                            return HyprpmManager.installedPlugins.filter(p => {
                                const name = (p.name || "").toLowerCase();
                                const label = (p.label || "").toLowerCase();
                                const desc = (p.description || "").toLowerCase();
                                const author = (p.author || "").toLowerCase();
                                return name.includes(q) || label.includes(q) || desc.includes(q) || author.includes(q);
                            });
                        }

                        ConnectedRect {
                            id: instCard
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === parent.count - 1
                            Layout.fillWidth: true
                            implicitHeight: instCardContent.implicitHeight + Tokens.padding.large * 2

                            ColumnLayout {
                                id: instCardContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.largeIncreased
                                spacing: Tokens.spacing.small

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        text: instCard.modelData.icon ?? "extension"
                                        color: instCard.modelData.isEnabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: Tokens.spacing.small

                                            StyledText {
                                                text: instCard.modelData.label ?? instCard.modelData.name
                                                font: Tokens.font.title.small
                                                color: Colours.palette.m3onSurface
                                            }

                                            StyledRect {
                                                implicitHeight: 20
                                                implicitWidth: instBadgeText.implicitWidth + 12
                                                radius: Tokens.rounding.full
                                                color: instCard.modelData.isEnabled ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                                                StyledText {
                                                    id: instBadgeText
                                                    anchors.centerIn: parent
                                                    text: instCard.modelData.isEnabled ? qsTr("Enabled") : qsTr("Disabled")
                                                    font: Tokens.font.label.small
                                                    color: instCard.modelData.isEnabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                                }
                                            }
                                        }

                                        StyledText {
                                            visible: instCard.modelData.author !== undefined && instCard.modelData.author !== ""
                                            text: qsTr("By %1").arg(instCard.modelData.author)
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3outline
                                        }
                                    }

                                    // Enable / Disable Action Buttons
                                    RowLayout {
                                        spacing: Tokens.spacing.small

                                        TextButton {
                                            visible: !instCard.modelData.isEnabled
                                            type: TextButton.Filled
                                            text: qsTr("Enable")
                                            enabled: !HyprpmManager.isBusy
                                            onClicked: HyprpmManager.enablePlugin(instCard.modelData.name)
                                        }

                                        TextButton {
                                            visible: instCard.modelData.isEnabled
                                            type: TextButton.Outlined
                                            text: qsTr("Disable")
                                            enabled: !HyprpmManager.isBusy
                                            onClicked: HyprpmManager.disablePlugin(instCard.modelData.name)
                                        }

                                        IconButton {
                                            icon: "delete"
                                            type: IconButton.Text
                                            font: Tokens.font.icon.small
                                            enabled: !HyprpmManager.isBusy
                                            onClicked: HyprpmManager.removePlugin(instCard.modelData.name)
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: instCard.modelData.description ?? ""
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    // Section 2: Available Plugins (Store Catalog)
                    SectionHeader {
                        visible: storeMainHub.selectedFilter === 0 || storeMainHub.selectedFilter === 2
                        text: qsTr("Available Plugins Catalog (%1)").arg(HyprpmManager.availableCount)
                    }

                    Repeater {
                        model: {
                            if (storeMainHub.selectedFilter === 1) return [];
                            const q = storeMainHub.searchQuery.trim().toLowerCase();
                            if (q === "") return HyprpmManager.availablePlugins;
                            return HyprpmManager.availablePlugins.filter(p => {
                                const name = (p.name || "").toLowerCase();
                                const label = (p.label || "").toLowerCase();
                                const desc = (p.description || "").toLowerCase();
                                const author = (p.author || "").toLowerCase();
                                return name.includes(q) || label.includes(q) || desc.includes(q) || author.includes(q);
                            });
                        }

                        ConnectedRect {
                            id: availCard
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === parent.count - 1
                            Layout.fillWidth: true
                            implicitHeight: availCardContent.implicitHeight + Tokens.padding.large * 2

                            ColumnLayout {
                                id: availCardContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.largeIncreased
                                spacing: Tokens.spacing.small

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        text: availCard.modelData.icon ?? "extension"
                                        color: Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: Tokens.spacing.small

                                            StyledText {
                                                text: availCard.modelData.label ?? availCard.modelData.name
                                                font: Tokens.font.title.small
                                                color: Colours.palette.m3onSurface
                                            }

                                            StyledRect {
                                                implicitHeight: 20
                                                implicitWidth: availBadgeText.implicitWidth + 12
                                                radius: Tokens.rounding.full
                                                color: Colours.palette.m3surfaceContainerLowest
                                                border.width: 1
                                                border.color: Colours.palette.m3outlineVariant

                                                StyledText {
                                                    id: availBadgeText
                                                    anchors.centerIn: parent
                                                    text: qsTr("Available")
                                                    font: Tokens.font.label.small
                                                    color: Colours.palette.m3outline
                                                }
                                            }
                                        }

                                        StyledText {
                                            visible: availCard.modelData.author !== undefined && availCard.modelData.author !== ""
                                            text: qsTr("By %1").arg(availCard.modelData.author)
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3outline
                                        }
                                    }

                                    TextButton {
                                        type: TextButton.Filled
                                        text: qsTr("Install")
                                        enabled: !HyprpmManager.isBusy
                                        onClicked: {
                                            storeMainHub.showConsole = true;
                                            HyprpmManager.installPlugin(availCard.modelData.repository ?? availCard.modelData.name);
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: availCard.modelData.description ?? ""
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
        }
    ]
}
