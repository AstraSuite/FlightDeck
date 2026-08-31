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
                property int lastFilter: 0
                property real animOffX: 0
                property bool showCustomDialog: false
                property bool showConsole: false

                onSelectedFilterChanged: {
                    filterAnim.complete();
                    animOffX = (selectedFilter > lastFilter ? 1 : -1) * Tokens.padding.largeIncreased;
                    filterAnim.start();
                    lastFilter = selectedFilter;
                }

                headerContent: Component {
                    SearchBar {
                        topPadding: Tokens.padding.small
                        bottomPadding: Tokens.padding.small

                        placeholderText: qsTr("Search plugins...")
                        font: Tokens.font.body.medium

                        bg.color: Colours.tPalette.m3surfaceContainerLowest
                        bg.border.color: Colours.palette.m3outlineVariant
                        searchIcon.fontStyle: Tokens.font.icon.medium
                        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
                        clearIcon.font: Tokens.font.icon.medium
                        clearIcon.padding: Tokens.padding.extraSmall

                        onTextChanged: storeMainHub.searchQuery = text
                    }
                }
                headerContentWidth: 260

                ColumnLayout {
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    anchors.top: parent ? parent.top : undefined
                    width: storeMainHub ? storeMainHub.cappedWidth : 800
                    spacing: Tokens.spacing.extraSmall / 2

                    CustomRepoDialog {
                        id: customDialog
                        visible: storeMainHub.showCustomDialog
                        onClosed: storeMainHub.showCustomDialog = false
                    }

                    // Top Toolbar: Filter Chips & Action Icons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Tokens.spacing.extraSmall
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

                        IconButton {
                            icon: "system_update_alt"
                            type: IconButton.Filled
                            font: Tokens.font.icon.small
                            enabled: !HyprpmManager.isBusy
                            onClicked: {
                                storeMainHub.showConsole = true;
                                HyprpmManager.updateAll(true);
                            }
                        }

                        IconButton {
                            icon: "sync"
                            type: IconButton.Outlined
                            font: Tokens.font.icon.small
                            enabled: !HyprpmManager.isBusy
                            onClicked: HyprpmManager.reloadPlugins()
                        }

                        IconButton {
                            visible: HyprpmManager.logOutput.length > 0 || HyprpmManager.isBusy
                            icon: "terminal"
                            type: storeMainHub.showConsole ? IconButton.Filled : IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: storeMainHub.showConsole = !storeMainHub.showConsole
                        }
                    }

                    // Live Build Status / Output Console
                    StyledRect {
                        visible: storeMainHub.showConsole || HyprpmManager.isBusy
                        Layout.fillWidth: true
                        implicitHeight: Math.min(240, consoleCol.implicitHeight + Tokens.padding.medium * 2)
                        radius: Tokens.rounding.large
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

                    // Filtered List Container with Fading Swipe Animation
                    ColumnLayout {
                        id: listContainer
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        // Section 1: Installed Plugins Management
                        SectionHeader {
                            first: true
                            visible: (storeMainHub.selectedFilter === 0 || storeMainHub.selectedFilter === 1) && HyprpmManager.installedCount > 0
                            text: qsTr("Manage Installed Plugins (%1)").arg(HyprpmManager.installedCount)
                        }

                        Repeater {
                            id: instRepeater
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
                                last: index === instRepeater.count - 1
                                Layout.fillWidth: true
                                implicitHeight: instCardContent.implicitHeight + Tokens.padding.large * 2

                                ColumnLayout {
                                    id: instCardContent
                                    anchors.fill: parent
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

                                        // Spacer pushes actions to the far right edge
                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        // Material 3 Switch Component & Delete Action (delete to the left of switch)
                                        RowLayout {
                                            spacing: Tokens.spacing.small

                                            IconButton {
                                                icon: "delete"
                                                type: IconButton.Text
                                                font: Tokens.font.icon.small
                                                enabled: !HyprpmManager.isBusy
                                                onClicked: HyprpmManager.removePlugin(instCard.modelData.name)
                                            }

                                            StyledSwitch {
                                                checked: instCard.modelData.isEnabled
                                                enabled: !HyprpmManager.isBusy
                                                onToggled: {
                                                    if (checked) {
                                                        HyprpmManager.enablePlugin(instCard.modelData.name);
                                                    } else {
                                                        HyprpmManager.disablePlugin(instCard.modelData.name);
                                                    }
                                                }
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
                            first: HyprpmManager.installedCount === 0 || storeMainHub.selectedFilter === 2
                            visible: storeMainHub.selectedFilter === 0 || storeMainHub.selectedFilter === 2
                            text: qsTr("Available Plugins Catalog (%1)").arg(HyprpmManager.availableCount)
                        }

                        Repeater {
                            id: availRepeater
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
                                last: index === availRepeater.count - 1
                                Layout.fillWidth: true
                                implicitHeight: availCardContent.implicitHeight + Tokens.padding.large * 2

                                ColumnLayout {
                                    id: availCardContent
                                    anchors.fill: parent
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

                                        // Spacer pushes action button to the far right edge
                                        Item {
                                            Layout.fillWidth: true
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
                    }

                    SequentialAnimation {
                        id: filterAnim

                        Anim {
                            target: listContainer
                            property: "opacity"
                            to: 0
                            type: Anim.FastEffects
                        }
                        PropertyAction {
                            target: listContainer
                            property: "x"
                            value: storeMainHub.animOffX
                        }
                        ParallelAnimation {
                            Anim {
                                target: listContainer
                                property: "opacity"
                                from: 0
                                to: 1
                                type: Anim.DefaultEffects
                            }
                            Anim {
                                target: listContainer
                                property: "x"
                                from: storeMainHub.animOffX
                                to: 0
                                type: Anim.DefaultEffects
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
