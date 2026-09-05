pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.astra.common

ColumnLayout {
    id: root

    property bool flagLocked: false
    property bool flagRepeating: false
    property bool flagRelease: false
    property bool flagLongPress: false
    property bool flagNonConsuming: false
    property bool flagTransparent: false
    property bool flagIgnoreMods: false
    property bool flagDontInhibit: false
    property alias flagDescription: descInput.text

    property bool showAdvanced: false

    function getFlagsMap() {
        let flags = {};
        if (flagLocked) flags["locked"] = true;
        if (flagRepeating) flags["repeating"] = true;
        if (flagRelease) flags["release"] = true;
        if (flagLongPress) flags["long_press"] = true;
        if (flagNonConsuming) flags["non_consuming"] = true;
        if (flagTransparent) flags["transparent"] = true;
        if (flagIgnoreMods) flags["ignore_mods"] = true;
        if (flagDontInhibit) flags["dont_inhibit"] = true;
        if (flagDescription.trim() !== "") flags["description"] = flagDescription.trim();
        return flags;
    }

    function setFromFlagsMap(flags) {
        if (!flags) {
            reset();
            return;
        }
        flagLocked = Boolean(flags["locked"]);
        flagRepeating = Boolean(flags["repeating"]);
        flagRelease = Boolean(flags["release"]);
        flagLongPress = Boolean(flags["long_press"]);
        flagNonConsuming = Boolean(flags["non_consuming"]);
        flagTransparent = Boolean(flags["transparent"]);
        flagIgnoreMods = Boolean(flags["ignore_mods"]);
        flagDontInhibit = Boolean(flags["dont_inhibit"]);
        flagDescription = String(flags["description"] || "");
        if (flagTransparent || flagIgnoreMods || flagDontInhibit) {
            showAdvanced = true;
        }
    }

    function reset() {
        flagLocked = false;
        flagRepeating = false;
        flagRelease = false;
        flagLongPress = false;
        flagNonConsuming = false;
        flagTransparent = false;
        flagIgnoreMods = false;
        flagDontInhibit = false;
        flagDescription = "";
        showAdvanced = false;
    }

    spacing: Tokens.spacing.small
    Layout.fillWidth: true

    StyledText {
        text: qsTr("Description (Optional)")
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurfaceVariant
    }

    StyledTextField {
        id: descInput
        Layout.fillWidth: true
        placeholderText: qsTr("e.g. Open primary terminal or Raise volume")
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.extraSmall
        text: qsTr("Keybind Flags")
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurfaceVariant
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Locked")
            subtext: qsTr("Works when lockscreen or input inhibitor is active")
            checked: root.flagLocked
            onToggled: root.flagLocked = checked
        }

        ToggleRow {
            text: qsTr("Repeat")
            subtext: qsTr("Repeats action while key combination is held down")
            checked: root.flagRepeating
            onToggled: root.flagRepeating = checked
        }

        ToggleRow {
            text: qsTr("Trigger on Release")
            subtext: qsTr("Fires when the key combination is released")
            checked: root.flagRelease
            onToggled: {
                root.flagRelease = checked;
                if (checked) root.flagLongPress = false;
            }
        }

        ToggleRow {
            text: qsTr("Long Press")
            subtext: qsTr("Fires only on prolonged key press")
            checked: root.flagLongPress
            onToggled: {
                root.flagLongPress = checked;
                if (checked) root.flagRelease = false;
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Non-consuming")
            subtext: qsTr("Pass key event to active window while executing action")
            checked: root.flagNonConsuming
            onToggled: root.flagNonConsuming = checked
        }
    }

    // Advanced Flags Button
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        StateLayer {
            anchors.fill: parent
            onClicked: root.showAdvanced = !root.showAdvanced
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: root.showAdvanced ? "expand_less" : "expand_more"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3primary
            }

            StyledText {
                text: root.showAdvanced ? qsTr("Hide Advanced Flags") : qsTr("Show Advanced Flags")
                font: Tokens.font.label.medium
                color: Colours.palette.m3primary
            }
        }
    }

    // Advanced flags container
    ColumnLayout {
        visible: root.showAdvanced
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Transparent")
            subtext: qsTr("Cannot be shadowed or blocked by other binds")
            checked: root.flagTransparent
            onToggled: root.flagTransparent = checked
        }

        ToggleRow {
            text: qsTr("Ignore Modifiers")
            subtext: qsTr("Ignores any extra modifier keys held down")
            checked: root.flagIgnoreMods
            onToggled: root.flagIgnoreMods = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Bypass Application Inhibit")
            subtext: qsTr("Bypasses client application requests to inhibit shortcuts")
            checked: root.flagDontInhibit
            onToggled: root.flagDontInhibit = checked
        }
    }
}
