import QtQuick
import QtQuick.Window
import QtQuick.Controls
import qs.services
import qs.modules.astra
import Helm.Caelestia 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 1080
    height: 600
    minimumWidth: 800
    minimumHeight: 500
    title: "FlightDeck"
    color: Colours.palette.m3surface

    onClosing: {
        Qt.quit();
    }

    Astra {
        id: astraUi
        anchors.fill: parent
        anchors.margins: 0

        onClose: {
            window.close();
            Qt.quit();
        }
    }
}
