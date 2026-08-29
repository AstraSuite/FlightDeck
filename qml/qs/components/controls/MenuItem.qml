import QtQuick

QtObject {
    property string text: ""
    property string icon: ""
    property string trailingIcon: ""
    property string activeIcon: icon
    property string activeText: text
    property color previewColor: "transparent"

    signal clicked()
}
