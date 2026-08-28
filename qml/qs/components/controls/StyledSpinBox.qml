import QtQuick
import Helm.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 2147483647
    property real stepSize: 1
    property string suffix: ""
    property int repeatRate: 350
    property int repeatDecay: 40
    property int cLayer: 1

    signal valueModified()

    function increase(): void {
        let newValue = Math.min(root.to, root.value + root.stepSize);
        const decimals = root.stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(root.stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        if (root.value !== newValue) {
            root.value = newValue;
            root.valueModified();
        }
    }

    function decrease(): void {
        let newValue = Math.max(root.from, root.value - root.stepSize);
        const decimals = root.stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(root.stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        if (root.value !== newValue) {
            root.value = newValue;
            root.valueModified();
        }
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.max(1, Math.round(Tokens.spacing.extraSmall / 2))

        IconButton {
            id: downButton
            anchors.verticalCenter: parent.verticalCenter

            radius: 0
            radiusMorph: false
            isRound: false

            topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.large
            bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.large
            topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "remove"
            font: Tokens.font.icon.small
            disabled: root.value <= root.from
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall

            onClicked: root.decrease()
        }

        TextFieldBase {
            id: inputField
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(48, contentWidth + Tokens.padding.medium * 2 + 10)
            implicitHeight: downButton.implicitHeight
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurface
            inputMethodHints: Qt.ImhDigitsOnly
            selectByMouse: true

            text: root.value.toString()

            validator: IntValidator {
                bottom: Math.round(root.from)
                top: Math.round(root.to)
            }

            background: StyledRect {
                radius: Tokens.rounding.extraSmall
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            onEditingFinished: {
                let parsed = parseInt(text);
                if (isNaN(parsed)) parsed = root.from;
                parsed = Math.max(root.from, Math.min(root.to, parsed));
                if (root.value !== parsed) {
                    root.value = parsed;
                    root.valueModified();
                }
                text = root.value.toString();
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    let parsed = parseInt(text);
                    if (isNaN(parsed)) parsed = root.from;
                    parsed = Math.max(root.from, Math.min(root.to, parsed));
                    if (root.value !== parsed) {
                        root.value = parsed;
                        root.valueModified();
                    }
                    text = root.value.toString();
                } else {
                    selectAll();
                }
            }

            Connections {
                target: root
                function onValueChanged(): void {
                    if (!inputField.activeFocus) {
                        inputField.text = root.value.toString();
                    }
                }
            }
        }

        IconButton {
            id: upButton
            anchors.verticalCenter: parent.verticalCenter

            radius: 0
            radiusMorph: false
            isRound: false

            topRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.large
            bottomRightRadius: pressed ? Tokens.rounding.small : Tokens.rounding.large
            topLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall
            bottomLeftRadius: pressed ? Tokens.rounding.small : Tokens.rounding.extraSmall

            icon: "add"
            font: Tokens.font.icon.small
            disabled: root.value >= root.to
            disabledColour: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
            color: disabled ? disabledColour : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer)
            type: IconButton.Text
            padding: Tokens.padding.extraSmall

            onClicked: root.increase()
        }
    }

    Timer {
        id: repeatTimer
        running: upButton.pressed || downButton.pressed
        interval: root.repeatRate
        repeat: true
        onRunningChanged: {
            if (!running) interval = root.repeatRate;
        }
        onTriggered: {
            if (upButton.pressed) root.increase();
            else if (downButton.pressed) root.decrease();
            if (interval > root.repeatDecay) interval -= root.repeatDecay;
        }
    }
}
