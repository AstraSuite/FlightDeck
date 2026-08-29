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

PageBase {
    id: root

    title: qsTr("Keyboard")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root ? root.cappedWidth : 800
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Layout & Options")
        }

        TextFieldRow {
            first: true
            varKey: "kbLayout"
            label: qsTr("Keyboard Layout")
            subtext: qsTr("XKB layout code (e.g. us, de, fr, ru)")
            text: CaelestiaVars.pendingVars.kbLayout ?? CaelestiaVars.currentVars.kbLayout ?? CaelestiaVars.getDefault("kbLayout", "us")
            placeholderText: "us"
            onEditingFinished: CaelestiaVars.set("kbLayout", text.trim())
        }

        TextFieldRow {
            varKey: "kbVariant"
            label: qsTr("Keyboard Variant")
            subtext: qsTr("XKB layout variant (optional, e.g. intl, dvorak)")
            text: CaelestiaVars.pendingVars.kbVariant ?? CaelestiaVars.currentVars.kbVariant ?? CaelestiaVars.getDefault("kbVariant", "")
            placeholderText: ""
            onEditingFinished: CaelestiaVars.set("kbVariant", text.trim())
        }

        TextFieldRow {
            last: true
            varKey: "kbOptions"
            label: qsTr("Keyboard Options")
            subtext: qsTr("XKB options (e.g. grp:alt_shift_toggle, caps:swapescape)")
            text: CaelestiaVars.pendingVars.kbOptions ?? CaelestiaVars.currentVars.kbOptions ?? CaelestiaVars.getDefault("kbOptions", "")
            placeholderText: "grp:alt_shift_toggle"
            onEditingFinished: CaelestiaVars.set("kbOptions", text.trim())
        }

        SectionHeader {
            text: qsTr("Key Repeat & Behavior")
        }

        ToggleRow {
            first: true
            varKey: "numlockByDefault"
            text: qsTr("Numlock by Default")
            subtext: qsTr("Enable NumLock on compositor startup")
            checked: CaelestiaVars.pendingVars.numlockByDefault ?? CaelestiaVars.currentVars.numlockByDefault ?? CaelestiaVars.getDefault("numlockByDefault", false)
            onToggled: CaelestiaVars.set("numlockByDefault", checked)
        }

        StepperRow {
            varKey: "keyRepeatRate"
            label: qsTr("Key Repeat Rate")
            subtext: qsTr("Repeats per second when holding down a key")
            value: CaelestiaVars.pendingVars.keyRepeatRate ?? CaelestiaVars.currentVars.keyRepeatRate ?? CaelestiaVars.getDefault("keyRepeatRate", 25)
            from: 5
            to: 100
            stepSize: 5
            suffix: "/s"
            onMoved: v => CaelestiaVars.set("keyRepeatRate", v)
        }

        StepperRow {
            last: true
            varKey: "keyRepeatDelay"
            label: qsTr("Key Repeat Delay")
            subtext: qsTr("Delay in milliseconds before key repeat begins")
            value: CaelestiaVars.pendingVars.keyRepeatDelay ?? CaelestiaVars.currentVars.keyRepeatDelay ?? CaelestiaVars.getDefault("keyRepeatDelay", 600)
            from: 100
            to: 2000
            stepSize: 50
            suffix: "ms"
            onMoved: v => CaelestiaVars.set("keyRepeatDelay", v)
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
