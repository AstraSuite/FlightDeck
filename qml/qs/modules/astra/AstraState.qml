import QtQuick

QtObject {
    property var screen: ({ height: 900, width: 1400 })
    property bool isWindow: true
    property bool animatingContainer
    property int currentPageIdx: 0
    property var subPageIdxStack: []
    property bool searchOpen
    property bool justUnlockedDevMode: false
    property string targetScreen: ""
    property string scrollToTarget: ""

    property string selectedWallpaperCategory
    property string wallpaperFilterType: "all"
    property var selectedBtDevice
    property var selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed
    signal focusSearchRequested
    signal refreshRequested
    signal scrollToRequested(string target)

    function openSubPage(idx: int): void {
        var copy = subPageIdxStack ? subPageIdxStack.slice() : [];
        copy.push(idx);
        subPageIdxStack = copy;
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        var copy = subPageIdxStack ? subPageIdxStack.slice() : [];
        copy.pop();
        subPageIdxStack = copy;
    }

    onCurrentPageIdxChanged: subPageIdxStack = []
}
