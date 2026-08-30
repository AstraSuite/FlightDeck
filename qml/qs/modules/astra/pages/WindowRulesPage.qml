import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FlightDeck.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.modules.astra.common
import FlightDeck.Caelestia 1.0

PageBase {
    id: root

    title: qsTr("Window rules")

    headerContent: Component {
        SearchBar {
            topPadding: Tokens.padding.small
            bottomPadding: Tokens.padding.small

            placeholderText: qsTr("Search window rules")
            font: Tokens.font.body.medium

            bg.color: Colours.tPalette.m3surfaceContainerLowest
            bg.border.color: Colours.palette.m3outlineVariant
            searchIcon.fontStyle: Tokens.font.icon.medium
            searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
            clearIcon.font: Tokens.font.icon.medium
            clearIcon.padding: Tokens.padding.extraSmall

            onTextChanged: root.searchText = text
        }
    }
    headerContentWidth: 240

    property string searchText: ""

    function windowRuleMatches(r) {
        const q = root.searchText.trim().toLowerCase();
        if (q === "") return true;
        const terms = q.split(/\s+/).filter(t => t.length > 0);

        let matchStr = "";
        if (r.match) {
            for (let k in r.match) {
                matchStr += " " + k + " " + r.match[k];
            }
        }
        let acts = [];
        if (r.float) acts.push("float");
        if (r.opaque) acts.push("opaque");
        if (r.pin) acts.push("pin");
        if (r.center) acts.push("center");
        if (r.noblur || r.no_blur) acts.push("no_blur noblur");
        if (r.fullscreen) acts.push("fullscreen");
        if (r.workspace) acts.push("workspace " + r.workspace);
        if (r.size) acts.push("size " + r.size);
        if (r.move) acts.push("move " + r.move);
        if (r.opacity) acts.push("opacity " + r.opacity);
        if (r.rounding !== undefined) acts.push("rounding " + r.rounding);
        if (r.sourcePath) acts.push(r.sourcePath);
        if (r.isReadOnly) acts.push("system readonly default");

        const hay = (matchStr + " " + acts.join(" ")).toLowerCase();
        for (let i = 0; i < terms.length; i++) {
            if (hay.indexOf(terms[i]) === -1) return false;
        }
        return true;
    }

    readonly property var filteredWindowRules: {
        const q = root.searchText.trim();
        const src = FlightDeckWriter.windowRules;
        if (q === "") return src;
        const out = [];
        for (let i = 0; i < src.length; i++) {
            if (root.windowRuleMatches(src[i])) {
                out.push(src[i]);
            }
        }
        return out;
    }

    function findMasterWindowRuleIndex(ruleData) {
        const list = FlightDeckWriter.windowRules;
        for (let i = 0; i < list.length; i++) {
            if (list[i] === ruleData) return i;
        }
        return -1;
    }

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        anchors.top: parent ? parent.top : undefined
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            visible: root.searchText.trim() === "" || root.filteredWindowRules.length > 0
            text: qsTr("Window Rules")
        }

        // Add Window Rule via DialogRowButton (connected to rules list below)
        DialogRowButton {
            id: addRuleBtn
            rootParent: root.modalOverlay
            visible: root.searchText.trim() === ""
            first: true
            last: FlightDeckWriter.windowRules.length === 0
            icon: "add_circle"
            label: qsTr("Add Window Rule")
            header: qsTr("Add New Window Rule")
            acceptLabel: qsTr("Save Rule")
            separateContent: true
            horizontalContentMargin: -Tokens.padding.small
            openWidth: Math.min((rootParent ? rootParent.width : 560) * 0.95, 540)
            customOpenHeight: Math.min((rootParent ? rootParent.height : 700) * 0.95, 620)

            property string matchClass: ""
            property string matchTitle: ""
            property string matchInitialClass: ""
            property string matchInitialTitle: ""
            property string matchWorkspace: ""
            property string matchTag: ""
            property bool matchXWayland: false
            property bool matchModal: false
            property bool matchFloating: false
            property bool matchFullscreen: false
            property bool matchPinned: false

            property bool isFloat: true
            property bool isPin: false
            property bool isCenter: false
            property bool isOpaque: false
            property bool isNoBlur: false
            property bool isFullscreen: false
            property string targetWorkspace: ""
            property string targetSize: ""
            property string targetMove: ""
            property string targetOpacity: ""
            property string targetRounding: ""

            acceptAllowed: matchClass.trim() !== "" || matchTitle.trim() !== "" || matchInitialClass.trim() !== "" || matchInitialTitle.trim() !== "" || matchWorkspace.trim() !== "" || matchTag.trim() !== "" || matchXWayland || matchModal || matchFloating || matchPinned

            function resetFields() {
                matchClass = "";
                matchTitle = "";
                matchInitialClass = "";
                matchInitialTitle = "";
                matchWorkspace = "";
                matchTag = "";
                matchXWayland = false;
                matchModal = false;
                matchFloating = false;
                matchFullscreen = false;
                matchPinned = false;

                isFloat = true;
                isPin = false;
                isCenter = false;
                isOpaque = false;
                isNoBlur = false;
                isFullscreen = false;
                targetWorkspace = "";
                targetSize = "";
                targetMove = "";
                targetOpacity = "";
                targetRounding = "";
            }

            onAccepted: {
                var ruleMap = {
                    "match": {}
                };
                if (matchClass.trim() !== "") ruleMap.match["class"] = matchClass.trim();
                if (matchTitle.trim() !== "") ruleMap.match["title"] = matchTitle.trim();
                if (matchInitialClass.trim() !== "") ruleMap.match["initial_class"] = matchInitialClass.trim();
                if (matchInitialTitle.trim() !== "") ruleMap.match["initial_title"] = matchInitialTitle.trim();
                if (matchWorkspace.trim() !== "") ruleMap.match["workspace"] = matchWorkspace.trim();
                if (matchTag.trim() !== "") ruleMap.match["tag"] = matchTag.trim();
                if (matchXWayland) ruleMap.match["xwayland"] = true;
                if (matchModal) ruleMap.match["modal"] = true;
                if (matchFloating) ruleMap.match["float"] = true;
                if (matchFullscreen) ruleMap.match["fullscreen"] = true;
                if (matchPinned) ruleMap.match["pin"] = true;

                if (isFloat) ruleMap["float"] = true;
                if (isPin) ruleMap["pin"] = true;
                if (isCenter) ruleMap["center"] = true;
                if (isOpaque) ruleMap["opaque"] = true;
                if (isNoBlur) ruleMap["no_blur"] = true;
                if (isFullscreen) ruleMap["fullscreen"] = true;
                if (targetWorkspace.trim() !== "") ruleMap["workspace"] = targetWorkspace.trim();
                if (targetSize.trim() !== "") ruleMap["size"] = targetSize.trim();
                if (targetMove.trim() !== "") ruleMap["move"] = targetMove.trim();
                if (targetOpacity.trim() !== "") ruleMap["opacity"] = targetOpacity.trim();
                if (targetRounding.trim() !== "") {
                    var rVal = parseInt(targetRounding.trim());
                    ruleMap["rounding"] = isNaN(rVal) ? targetRounding.trim() : rVal;
                }

                FlightDeckWriter.addWindowRule(ruleMap);
                FlightDeckWriter.save();
                resetFields();
            }

            content: Component {
                VerticalFadeFlickable {
                    id: addFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: addCol.implicitHeight + (Tokens.padding?.medium ?? 12)
                    topMargin: Tokens.padding.medium
                    bottomMargin: Tokens.padding.medium
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: addCol
                        width: addFlick.width - (Tokens.padding?.small ?? 8) * 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Tokens.spacing.medium

                        StyledText {
                            text: qsTr("Window Match Criteria")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Window class regex (e.g. ^(zen|firefox)$)")
                                text: addRuleBtn.matchClass
                                onTextEdited: addRuleBtn.matchClass = text
                            }

                            ClientPickerPopup {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: Tokens.padding?.extraSmall ?? 4
                                rootParent: root.modalOverlay
                                onClientSelected: (winClass, winTitle, initClass, initTitle) => {
                                    if (winClass) addRuleBtn.matchClass = "^(" + winClass + ")$";
                                    if (winTitle) addRuleBtn.matchTitle = "^(" + winTitle + ")$";
                                    if (initClass) addRuleBtn.matchInitialClass = "^(" + initClass + ")$";
                                    if (initTitle) addRuleBtn.matchInitialTitle = "^(" + initTitle + ")$";
                                }
                            }
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Window title regex (Optional, e.g. ^(Picture.*)$)")
                            text: addRuleBtn.matchTitle
                            onTextEdited: addRuleBtn.matchTitle = text
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Initial class regex (Optional)")
                            text: addRuleBtn.matchInitialClass
                            onTextEdited: addRuleBtn.matchInitialClass = text
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Initial title regex (Optional)")
                            text: addRuleBtn.matchInitialTitle
                            onTextEdited: addRuleBtn.matchInitialTitle = text
                        }

                        StyledText {
                            text: qsTr("Match Modifiers")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                            Layout.topMargin: Tokens.spacing.extraSmall / 2
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            ToggleRow {
                                first: true
                                text: qsTr("XWayland Window Only")
                                subtext: qsTr("Match windows running under XWayland")
                                checked: addRuleBtn.matchXWayland
                                onToggled: addRuleBtn.matchXWayland = checked
                            }

                            ToggleRow {
                                text: qsTr("Modal Dialog Only")
                                subtext: qsTr("Match dialog and confirmation windows")
                                checked: addRuleBtn.matchModal
                                onToggled: addRuleBtn.matchModal = checked
                            }

                            ToggleRow {
                                text: qsTr("Floating Window Only")
                                subtext: qsTr("Match currently floating windows")
                                checked: addRuleBtn.matchFloating
                                onToggled: addRuleBtn.matchFloating = checked
                            }

                            ToggleRow {
                                last: true
                                text: qsTr("Pinned Window Only")
                                subtext: qsTr("Match pinned windows across workspaces")
                                checked: addRuleBtn.matchPinned
                                onToggled: addRuleBtn.matchPinned = checked
                            }
                        }

                        StyledText {
                            text: qsTr("Window Actions & Effects")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.topMargin: Tokens.spacing.extraSmall
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall / 2

                            ToggleRow {
                                first: true
                                text: qsTr("Float Window")
                                subtext: qsTr("Open matched windows in floating mode")
                                checked: addRuleBtn.isFloat
                                onToggled: addRuleBtn.isFloat = checked
                            }

                            ToggleRow {
                                text: qsTr("Pin Window")
                                subtext: qsTr("Stay visible across all workspaces")
                                checked: addRuleBtn.isPin
                                onToggled: addRuleBtn.isPin = checked
                            }

                            ToggleRow {
                                text: qsTr("Center Window")
                                subtext: qsTr("Center floating window upon creation")
                                checked: addRuleBtn.isCenter
                                onToggled: addRuleBtn.isCenter = checked
                            }

                            ToggleRow {
                                text: qsTr("Fullscreen Window")
                                subtext: qsTr("Launch window in fullscreen mode")
                                checked: addRuleBtn.isFullscreen
                                onToggled: addRuleBtn.isFullscreen = checked
                            }

                            ToggleRow {
                                text: qsTr("Force Opaque")
                                subtext: qsTr("Disable transparency for this application")
                                checked: addRuleBtn.isOpaque
                                onToggled: addRuleBtn.isOpaque = checked
                            }

                            ToggleRow {
                                last: true
                                text: qsTr("No Blur")
                                subtext: qsTr("Disable backdrop blur behind window")
                                checked: addRuleBtn.isNoBlur
                                onToggled: addRuleBtn.isNoBlur = checked
                            }
                        }

                        StyledText {
                            text: qsTr("Placement & Size (Optional)")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                            Layout.topMargin: Tokens.spacing.extraSmall
                        }

                        StyledTextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Assign Workspace (e.g. 1, 2, special:communication)")
                            text: addRuleBtn.targetWorkspace
                            onTextEdited: addRuleBtn.targetWorkspace = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Initial Size (e.g. 1280 720)")
                                text: addRuleBtn.targetSize
                                onTextEdited: addRuleBtn.targetSize = text
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Initial Position (e.g. 100 100)")
                                text: addRuleBtn.targetMove
                                onTextEdited: addRuleBtn.targetMove = text
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Opacity (e.g. 0.95 or 0.9 0.8)")
                                text: addRuleBtn.targetOpacity
                                onTextEdited: addRuleBtn.targetOpacity = text
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Corner Rounding (px, e.g. 12)")
                                text: addRuleBtn.targetRounding
                                onTextEdited: addRuleBtn.targetRounding = text
                            }
                        }
                    }
                }
            }
        }

        // Each Configured Rule is its own DialogRowButton
        Repeater {
            model: root.filteredWindowRules

            delegate: DialogRowButton {
                id: editRuleRow
                required property var modelData
                required property int index

                readonly property bool isReadOnly: editRuleRow.modelData ? (editRuleRow.modelData.isReadOnly || false) : false

                rootParent: root.modalOverlay
                first: index === 0 && root.searchText.trim() !== ""
                last: index === root.filteredWindowRules.length - 1
                icon: editRuleRow.isReadOnly ? "tune" : "web_asset"

                label: {
                    var r = editRuleRow.modelData;
                    var acts = [];
                    if (r.float) acts.push(qsTr("Float"));
                    if (r.opaque) acts.push(qsTr("Force opaque"));
                    if (r.pin) acts.push(qsTr("Pin"));
                    if (r.center) acts.push(qsTr("Center"));
                    if (r.noblur || r.no_blur) acts.push(qsTr("No blur"));
                    if (r.fullscreen) acts.push(qsTr("Fullscreen"));
                    if (r.workspace) acts.push(qsTr("Workspace %1").arg(r.workspace));
                    if (r.size) acts.push(qsTr("Size %1").arg(r.size));
                    if (r.opacity) acts.push(qsTr("Opacity %1").arg(r.opacity));
                    if (r.rounding !== undefined) acts.push(qsTr("Rounding %1px").arg(r.rounding));
                    return acts.length > 0 ? acts.join(" + ") : (r.name || qsTr("Window Rule"));
                }

                subtext: {
                    var r = editRuleRow.modelData;
                    var conds = [];
                    if (r.match) {
                        for (var k in r.match) {
                            var val = r.match[k];
                            if (val === true) {
                                conds.push(k);
                            } else {
                                conds.push(k + ": " + val);
                            }
                        }
                    }
                    var txt = conds.length > 0 ? conds.join(" • ") : qsTr("Default matching");
                    if (editRuleRow.isReadOnly) {
                        txt += " • " + qsTr("System default");
                    }
                    return txt;
                }

                header: editRuleRow.isReadOnly ? qsTr("Override Window Rule") : qsTr("Edit Window Rule")
                acceptLabel: editRuleRow.isReadOnly ? qsTr("Save Override") : qsTr("Save Changes")
                separateContent: true
                horizontalContentMargin: -Tokens.padding.small
                openWidth: Math.min((rootParent ? rootParent.width : 560) * 0.95, 540)
                customOpenHeight: Math.min((rootParent ? rootParent.height : 700) * 0.95, 620)

                property string matchClass: ""
                property string matchTitle: ""
                property string matchInitialClass: ""
                property string matchInitialTitle: ""
                property string matchWorkspace: ""
                property string matchTag: ""
                property bool matchXWayland: false
                property bool matchModal: false
                property bool matchFloating: false
                property bool matchFullscreen: false
                property bool matchPinned: false

                property bool isFloat: false
                property bool isPin: false
                property bool isCenter: false
                property bool isOpaque: false
                property bool isNoBlur: false
                property bool isFullscreen: false
                property string targetWorkspace: ""
                property string targetSize: ""
                property string targetMove: ""
                property string targetOpacity: ""
                property string targetRounding: ""

                acceptAllowed: matchClass.trim() !== "" || matchTitle.trim() !== "" || matchInitialClass.trim() !== "" || matchInitialTitle.trim() !== "" || matchWorkspace.trim() !== "" || matchTag.trim() !== "" || matchXWayland || matchModal || matchFloating || matchPinned

                onOpenChanged: {
                    if (open && editRuleRow.modelData) {
                        var r = editRuleRow.modelData;
                        var m = r.match || {};
                        matchClass = m["class"] || "";
                        matchTitle = m["title"] || "";
                        matchInitialClass = m["initial_class"] || m["initialClass"] || "";
                        matchInitialTitle = m["initial_title"] || m["initialTitle"] || "";
                        matchWorkspace = m["workspace"] || "";
                        matchTag = m["tag"] || "";
                        matchXWayland = !!m["xwayland"];
                        matchModal = !!m["modal"];
                        matchFloating = !!(m["float"] || m["floating"]);
                        matchFullscreen = !!m["fullscreen"];
                        matchPinned = !!(m["pin"] || m["pinned"]);

                        isFloat = !!r.float;
                        isPin = !!r.pin;
                        isCenter = !!r.center;
                        isOpaque = !!r.opaque;
                        isNoBlur = !!(r.noblur || r.no_blur);
                        isFullscreen = !!r.fullscreen;
                        targetWorkspace = r.workspace || "";
                        targetSize = r.size ? String(r.size) : "";
                        targetMove = r.move ? String(r.move) : "";
                        targetOpacity = r.opacity ? String(r.opacity) : "";
                        targetRounding = r.rounding !== undefined ? String(r.rounding) : "";
                    }
                }

                onAccepted: {
                    var ruleMap = {
                        "match": {}
                    };
                    if (matchClass.trim() !== "") ruleMap.match["class"] = matchClass.trim();
                    if (matchTitle.trim() !== "") ruleMap.match["title"] = matchTitle.trim();
                    if (matchInitialClass.trim() !== "") ruleMap.match["initial_class"] = matchInitialClass.trim();
                    if (matchInitialTitle.trim() !== "") ruleMap.match["initial_title"] = matchInitialTitle.trim();
                    if (matchWorkspace.trim() !== "") ruleMap.match["workspace"] = matchWorkspace.trim();
                    if (matchTag.trim() !== "") ruleMap.match["tag"] = matchTag.trim();
                    if (matchXWayland) ruleMap.match["xwayland"] = true;
                    if (matchModal) ruleMap.match["modal"] = true;
                    if (matchFloating) ruleMap.match["float"] = true;
                    if (matchFullscreen) ruleMap.match["fullscreen"] = true;
                    if (matchPinned) ruleMap.match["pin"] = true;

                    if (isFloat) ruleMap["float"] = true;
                    if (isPin) ruleMap["pin"] = true;
                    if (isCenter) ruleMap["center"] = true;
                    if (isOpaque) ruleMap["opaque"] = true;
                    if (isNoBlur) ruleMap["no_blur"] = true;
                    if (isFullscreen) ruleMap["fullscreen"] = true;
                    if (targetWorkspace.trim() !== "") ruleMap["workspace"] = targetWorkspace.trim();
                    if (targetSize.trim() !== "") ruleMap["size"] = targetSize.trim();
                    if (targetMove.trim() !== "") ruleMap["move"] = targetMove.trim();
                    if (targetOpacity.trim() !== "") ruleMap["opacity"] = targetOpacity.trim();
                    if (targetRounding.trim() !== "") {
                        var rVal = parseInt(targetRounding.trim());
                        ruleMap["rounding"] = isNaN(rVal) ? targetRounding.trim() : rVal;
                    }

                    var masterIdx = root.findMasterWindowRuleIndex(editRuleRow.modelData);
                    if (masterIdx !== -1) {
                        FlightDeckWriter.updateWindowRule(masterIdx, ruleMap);
                        FlightDeckWriter.save();
                    }
                }

                trailingActions: Component {
                    RowLayout {
                        spacing: 0

                        IconButton {
                            visible: !editRuleRow.isReadOnly
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                var masterIdx = root.findMasterWindowRuleIndex(editRuleRow.modelData);
                                if (masterIdx !== -1) {
                                    FlightDeckWriter.removeWindowRule(masterIdx);
                                    FlightDeckWriter.save();
                                }
                            }
                        }
                    }
                }

                content: Component {
                    VerticalFadeFlickable {
                        id: editFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: editCol.implicitHeight + (Tokens.padding?.medium ?? 12)
                        topMargin: Tokens.padding.medium
                        bottomMargin: Tokens.padding.medium
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: editCol
                            width: editFlick.width - (Tokens.padding?.small ?? 8) * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Window Match Criteria")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledTextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Window class regex (e.g. ^(zen|firefox)$)")
                                    text: editRuleRow.matchClass
                                    onTextEdited: editRuleRow.matchClass = text
                                }

                                ClientPickerPopup {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.rightMargin: Tokens.padding?.extraSmall ?? 4
                                    rootParent: root.modalOverlay
                                    onClientSelected: (winClass, winTitle, initClass, initTitle) => {
                                        if (winClass) editRuleRow.matchClass = "^(" + winClass + ")$";
                                        if (winTitle) editRuleRow.matchTitle = "^(" + winTitle + ")$";
                                        if (initClass) editRuleRow.matchInitialClass = "^(" + initClass + ")$";
                                        if (initTitle) editRuleRow.matchInitialTitle = "^(" + initTitle + ")$";
                                    }
                                }
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Window title regex (Optional, e.g. ^(Picture.*)$)")
                                text: editRuleRow.matchTitle
                                onTextEdited: editRuleRow.matchTitle = text
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Initial class regex (Optional)")
                                text: editRuleRow.matchInitialClass
                                onTextEdited: editRuleRow.matchInitialClass = text
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Initial title regex (Optional)")
                                text: editRuleRow.matchInitialTitle
                                onTextEdited: editRuleRow.matchInitialTitle = text
                            }

                            StyledText {
                                text: qsTr("Match Modifiers")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                                Layout.topMargin: Tokens.spacing.extraSmall / 2
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                ToggleRow {
                                    first: true
                                    text: qsTr("XWayland Window Only")
                                    subtext: qsTr("Match windows running under XWayland")
                                    checked: editRuleRow.matchXWayland
                                    onToggled: editRuleRow.matchXWayland = checked
                                }

                                ToggleRow {
                                    text: qsTr("Modal Dialog Only")
                                    subtext: qsTr("Match dialog and confirmation windows")
                                    checked: editRuleRow.matchModal
                                    onToggled: editRuleRow.matchModal = checked
                                }

                                ToggleRow {
                                    text: qsTr("Floating Window Only")
                                    subtext: qsTr("Match currently floating windows")
                                    checked: editRuleRow.matchFloating
                                    onToggled: editRuleRow.matchFloating = checked
                                }

                                ToggleRow {
                                    last: true
                                    text: qsTr("Pinned Window Only")
                                    subtext: qsTr("Match pinned windows across workspaces")
                                    checked: editRuleRow.matchPinned
                                    onToggled: editRuleRow.matchPinned = checked
                                }
                            }

                            StyledText {
                                text: qsTr("Window Actions & Effects")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                Layout.topMargin: Tokens.spacing.extraSmall
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall / 2

                                ToggleRow {
                                    first: true
                                    text: qsTr("Float Window")
                                    subtext: qsTr("Open matched windows in floating mode")
                                    checked: editRuleRow.isFloat
                                    onToggled: editRuleRow.isFloat = checked
                                }

                                ToggleRow {
                                    text: qsTr("Pin Window")
                                    subtext: qsTr("Stay visible across all workspaces")
                                    checked: editRuleRow.isPin
                                    onToggled: editRuleRow.isPin = checked
                                }

                                ToggleRow {
                                    text: qsTr("Center Window")
                                    subtext: qsTr("Center floating window upon creation")
                                    checked: editRuleRow.isCenter
                                    onToggled: editRuleRow.isCenter = checked
                                }

                                ToggleRow {
                                    text: qsTr("Fullscreen Window")
                                    subtext: qsTr("Launch window in fullscreen mode")
                                    checked: editRuleRow.isFullscreen
                                    onToggled: editRuleRow.isFullscreen = checked
                                }

                                ToggleRow {
                                    text: qsTr("Force Opaque")
                                    subtext: qsTr("Disable transparency for this application")
                                    checked: editRuleRow.isOpaque
                                    onToggled: editRuleRow.isOpaque = checked
                                }

                                ToggleRow {
                                    last: true
                                    text: qsTr("No Blur")
                                    subtext: qsTr("Disable backdrop blur behind window")
                                    checked: editRuleRow.isNoBlur
                                    onToggled: editRuleRow.isNoBlur = checked
                                }
                            }

                            StyledText {
                                text: qsTr("Placement & Size (Optional)")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                Layout.topMargin: Tokens.spacing.extraSmall
                            }

                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("Assign Workspace (e.g. 1, 2, special:communication)")
                                text: editRuleRow.targetWorkspace
                                onTextEdited: editRuleRow.targetWorkspace = text
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledTextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Initial Size (e.g. 1280 720)")
                                    text: editRuleRow.targetSize
                                    onTextEdited: editRuleRow.targetSize = text
                                }

                                StyledTextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Initial Position (e.g. 100 100)")
                                    text: editRuleRow.targetMove
                                    onTextEdited: editRuleRow.targetMove = text
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                StyledTextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Opacity (e.g. 0.95 or 0.9 0.8)")
                                    text: editRuleRow.targetOpacity
                                    onTextEdited: editRuleRow.targetOpacity = text
                                }

                                StyledTextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Corner Rounding (px, e.g. 12)")
                                    text: editRuleRow.targetRounding
                                    onTextEdited: editRuleRow.targetRounding = text
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            visible: FlightDeckWriter.windowRules.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No custom window rules defined yet.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }

        Item {
            visible: root.searchText.trim() !== "" && root.filteredWindowRules.length === 0 && FlightDeckWriter.windowRules.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            StyledText {
                anchors.centerIn: parent
                text: qsTr("No window rules matching \"%1\"").arg(root.searchText.trim())
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }

        Item {
            Layout.preferredHeight: Tokens.padding.large
            Layout.fillWidth: true
        }
    }
}
