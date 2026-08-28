pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0

ConnectedRect {
    id: root

    property alias label: labelText.text
    property alias text: labelText.text
    property string varKey: ""
    property bool isModifier: false
    property bool recording: false
    readonly property alias stateLayer: stateLayer

    readonly property string bindValue: {
        var v = CaelestiaVars.pendingVars[root.varKey] ?? CaelestiaVars.currentVars[root.varKey] ?? CaelestiaVars.getDefault(root.varKey);
        if (v === undefined || v === null || v === "") return qsTr("Unbound");
        if (Array.isArray(v)) return v.join(", ");
        return String(v);
    }

    Layout.fillWidth: true
    implicitHeight: Math.max(54, contentRow.implicitHeight + Tokens.padding.medium * 2)

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.recording = !root.recording;
            if (root.recording) {
                focusItem.forceActiveFocus();
                HyprlandState.dispatch("submap record");
            } else {
                HyprlandState.dispatch("submap reset");
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        anchors.topMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    id: labelText
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledRect {
                    visible: root.isModifier
                    implicitHeight: 20
                    implicitWidth: modLabel.implicitWidth + 12
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        id: modLabel
                        anchors.centerIn: parent
                        text: qsTr("Modifier")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSecondaryContainer
                    }
                }

                IconButton {
                    icon: "edit"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    onClicked: {
                        root.recording = !root.recording;
                        if (root.recording) {
                            focusItem.forceActiveFocus();
                            HyprlandState.dispatch("submap record");
                        } else {
                            HyprlandState.dispatch("submap reset");
                        }
                    }
                }

                IconButton {
                    icon: "restart_alt"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars)
                    onClicked: {
                        CaelestiaVars.resetToDefault(root.varKey);
                    }
                }

                IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    font: Tokens.font.icon.small
                    visible: root.varKey !== "" && (root.isModifier || (root.bindValue !== qsTr("Unbound") && root.bindValue !== ""))
                    onClicked: {
                        CaelestiaVars.set(root.varKey, "");
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: {
                    if (root.recording) return qsTr("Recording shortcut... (Press Esc to cancel)");
                    if (root.isModifier) return qsTr("Modifier combination: %1 (used with [0-9])").arg(root.bindValue);
                    return root.bindValue;
                }
                color: root.recording ? Colours.palette.m3primary : (root.isModifier ? Colours.palette.m3secondary : Colours.palette.m3outline)
                font: Tokens.font.label.small
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        StyledRect {
            id: recordBadge
            implicitWidth: 36
            implicitHeight: 36
            radius: Tokens.rounding.full
            color: root.recording ? Colours.palette.m3primary : (stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh)

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.recording ? "stop_circle" : "fiber_manual_record"
                color: root.recording ? Colours.palette.m3onPrimary : (stateLayer.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant)
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    Item {
        id: focusItem
        focus: root.recording
        property bool modifierOnly: false
        property var lastMods: []

        Keys.onPressed: (event) => {
            if (!root.recording) return;
            let k = event.key;
            if (k === Qt.Key_Escape) {
                root.recording = false;
                HyprlandState.dispatch("submap reset");
                event.accepted = true;
                return;
            }

            let mods = [];
            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

            let keyStr = "";
            if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                keyStr = String.fromCharCode(k);
            } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                keyStr = String.fromCharCode(k);
            } else {
                let map = {
                    [Qt.Key_Return]: "Return",
                    [Qt.Key_Enter]: "Return",
                    [Qt.Key_Space]: "Space",
                    [Qt.Key_Tab]: "Tab",
                    [Qt.Key_Backtab]: "Tab",
                    [Qt.Key_Backspace]: "Backspace",
                    [Qt.Key_Minus]: "minus",
                    [Qt.Key_Equal]: "equal",
                    [Qt.Key_BracketLeft]: "bracketleft",
                    [Qt.Key_BracketRight]: "bracketright",
                    [Qt.Key_Semicolon]: "semicolon",
                    [Qt.Key_Apostrophe]: "apostrophe",
                    [Qt.Key_Grave]: "grave",
                    [Qt.Key_Slash]: "slash",
                    [Qt.Key_Period]: "period",
                    [Qt.Key_Backslash]: "backslash",
                    [Qt.Key_Comma]: "comma",
                    [Qt.Key_Right]: "Right",
                    [Qt.Key_Left]: "Left",
                    [Qt.Key_Up]: "Up",
                    [Qt.Key_Down]: "Down",
                    [Qt.Key_Delete]: "Delete"
                };
                if (map[k] !== undefined) keyStr = map[k];
                else keyStr = event.text.toUpperCase();
            }

            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

            if (keyStr !== "" && !isModKey) {
                modifierOnly = false;
                mods.push(keyStr);
                let finalBind = mods.join(" + ");
                CaelestiaVars.set(root.varKey, finalBind);
                root.recording = false;
                HyprlandState.dispatch("submap reset");
                event.accepted = true;
            } else if (isModKey) {
                modifierOnly = true;
                let modStr = "";
                if (k === Qt.Key_Control) modStr = "CTRL";
                else if (k === Qt.Key_Shift) modStr = "SHIFT";
                else if (k === Qt.Key_Alt) modStr = "ALT";
                else if (k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R) modStr = "SUPER";

                if (!mods.includes(modStr) && modStr !== "") mods.push(modStr);
                lastMods = mods;
                event.accepted = true;
            }
        }

        Keys.onReleased: (event) => {
            if (!root.recording) return;
            let k = event.key;
            let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

            if (isModKey && (root.isModifier || modifierOnly) && lastMods.length > 0) {
                let finalBind = lastMods.join(" + ");
                CaelestiaVars.set(root.varKey, finalBind);
                root.recording = false;
                HyprlandState.dispatch("submap reset");
                event.accepted = true;
            }
        }
    }
}
