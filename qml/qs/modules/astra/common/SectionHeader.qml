import QtQuick
import QtQuick.Layouts
import Helm.Config
import qs.components
import qs.services

StyledText {
    id: root

    property bool first: false

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.spacing.largeIncreased - (parent && parent.spacing !== undefined ? parent.spacing : 0)
    Layout.bottomMargin: Tokens.spacing.extraSmall
    Layout.leftMargin: Tokens.padding.small

    color: Colours.palette.m3onSurfaceVariant
    font: Tokens.font.label.medium
    elide: Text.ElideRight
}
