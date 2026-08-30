import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0
import FlightDeck.Hyprland 1.0

Popup {
    id: root

    property string bindKey: ""
    property string dispatcher: "exec"
    property string args: ""
    property bool recording: false

    width: Math.min(480, parent.width - 40)
    height: Math.min(460, parent.height - 40)
    anchors.centerIn: parent

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: StyledRect {
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
    }

    onClosed: {
        root.recording = false;
        HyprlandState.stopCapture();
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Add Custom Shortcut")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
                Layout.fillWidth: true
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                onClicked: root.close()
            }
        }

        // Key Combo Field
        StyledText {
            text: qsTr("Key Combination")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: keyInput
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. SUPER + Shift + D")
                text: root.bindKey
                onTextEdited: root.bindKey = text
            }

            StyledRect {
                implicitWidth: 44
                implicitHeight: 44
                radius: Tokens.rounding.medium
                color: root.recording ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                StateLayer {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.recording = !root.recording;
                        if (root.recording) {
                            focusItem.forceActiveFocus();
                            HyprlandState.startCapture();
                        } else {
                            HyprlandState.stopCapture();
                        }
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.recording ? "stop_circle" : "fiber_manual_record"
                    color: root.recording ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Dispatcher / Action Type
        StyledText {
            text: qsTr("Action Type (Dispatcher)")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        OptionRow {
            first: true
            last: true
            title: qsTr("Dispatcher")
            subtext: qsTr("Hyprland action to execute")
            options: [
                { label: qsTr("Launch Command (exec)"), value: "exec" },
                { label: qsTr("Switch Workspace (workspace)"), value: "workspace" },
                { label: qsTr("Move to Workspace (movetoworkspace)"), value: "movetoworkspace" },
                { label: qsTr("Close Window (killactive)"), value: "killactive" },
                { label: qsTr("Toggle Fullscreen (fullscreen)"), value: "fullscreen" },
                { label: qsTr("Toggle Floating (togglefloating)"), value: "togglefloating" }
            ]
            currentValue: {
                if (root.dispatcher === "exec") return qsTr("Launch Command (exec)");
                if (root.dispatcher === "workspace") return qsTr("Switch Workspace (workspace)");
                if (root.dispatcher === "movetoworkspace") return qsTr("Move to Workspace (movetoworkspace)");
                if (root.dispatcher === "killactive") return qsTr("Close Window (killactive)");
                if (root.dispatcher === "fullscreen") return qsTr("Toggle Fullscreen (fullscreen)");
                if (root.dispatcher === "togglefloating") return qsTr("Toggle Floating (togglefloating)");
                return root.dispatcher;
            }
            onOptionSelected: (val, lbl) => {
                root.dispatcher = val;
            }
        }

        // Argument / Command
        StyledText {
            text: root.dispatcher === "exec" ? qsTr("Command to Execute") : qsTr("Dispatcher Argument (Optional)")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: argInput
            Layout.fillWidth: true
            placeholderText: root.dispatcher === "exec" ? qsTr("e.g. kitty or flatpak run ...") : qsTr("e.g. 1 or special:magic")
            text: root.args
            onTextEdited: root.args = text
        }

        Item { Layout.fillHeight: true }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            TextButton {
                Layout.fillWidth: true
                implicitHeight: 40
                text: qsTr("Add Shortcut")
                onClicked: {
                    if (root.bindKey.trim() === "") return;
                    FlightDeckWriter.addCustomBind(root.bindKey.trim(), root.dispatcher, root.args.trim(), true);
                    FlightDeckWriter.save();
                    root.close();
                }
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

            let mods = [];
            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL");
            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
            if (event.modifiers & Qt.AltModifier) mods.push("ALT");
            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER");

            if (k === Qt.Key_Escape) {
                if (mods.length === 0) {
                    root.recording = false;
                    HyprlandState.stopCapture();
                    event.accepted = true;
                    return;
                }
            }

            let keyStr = "";
            if (k >= Qt.Key_A && k <= Qt.Key_Z) {
                keyStr = String.fromCharCode(k);
            } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
                keyStr = String.fromCharCode(k);
            } else {
                let map = {
                    [Qt.Key_Escape]: "escape",
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
                root.bindKey = mods.join(" + ");
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

            if (isModKey && modifierOnly && lastMods.length > 0) {
                root.bindKey = lastMods.join(" + ");
                root.recording = false;
                HyprlandState.stopCapture();
                event.accepted = true;
            }
        }
    }
}
