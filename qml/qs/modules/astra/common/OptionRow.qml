pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

ConnectedRect {
    id: root

    property string varKey: ""
    property bool showReset: false
    signal reset()

    property alias title: root.text
    property string text
    property string subtext
    property string currentValue
    property var options: []
    property int currentIndex: 0
    property bool menuOnTop: false
    readonly property alias stateLayer: stateLayer
    signal optionSelected(var value, string label)
    signal clicked()

    readonly property bool isSplitButton: !!(root.options && root.options.length > 2)

    Layout.fillWidth: true
    implicitHeight: Math.max(rowLayout.implicitHeight, isSplitButton ? splitBtn.implicitHeight : 0) + Tokens.padding.medium * 2
    clip: false
    z: (isSplitButton && splitBtn.expanded) ? 10 : 0

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        enabled: !root.isSplitButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.options && root.options.length > 0) {
                const nextIdx = (root.currentIndex + 1) % root.options.length;
                root.currentIndex = nextIdx;
                root.optionSelected(root.options[nextIdx].value, root.options[nextIdx].label);
            }
            root.clicked();
        }
    }

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: titleText
                    text: root.text
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.showReset || (root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars))
                    onClicked: {
                        if (root.varKey !== "") {
                            CaelestiaVars.resetToDefault(root.varKey);
                            var defVal = CaelestiaVars.getDefault(root.varKey, "");
                            root.currentValue = defVal;
                        }
                        root.reset();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        // Case 1: 2 options (swap / toggle mode)
        RowLayout {
            visible: !root.isSplitButton
            spacing: Tokens.spacing.small

            StyledText {
                text: root.currentValue
                color: Colours.palette.m3primary
                font: Tokens.font.label.medium
            }

            MaterialIcon {
                text: "swap_horiz"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }
        }

        // Case 2: > 2 options (SplitButton dropdown)
        SplitButton {
            id: splitBtn
            visible: root.isSplitButton
            type: SplitButton.Tonal
            menuOnTop: root.menuOnTop
            stateLayer.onClicked: splitBtn.expanded = !splitBtn.expanded
            menuItems: {
                if (!root.options || root.options.length <= 2) return [];
                var items = [];
                for (var i = 0; i < root.options.length; i++) {
                    (function(opt, idx) {
                        var item = Qt.createQmlObject(
                            'import qs.components.controls; MenuItem { text: "' + opt.label.replace(/"/g, '\\"') + '"; onClicked: { root.currentIndex = ' + idx + '; root.optionSelected(root.options[' + idx + '].value, root.options[' + idx + '].label); } }',
                            splitBtn
                        );
                        if (opt.icon) item.activeIcon = opt.icon;
                        items.push(item);
                    })(root.options[i], i);
                }
                return items;
            }
            active: {
                if (!menuItems || menuItems.length === 0) return null;
                for (var i = 0; i < menuItems.length; i++) {
                    if (menuItems[i].text === root.currentValue) return menuItems[i];
                }
                return menuItems[root.currentIndex] || menuItems[0] || null;
            }
            fallbackText: root.currentValue
        }
    }
}
