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
import FlightDeck.Hyprland 1.0

DialogRowButton {
    id: root

    property string varKey: ""
    property bool isModifier: false
    property string recordedKey: ""
    property bool recording: false

    readonly property string currentBindValue: {
        var v = CaelestiaVars.pendingVars[root.varKey] ?? CaelestiaVars.currentVars[root.varKey] ?? CaelestiaVars.getDefault(root.varKey);
        if (v === undefined || v === null || v === "") return qsTr("Disabled / Unbound");
        if (Array.isArray(v)) return v.join(", ");
        return String(v);
    }

    icon: root.isModifier ? "tune" : "keyboard"
    header: root.isModifier ? qsTr("Edit Modifier Combination") : qsTr("Edit Keybinding")
    acceptLabel: qsTr("Save Keybinding")

    subtext: {
        if (root.isModifier) {
            if (root.currentBindValue === qsTr("Disabled / Unbound")) {
                return qsTr("Modifier: Disabled");
            }
            return qsTr("Modifier: %1 (used with [0-9])").arg(root.currentBindValue);
        }
        return root.currentBindValue;
    }

    onOpenChanged: {
        if (open) {
            var v = CaelestiaVars.pendingVars[root.varKey] ?? CaelestiaVars.currentVars[root.varKey] ?? CaelestiaVars.getDefault(root.varKey, "");
            if (Array.isArray(v)) {
                root.recordedKey = v.join(", ");
            } else {
                root.recordedKey = String(v || "");
            }
            root.recording = false;
        } else {
            root.recording = false;
            HyprlandState.stopCapture();
        }
    }

    onAccepted: {
        CaelestiaVars.set(root.varKey, root.recordedKey.trim());
    }

    trailingActions: Component {
        RowLayout {
            spacing: Tokens.spacing.small

            // Reset button if overridden
            IconButton {
                icon: "restart_alt"
                type: IconButton.Text
                font: Tokens.font.icon.small
                visible: root.varKey !== "" && (root.varKey in CaelestiaVars.currentVars || root.varKey in CaelestiaVars.pendingVars)
                onClicked: {
                    CaelestiaVars.resetToDefault(root.varKey);
                }
            }

            // Delete / Disable button (sets to empty string "")
            IconButton {
                icon: "delete"
                type: IconButton.Text
                font: Tokens.font.icon.small
                visible: root.varKey !== "" && (root.currentBindValue !== qsTr("Disabled / Unbound") && root.currentBindValue !== "")
                onClicked: {
                    CaelestiaVars.set(root.varKey, "");
                }
            }
        }
    }

    content: Component {
        ColumnLayout {
            id: modalCol
            spacing: Tokens.spacing.medium
            Layout.fillWidth: true

            StyledText {
                text: root.isModifier 
                    ? qsTr("Set the modifier key combination used for 0-9 workspace actions. Clearing this field disables the shortcut.")
                    : qsTr("Click Record or type the key combination below. Clearing this field unbinds the action.")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledTextField {
                    id: keyField
                    Layout.fillWidth: true
                    placeholderText: root.isModifier ? qsTr("e.g. SUPER or CTRL + SUPER (empty to disable)") : qsTr("e.g. SUPER + T or Print (empty to unbind)")
                    text: root.recordedKey
                    onTextEdited: root.recordedKey = text
                }

                ButtonBase {
                    id: recBtn
                    implicitHeight: 40
                    implicitWidth: 90
                    radius: Tokens.rounding.medium
                    color: root.recording ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                    StateLayer {
                        anchors.fill: parent
                        onClicked: {
                            root.recording = !root.recording;
                            if (root.recording) {
                                keyListener.forceActiveFocus();
                                HyprlandState.startCapture();
                            } else {
                                HyprlandState.stopCapture();
                            }
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: root.recording ? "stop" : "fiber_manual_record"
                            color: root.recording ? Colours.palette.m3onPrimary : Colours.palette.m3error
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: root.recording ? qsTr("Stop") : qsTr("Record")
                            font: Tokens.font.label.medium
                            color: root.recording ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }
                    }
                }
            }

            // Quick actions inside modal: Clear / Disable & Reset to default
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                TextButton {
                    type: TextButton.Outlined
                    text: qsTr("Clear / Disable")
                    onClicked: {
                        root.recordedKey = "";
                    }
                }

                TextButton {
                    type: TextButton.Outlined
                    text: qsTr("Reset to Default")
                    onClicked: {
                        var def = CaelestiaVars.getDefault(root.varKey, "");
                        if (Array.isArray(def)) {
                            root.recordedKey = def.join(", ");
                        } else {
                            root.recordedKey = String(def || "");
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Item {
                id: keyListener
                focus: root.recording
                property bool modifierOnly: false
                property var lastMods: []

                Keys.onPressed: (event) => {
                    if (!root.recording) return;
                    let k = event.key;
                    if (k === Qt.Key_Escape) {
                        root.recording = false;
                        HyprlandState.stopCapture();
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
                            [Qt.Key_Minus]: "Minus",
                            [Qt.Key_Equal]: "Equal",
                            [Qt.Key_BracketLeft]: "bracketleft",
                            [Qt.Key_BracketRight]: "bracketright",
                            [Qt.Key_Semicolon]: "semicolon",
                            [Qt.Key_Apostrophe]: "apostrophe",
                            [Qt.Key_Grave]: "grave",
                            [Qt.Key_Slash]: "slash",
                            [Qt.Key_Period]: "Period",
                            [Qt.Key_Comma]: "Comma",
                            [Qt.Key_Backslash]: "Backslash",
                            [Qt.Key_Right]: "Right",
                            [Qt.Key_Left]: "Left",
                            [Qt.Key_Up]: "Up",
                            [Qt.Key_Down]: "Down",
                            [Qt.Key_PageUp]: "Page_Up",
                            [Qt.Key_PageDown]: "Page_Down",
                            [Qt.Key_Print]: "Print",
                            [Qt.Key_Delete]: "Delete"
                        };
                        if (map[k] !== undefined) keyStr = map[k];
                        else keyStr = event.text.toUpperCase();
                    }

                    let isModKey = (k === Qt.Key_Control || k === Qt.Key_Shift || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R);

                    if (keyStr !== "" && !isModKey) {
                        modifierOnly = false;
                        mods.push(keyStr);
                        root.recordedKey = mods.join(" + ");
                        root.recording = false;
                        HyprlandState.stopCapture();
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
                        root.recordedKey = lastMods.join(" + ");
                        root.recording = false;
                        HyprlandState.stopCapture();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
