#include "caelestiavars.hpp"
#include "luavalidator.hpp"
#include "flightdeckwriter.hpp"
#include "../hyprland/hyprlandsocket.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

namespace FlightDeck::Caelestia {

CaelestiaVars* CaelestiaVars::instance() {
    static CaelestiaVars inst;
    return &inst;
}

CaelestiaVars* CaelestiaVars::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QString CaelestiaVars::varsFilePath() {
    return QDir::homePath() + QStringLiteral("/.config/caelestia/hypr-vars.lua");
}

QString CaelestiaVars::defaultVarsFilePath() {
    return QDir::homePath() + QStringLiteral("/.config/hypr/variables.lua");
}

QString CaelestiaVars::schemeFilePath() {
    return QDir::homePath() + QStringLiteral("/.config/hypr/scheme/current.lua");
}

CaelestiaVars::CaelestiaVars(QObject* parent)
    : QObject(parent) {
    loadDefaults();
    loadFromFile();
}

QVariantList CaelestiaVars::schemeColors() const {
    return getSchemeColors();
}

QVariantList CaelestiaVars::getSchemeColors() const {
    QVariantList list;
    const QString path = schemeFilePath();
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return list;
    }

    const QString content = QString::fromUtf8(file.readAll());
    file.close();

    static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*\"([0-9a-fA-F]{6})\"\s*,?)"), QRegularExpression::MultilineOption);
    auto matchIt = lineRe.globalMatch(content);
    while (matchIt.hasNext()) {
        auto m = matchIt.next();
        const QString name = m.captured(1);
        const QString hex = m.captured(2);

        QVariantMap item;
        item[QStringLiteral("name")] = name;
        item[QStringLiteral("hex")] = hex;
        item[QStringLiteral("color")] = QStringLiteral("#") + hex;
        list.append(item);
    }
    return list;
}

QString CaelestiaVars::getSchemeHex(const QString& token) const {
    const QVariantList colors = getSchemeColors();
    for (const QVariant& c : colors) {
        const QVariantMap m = c.toMap();
        if (m.value(QStringLiteral("name")).toString() == token) {
            return m.value(QStringLiteral("hex")).toString();
        }
    }
    return QStringLiteral("9bd0cc"); // Fallback primary
}

QVariantMap CaelestiaVars::parseColor(const QString& colorStr) const {
    QVariantMap res;
    QString clean = colorStr.trimmed();

    // Pattern 1: scheme.<token> .. "<alphaHex>" (e.g. "rgba(" .. scheme.shadow .. "60)" or rgba(" .. scheme.shadow .. "60)")
    static const QRegularExpression schemeRe(QStringLiteral(R"(scheme\.([a-zA-Z0-9_]+)\s*\.\.\s*\"([0-9a-fA-F]{2})\")"));
    auto sm = schemeRe.match(clean);
    if (sm.hasMatch()) {
        QString token = sm.captured(1);
        QString alphaHex = sm.captured(2);
        bool ok = false;
        int alphaVal = alphaHex.toInt(&ok, 16);
        int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;
        QString hex = getSchemeHex(token);

        res[QStringLiteral("isScheme")] = true;
        res[QStringLiteral("token")] = token;
        res[QStringLiteral("hex")] = hex;
        res[QStringLiteral("alphaPercent")] = alphaPercent;
        res[QStringLiteral("alphaHex")] = alphaHex;
        res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
        res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(\" .. scheme.%1 .. \"%2)\"").arg(token, alphaHex);
        return res;
    }

    // Pattern 2: rgba(RRGGBBAA) or rgba("RRGGBBAA") or "rgba(RRGGBBAA)"
    static const QRegularExpression rgbaRe(QStringLiteral(R"(rgba\(\"?([0-9a-fA-F]{6})([0-9a-fA-F]{2})\"?\))"));
    auto rm = rgbaRe.match(clean);
    if (rm.hasMatch()) {
        QString hex = rm.captured(1);
        QString alphaHex = rm.captured(2);
        bool ok = false;
        int alphaVal = alphaHex.toInt(&ok, 16);
        int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;

        res[QStringLiteral("isScheme")] = false;
        res[QStringLiteral("token")] = QString();
        res[QStringLiteral("hex")] = hex;
        res[QStringLiteral("alphaPercent")] = alphaPercent;
        res[QStringLiteral("alphaHex")] = alphaHex;
        res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
        res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1%2)\"").arg(hex, alphaHex);
        return res;
    }

    // Pattern 3: #RRGGBBAA or #RRGGBB
    if (clean.startsWith(QLatin1Char('#')) || (clean.startsWith(QLatin1Char('"')) && clean.contains(QLatin1Char('#')))) {
        QString raw = clean;
        raw.remove(QLatin1Char('"'));
        raw.remove(QLatin1Char('\''));
        raw.remove(QLatin1Char('#'));
        if (raw.length() >= 8) {
            QString hex = raw.left(6);
            QString alphaHex = raw.mid(6, 2);
            bool ok = false;
            int alphaVal = alphaHex.toInt(&ok, 16);
            int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;

            res[QStringLiteral("isScheme")] = false;
            res[QStringLiteral("token")] = QString();
            res[QStringLiteral("hex")] = hex;
            res[QStringLiteral("alphaPercent")] = alphaPercent;
            res[QStringLiteral("alphaHex")] = alphaHex;
            res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
            res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1%2)\"").arg(hex, alphaHex);
            return res;
        } else if (raw.length() >= 6) {
            QString hex = raw.left(6);
            res[QStringLiteral("isScheme")] = false;
            res[QStringLiteral("token")] = QString();
            res[QStringLiteral("hex")] = hex;
            res[QStringLiteral("alphaPercent")] = 100;
            res[QStringLiteral("alphaHex")] = QStringLiteral("ff");
            res[QStringLiteral("previewColor")] = QStringLiteral("#ff") + hex;
            res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1ff)\"").arg(hex);
            return res;
        }
    }

    // Fallback default
    res[QStringLiteral("isScheme")] = true;
    res[QStringLiteral("token")] = QStringLiteral("shadow");
    res[QStringLiteral("hex")] = getSchemeHex(QStringLiteral("shadow"));
    res[QStringLiteral("alphaPercent")] = 38;
    res[QStringLiteral("alphaHex")] = QStringLiteral("60");
    res[QStringLiteral("previewColor")] = QStringLiteral("#60") + res[QStringLiteral("hex")].toString();
    res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(\" .. scheme.shadow .. \"60)\"");
    return res;
}

QString CaelestiaVars::formatColor(bool isScheme, const QString& tokenOrHex, int alphaPercent) const {
    int clampedAlpha = qBound(0, alphaPercent, 100);
    int alphaVal = qBound(0, qRound(clampedAlpha * 2.55), 255);
    QString alphaHex = QStringLiteral("%1").arg(alphaVal, 2, 16, QLatin1Char('0')).toLower();

    if (isScheme) {
        return QStringLiteral("\"rgba(\" .. scheme.%1 .. \"%2)\"").arg(tokenOrHex, alphaHex);
    }

    QString cleanHex = tokenOrHex.trimmed();
    if (cleanHex.startsWith(QLatin1Char('#'))) {
        cleanHex.remove(0, 1);
    }
    if (cleanHex.length() > 6) {
        cleanHex = cleanHex.left(6);
    }
    return QStringLiteral("\"rgba(%1%2)\"").arg(cleanHex, alphaHex);
}

void CaelestiaVars::loadDefaults() {
    m_defaults = QVariantMap{
        // Apps
        { QStringLiteral("terminal"), QStringLiteral("foot") },
        { QStringLiteral("browser"), QStringLiteral("firefox") },
        { QStringLiteral("editor"), QStringLiteral("codium") },
        { QStringLiteral("fileExplorer"), QStringLiteral("thunar") },
        { QStringLiteral("audioSettings"), QStringLiteral("pwvucontrol") },

        // Touchpad & Gestures
        { QStringLiteral("touchpadDisableTyping"), true },
        { QStringLiteral("touchpadScrollFactor"), 0.3 },
        { QStringLiteral("gestureFingers"), 3 },
        { QStringLiteral("workspaceSwipeFingers"), 4 },
        { QStringLiteral("gestureFingersMore"), 4 },
        { QStringLiteral("sleepGestureCmd"), QStringLiteral("systemctl suspend-then-hibernate") },
        { QStringLiteral("touchpadTapToClick"), true },
        { QStringLiteral("touchpadClickfingerBehavior"), false },
        { QStringLiteral("touchpadMiddleButtonEmulation"), false },
        { QStringLiteral("touchpadDragLock"), 0 },
        { QStringLiteral("touchpadTapButtonMap"), QStringLiteral("") },
        { QStringLiteral("workspaceSwipeCreateNew"), true },
        { QStringLiteral("workspaceSwipeForever"), false },
        { QStringLiteral("workspaceSwipeCancelRatio"), 0.5 },
        { QStringLiteral("workspaceSwipeMinSpeedToForce"), 30 },
        { QStringLiteral("workspaceSwipeDirectionLock"), true },
        { QStringLiteral("workspaceSwipeUseR"), false },
        { QStringLiteral("workspaceSwipeDistance"), 300 },
        { QStringLiteral("workspaceSwipeInvert"), false },

        // Blur
        { QStringLiteral("blurEnabled"), true },
        { QStringLiteral("blurSpecialWs"), false },
        { QStringLiteral("blurPopups"), true },
        { QStringLiteral("blurInputMethods"), true },
        { QStringLiteral("blurSize"), 8 },
        { QStringLiteral("blurPasses"), 2 },
        { QStringLiteral("blurXray"), false },
        { QStringLiteral("blurIgnoreOpacity"), false },
        { QStringLiteral("blurNoise"), 0.0117 },
        { QStringLiteral("blurContrast"), 0.8916 },
        { QStringLiteral("blurBrightness"), 0.8172 },
        { QStringLiteral("blurVibrancy"), 0.1696 },
        { QStringLiteral("blurVibrancyDarkness"), 0.0 },

        // Shadow
        { QStringLiteral("shadowEnabled"), true },
        { QStringLiteral("shadowRange"), 15 },
        { QStringLiteral("shadowRenderPower"), 4 },
        { QStringLiteral("shadowOffset"), QStringLiteral("0 0") },
        { QStringLiteral("shadowScale"), 1.0 },
        { QStringLiteral("shadowColour"), QStringLiteral("rgba(\" .. scheme.shadow .. \"60)") },
        { QStringLiteral("shadowColor"), QStringLiteral("rgba(\" .. scheme.shadow .. \"60)") },
        { QStringLiteral("inactiveShadowColour"), QStringLiteral("rgba(\" .. scheme.shadow .. \"30)") },
        { QStringLiteral("inactiveShadowColor"), QStringLiteral("rgba(\" .. scheme.shadow .. \"30)") },

        // Gaps
        { QStringLiteral("workspaceGaps"), 20 },
        { QStringLiteral("windowGapsIn"), 5 },
        { QStringLiteral("windowGapsOut"), 10 },
        { QStringLiteral("singleWindowGapsOut"), 20 },

        // Window styling & Borders
        { QStringLiteral("windowOpacity"), 0.95 },
        { QStringLiteral("activeWindowOpacity"), 1.0 },
        { QStringLiteral("inactiveWindowOpacity"), 0.95 },
        { QStringLiteral("fullscreenWindowOpacity"), 1.0 },
        { QStringLiteral("fullscreenOpacity"), 1.0 },
        { QStringLiteral("windowRounding"), 15 },
        { QStringLiteral("windowRoundingPower"), 2.0 },
        { QStringLiteral("windowBorderSize"), 1 },
        { QStringLiteral("resizeOnBorder"), true },
        { QStringLiteral("extendBorderGrabArea"), 15 },
        { QStringLiteral("hoverIconOnBorder"), true },
        { QStringLiteral("allowTearing"), false },
        { QStringLiteral("layout"), QStringLiteral("dwindle") },
        { QStringLiteral("activeWindowBorderColour"), QStringLiteral("rgba(\" .. scheme.primary .. \"e6)") },
        { QStringLiteral("activeWindowBorderColor"), QStringLiteral("rgba(\" .. scheme.primary .. \"e6)") },
        { QStringLiteral("inactiveWindowBorderColour"), QStringLiteral("rgba(\" .. scheme.onSurfaceVariant .. \"11)") },
        { QStringLiteral("inactiveWindowBorderColor"), QStringLiteral("rgba(\" .. scheme.onSurfaceVariant .. \"11)") },

        // Dimming
        { QStringLiteral("dimInactive"), false },
        { QStringLiteral("dimStrength"), 0.5 },
        { QStringLiteral("dimAround"), 0.4 },
        { QStringLiteral("dimSpecial"), 0.2 },

        // Snap
        { QStringLiteral("snapEnabled"), false },
        { QStringLiteral("snapWindowGap"), 10 },
        { QStringLiteral("snapMonitorGap"), 10 },
        { QStringLiteral("snapBorderOverlap"), false },
        { QStringLiteral("snapRespectGaps"), false },

        // Cursor
        { QStringLiteral("cursorTheme"), QStringLiteral("sweet-cursors") },
        { QStringLiteral("cursorSize"), 24 },
        { QStringLiteral("cursorNoHardwareCursors"), false },
        { QStringLiteral("cursorEnableHyprcursor"), true },
        { QStringLiteral("cursorNoWarps"), false },
        { QStringLiteral("cursorPersistentWarps"), false },
        { QStringLiteral("cursorWarpOnChangeWorkspace"), false },
        { QStringLiteral("cursorZoomFactor"), 1.0 },
        { QStringLiteral("cursorInactiveTimeout"), 0 },
        { QStringLiteral("cursorHideOnKeyPress"), false },
        { QStringLiteral("cursorHideOnTouch"), false },
        { QStringLiteral("cursorHideOnTablet"), false },

        // Keyboard & Mouse
        { QStringLiteral("kbLayout"), QStringLiteral("us") },
        { QStringLiteral("kbVariant"), QStringLiteral("") },
        { QStringLiteral("kbOptions"), QStringLiteral("") },
        { QStringLiteral("numlockByDefault"), false },
        { QStringLiteral("keyRepeatRate"), 25 },
        { QStringLiteral("keyRepeatDelay"), 600 },
        { QStringLiteral("mouseSensitivity"), 0.0 },
        { QStringLiteral("mouseAccelProfile"), QStringLiteral("") },
        { QStringLiteral("followMouse"), 1 },
        { QStringLiteral("mouseNaturalScroll"), false },
        { QStringLiteral("mouseScrollFactor"), 1.0 },
        { QStringLiteral("leftHandedMode"), false },
        { QStringLiteral("mouseRefocus"), false },
        { QStringLiteral("floatSwitchOverrideFocus"), 1 },

        // Layout Engines (Dwindle, Master, Scrolling)
        { QStringLiteral("dwindlePreserveSplit"), true },
        { QStringLiteral("dwindlePseudotile"), false },
        { QStringLiteral("dwindleForceSplit"), 0 },
        { QStringLiteral("dwindleSmartSplit"), false },
        { QStringLiteral("dwindleDefaultSplitRatio"), 1.0 },
        { QStringLiteral("dwindleSplitWidthMultiplier"), 1.0 },
        { QStringLiteral("dwindleSmartResizing"), true },
        { QStringLiteral("dwindleSpecialScaleFactor"), 0.8 },
        { QStringLiteral("masterOrientation"), QStringLiteral("left") },
        { QStringLiteral("masterMfact"), 0.55 },
        { QStringLiteral("masterNewStatus"), QStringLiteral("slave") },
        { QStringLiteral("masterNewOnTop"), false },
        { QStringLiteral("masterNewOnActive"), QStringLiteral("none") },
        { QStringLiteral("masterSmartResizing"), true },
        { QStringLiteral("masterSpecialScaleFactor"), 0.8 },
        { QStringLiteral("scrollingColumnWidth"), 0.5 },
        { QStringLiteral("scrollingDirection"), QStringLiteral("right") },
        { QStringLiteral("scrollingFullscreenOnOneColumn"), false },
        { QStringLiteral("scrollingFocusFitMethod"), QStringLiteral("Center") },
        { QStringLiteral("scrollingFollowFocus"), true },

        // XWayland & Ecosystem & Misc
        { QStringLiteral("xwaylandEnabled"), true },
        { QStringLiteral("xwaylandForceZeroScaling"), false },
        { QStringLiteral("xwaylandUseNearestNeighbor"), false },
        { QStringLiteral("noUpdateNews"), false },
        { QStringLiteral("noDonationNag"), false },
        { QStringLiteral("enforcePermissions"), false },
        { QStringLiteral("disableAutoreload"), false },
        { QStringLiteral("focusOnActivate"), false },
        { QStringLiteral("animateManualResizes"), false },
        { QStringLiteral("animateMouseWindowDragging"), false },
        { QStringLiteral("disableHyprlandLogo"), false },
        { QStringLiteral("disableSplashRendering"), false },
        { QStringLiteral("forceDefaultWallpaper"), -1 },
        { QStringLiteral("vrr"), 0 },
        { QStringLiteral("vfr"), true },
        { QStringLiteral("mouseMoveEnablesDpms"), false },
        { QStringLiteral("keyPressEnablesDpms"), false },

        // Misc
        { QStringLiteral("volumeStep"), 10 },
        { QStringLiteral("volumeMax"), 100 },
        { QStringLiteral("cursorTheme"), QStringLiteral("sweet-cursors") },
        { QStringLiteral("cursorSize"), 24 },
        { QStringLiteral("sleepGestureCmd"), QStringLiteral("systemctl suspend-then-hibernate") },

        // Keybinds (single or arrays)
        { QStringLiteral("kbGoToWs"), QStringLiteral("SUPER") },
        { QStringLiteral("kbGoToWsGroup"), QStringLiteral("CTRL + SUPER") },
        { QStringLiteral("kbMoveWinToWs"), QStringLiteral("SUPER + ALT") },
        { QStringLiteral("kbMoveWinToWsGroup"), QStringLiteral("CTRL + SUPER + ALT") },
        { QStringLiteral("kbMoveWinToWsSpecial"), QVariantList{ QStringLiteral("SUPER + ALT + S"), QStringLiteral("CTRL + SUPER + SHIFT + Up") } },
        { QStringLiteral("kbMoveWinFromWsSpecial"), QStringLiteral("CTRL + SUPER + SHIFT + Down") },
        { QStringLiteral("kbMoveWinToWsNext"), QVariantList{ QStringLiteral("SUPER + ALT + mouse_down"), QStringLiteral("SUPER + ALT + Page_Down"), QStringLiteral("CTRL + SUPER + SHIFT + Right") } },
        { QStringLiteral("kbMoveWinToWsPrev"), QVariantList{ QStringLiteral("SUPER + ALT + mouse_up"), QStringLiteral("SUPER + ALT + Page_Up"), QStringLiteral("CTRL + SUPER + SHIFT + Left") } },
        { QStringLiteral("kbNextWs"), QVariantList{ QStringLiteral("SUPER + mouse_down"), QStringLiteral("CTRL + SUPER + Right"), QStringLiteral("SUPER + Page_Down") } },
        { QStringLiteral("kbPrevWs"), QVariantList{ QStringLiteral("SUPER + mouse_up"), QStringLiteral("CTRL + SUPER + Left"), QStringLiteral("SUPER + Page_Up") } },
        { QStringLiteral("kbNextWsGroup"), QStringLiteral("CTRL + SUPER + mouse_down") },
        { QStringLiteral("kbPrevWsGroup"), QStringLiteral("CTRL + SUPER + mouse_up") },
        { QStringLiteral("kbWindowCycleNext"), QStringLiteral("ALT + TAB") },
        { QStringLiteral("kbWindowCyclePrev"), QStringLiteral("SHIFT + ALT + TAB") },
        { QStringLiteral("kbWindowGroupCycleNext"), QStringLiteral("CTRL + ALT + TAB") },
        { QStringLiteral("kbWindowGroupCyclePrev"), QStringLiteral("CTRL + SHIFT + ALT + TAB") },
        { QStringLiteral("kbUngroup"), QStringLiteral("SUPER + U") },
        { QStringLiteral("kbToggleGroup"), QStringLiteral("SUPER + Comma") },
        { QStringLiteral("kbGroupLockActive"), QStringLiteral("SUPER + SHIFT + Comma") },
        { QStringLiteral("kbWindowDecreaseWidth"), QVariantList{ QStringLiteral("SUPER + Minus"), QStringLiteral("SUPER + ALT + Left") } },
        { QStringLiteral("kbWindowIncreaseWidth"), QVariantList{ QStringLiteral("SUPER + Equal"), QStringLiteral("SUPER + ALT + Right") } },
        { QStringLiteral("kbWindowDecreaseHeight"), QVariantList{ QStringLiteral("SUPER + SHIFT + Minus"), QStringLiteral("SUPER + ALT + Up") } },
        { QStringLiteral("kbWindowIncreaseHeight"), QVariantList{ QStringLiteral("SUPER + SHIFT + Equal"), QStringLiteral("SUPER + ALT + Down") } },
        { QStringLiteral("kbMoveWindow"), QStringLiteral("SUPER + Z") },
        { QStringLiteral("kbResizeWindow"), QStringLiteral("SUPER + X") },
        { QStringLiteral("kbCenterWindow"), QStringLiteral("CTRL + SUPER + Backslash") },
        { QStringLiteral("kbNormalizeWindow"), QStringLiteral("CTRL + SUPER + ALT + Backslash") },
        { QStringLiteral("kbWindowPip"), QStringLiteral("SUPER + ALT + Backslash") },
        { QStringLiteral("kbPinWindow"), QStringLiteral("SUPER + P") },
        { QStringLiteral("kbWindowFullscreen"), QStringLiteral("SUPER + F") },
        { QStringLiteral("kbWindowBorderedFullscreen"), QStringLiteral("SUPER + ALT + F") },
        { QStringLiteral("kbToggleWindowFloating"), QStringLiteral("SUPER + ALT + Space") },
        { QStringLiteral("kbCloseWindow"), QStringLiteral("SUPER + Q") },
        { QStringLiteral("kbSpecialWs"), QStringLiteral("SUPER + S") },
        { QStringLiteral("kbSystemMonitorWs"), QStringLiteral("CTRL + SHIFT + Escape") },
        { QStringLiteral("kbMusicWs"), QStringLiteral("SUPER + M") },
        { QStringLiteral("kbCommunicationWs"), QStringLiteral("SUPER + D") },
        { QStringLiteral("kbTodoWs"), QStringLiteral("SUPER + R") },
        { QStringLiteral("kbTerminal"), QStringLiteral("SUPER + T") },
        { QStringLiteral("kbBrowser"), QStringLiteral("SUPER + W") },
        { QStringLiteral("kbEditor"), QStringLiteral("SUPER + C") },
        { QStringLiteral("kbFileExplorer"), QStringLiteral("SUPER + E") },
        { QStringLiteral("kbAudioSettings"), QStringLiteral("CTRL + ALT + V") },
        { QStringLiteral("kbScreenshot"), QStringLiteral("Print") },
        { QStringLiteral("kbScreenshotFreeze"), QStringLiteral("SUPER + SHIFT + S") },
        { QStringLiteral("kbScreenshotRegion"), QStringLiteral("SUPER + SHIFT + ALT + S") },
        { QStringLiteral("kbRecord"), QStringLiteral("CTRL + ALT + R") },
        { QStringLiteral("kbRecordSound"), QStringLiteral("SUPER + ALT + R") },
        { QStringLiteral("kbRecordRegion"), QStringLiteral("SUPER + SHIFT + ALT + R") },
        { QStringLiteral("kbColorPicker"), QStringLiteral("SUPER + SHIFT + C") },
        { QStringLiteral("kbMediaToggle"), QStringLiteral("CTRL + SUPER + Space") },
        { QStringLiteral("kbMediaNext"), QStringLiteral("CTRL + SUPER + Equal") },
        { QStringLiteral("kbMediaPrev"), QStringLiteral("CTRL + SUPER + Minus") },
        { QStringLiteral("kbMediaStop"), QStringLiteral("CTRL + SUPER + Backspace") },
        { QStringLiteral("kbVolumeMute"), QStringLiteral("SUPER + SHIFT + M") },
        { QStringLiteral("kbLauncher"), QStringLiteral("SUPER + SUPER_L") },
        { QStringLiteral("kbSession"), QStringLiteral("CTRL + ALT + Delete") },
        { QStringLiteral("kbShowSidebar"), QStringLiteral("SUPER + N") },
        { QStringLiteral("kbClearNotifs"), QStringLiteral("CTRL + ALT + C") },
        { QStringLiteral("kbShowPanels"), QStringLiteral("SUPER + K") },
        { QStringLiteral("kbLock"), QStringLiteral("SUPER + L") },
        { QStringLiteral("kbRestoreLock"), QStringLiteral("SUPER + ALT + L") },
        { QStringLiteral("kbSleep"), QStringLiteral("SUPER + SHIFT + L") },
        { QStringLiteral("kbClipboard"), QStringLiteral("SUPER + V") },
        { QStringLiteral("kbClipboardDel"), QStringLiteral("SUPER + ALT + V") },
        { QStringLiteral("kbClipboardPasteLatest"), QStringLiteral("CTRL + SHIFT + ALT + V") },
        { QStringLiteral("kbEmoji"), QStringLiteral("SUPER + Period") }
    };

    const QString defPath = defaultVarsFilePath();
    QFile defFile(defPath);
    if (defFile.exists() && defFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(defFile.readAll());
        defFile.close();

        static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?\s*(--.*)?$)"), QRegularExpression::MultilineOption);
        auto matchIt = lineRe.globalMatch(content);
        while (matchIt.hasNext()) {
            auto m = matchIt.next();
            const QString key = m.captured(1);
            QString valStr = m.captured(2).trimmed();
            if (valStr.endsWith(QLatin1Char(','))) {
                valStr.chop(1);
                valStr = valStr.trimmed();
            }

            if (valStr.contains(QLatin1String("scheme.")) || valStr.contains(QLatin1String("..")) || valStr.startsWith(QLatin1String("rgba("))) {
                m_defaults[key] = valStr;
            } else if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
                m_defaults[key] = valStr.mid(1, valStr.length() - 2);
            } else if (valStr == QStringLiteral("true")) {
                m_defaults[key] = true;
            } else if (valStr == QStringLiteral("false")) {
                m_defaults[key] = false;
            } else if (valStr.startsWith(QLatin1Char('{')) && valStr.endsWith(QLatin1Char('}'))) {
                QString inner = valStr.mid(1, valStr.length() - 2).trimmed();
                QStringList items;
                static const QRegularExpression strItemRe(QStringLiteral(R"(\"([^\"]*)\")"));
                auto itemIt = strItemRe.globalMatch(inner);
                while (itemIt.hasNext()) {
                    items.append(itemIt.next().captured(1));
                }
                m_defaults[key] = items;
            } else {
                bool ok = false;
                double d = valStr.toDouble(&ok);
                if (ok) {
                    if (valStr.contains(QLatin1Char('.'))) {
                        m_defaults[key] = d;
                    } else {
                        m_defaults[key] = valStr.toLongLong();
                    }
                } else {
                    m_defaults[key] = valStr;
                }
            }
        }
    }

    auto mirrorAliases = [](QVariantMap& map) {
        if (map.contains(QStringLiteral("shadowColour")) && !map.contains(QStringLiteral("shadowColor"))) {
            map[QStringLiteral("shadowColor")] = map[QStringLiteral("shadowColour")];
        } else if (map.contains(QStringLiteral("shadowColor")) && !map.contains(QStringLiteral("shadowColour"))) {
            map[QStringLiteral("shadowColour")] = map[QStringLiteral("shadowColor")];
        }

        if (map.contains(QStringLiteral("inactiveShadowColour")) && !map.contains(QStringLiteral("inactiveShadowColor"))) {
            map[QStringLiteral("inactiveShadowColor")] = map[QStringLiteral("inactiveShadowColour")];
        } else if (map.contains(QStringLiteral("inactiveShadowColor")) && !map.contains(QStringLiteral("inactiveShadowColour"))) {
            map[QStringLiteral("inactiveShadowColour")] = map[QStringLiteral("inactiveShadowColor")];
        }

        if (map.contains(QStringLiteral("activeWindowBorderColour")) && !map.contains(QStringLiteral("activeWindowBorderColor"))) {
            map[QStringLiteral("activeWindowBorderColor")] = map[QStringLiteral("activeWindowBorderColour")];
        } else if (map.contains(QStringLiteral("activeWindowBorderColor")) && !map.contains(QStringLiteral("activeWindowBorderColour"))) {
            map[QStringLiteral("activeWindowBorderColour")] = map[QStringLiteral("activeWindowBorderColor")];
        }

        if (map.contains(QStringLiteral("inactiveWindowBorderColour")) && !map.contains(QStringLiteral("inactiveWindowBorderColor"))) {
            map[QStringLiteral("inactiveWindowBorderColor")] = map[QStringLiteral("inactiveWindowBorderColour")];
        } else if (map.contains(QStringLiteral("inactiveWindowBorderColor")) && !map.contains(QStringLiteral("inactiveWindowBorderColour"))) {
            map[QStringLiteral("inactiveWindowBorderColour")] = map[QStringLiteral("inactiveWindowBorderColor")];
        }
    };
    mirrorAliases(m_defaults);
}

void CaelestiaVars::loadFromFile() {
    m_savedVars.clear();
    m_pendingVars.clear();

    const QString path = varsFilePath();
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit varsChanged();
        emit pendingChanged();
        emit dirtyChanged();
        return;
    }

    const QString content = QString::fromUtf8(file.readAll());
    file.close();

    static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?\s*(--.*)?$)"), QRegularExpression::MultilineOption);
    auto matchIt = lineRe.globalMatch(content);
    while (matchIt.hasNext()) {
        auto m = matchIt.next();
        const QString key = m.captured(1);
        QString valStr = m.captured(2).trimmed();
        if (valStr.endsWith(QLatin1Char(','))) {
            valStr.chop(1);
            valStr = valStr.trimmed();
        }

        if (valStr.contains(QLatin1String("scheme.")) || valStr.contains(QLatin1String("..")) || valStr.startsWith(QLatin1String("rgba("))) {
            m_savedVars[key] = valStr;
        } else if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
            m_savedVars[key] = valStr.mid(1, valStr.length() - 2);
        } else if (valStr == QStringLiteral("true")) {
            m_savedVars[key] = true;
        } else if (valStr == QStringLiteral("false")) {
            m_savedVars[key] = false;
        } else if (valStr.startsWith(QLatin1Char('{')) && valStr.endsWith(QLatin1Char('}'))) {
            QString inner = valStr.mid(1, valStr.length() - 2).trimmed();
            QStringList items;
            static const QRegularExpression strItemRe(QStringLiteral(R"(\"([^\"]*)\")"));
            auto itemIt = strItemRe.globalMatch(inner);
            while (itemIt.hasNext()) {
                items.append(itemIt.next().captured(1));
            }
            m_savedVars[key] = items;
        } else {
            bool ok = false;
            double d = valStr.toDouble(&ok);
            if (ok) {
                if (valStr.contains(QLatin1Char('.'))) {
                    m_savedVars[key] = d;
                } else {
                    m_savedVars[key] = valStr.toLongLong();
                }
            } else {
                m_savedVars[key] = valStr;
            }
        }
    }

    auto mirrorAliases = [](QVariantMap& map) {
        if (map.contains(QStringLiteral("shadowColour")) && !map.contains(QStringLiteral("shadowColor"))) {
            map[QStringLiteral("shadowColor")] = map[QStringLiteral("shadowColour")];
        } else if (map.contains(QStringLiteral("shadowColor")) && !map.contains(QStringLiteral("shadowColour"))) {
            map[QStringLiteral("shadowColour")] = map[QStringLiteral("shadowColor")];
        }

        if (map.contains(QStringLiteral("inactiveShadowColour")) && !map.contains(QStringLiteral("inactiveShadowColor"))) {
            map[QStringLiteral("inactiveShadowColor")] = map[QStringLiteral("inactiveShadowColour")];
        } else if (map.contains(QStringLiteral("inactiveShadowColor")) && !map.contains(QStringLiteral("inactiveShadowColour"))) {
            map[QStringLiteral("inactiveShadowColour")] = map[QStringLiteral("inactiveShadowColor")];
        }

        if (map.contains(QStringLiteral("activeWindowBorderColour")) && !map.contains(QStringLiteral("activeWindowBorderColor"))) {
            map[QStringLiteral("activeWindowBorderColor")] = map[QStringLiteral("activeWindowBorderColour")];
        } else if (map.contains(QStringLiteral("activeWindowBorderColor")) && !map.contains(QStringLiteral("activeWindowBorderColour"))) {
            map[QStringLiteral("activeWindowBorderColour")] = map[QStringLiteral("activeWindowBorderColor")];
        }

        if (map.contains(QStringLiteral("inactiveWindowBorderColour")) && !map.contains(QStringLiteral("inactiveWindowBorderColor"))) {
            map[QStringLiteral("inactiveWindowBorderColor")] = map[QStringLiteral("inactiveWindowBorderColour")];
        } else if (map.contains(QStringLiteral("inactiveWindowBorderColor")) && !map.contains(QStringLiteral("inactiveWindowBorderColour"))) {
            map[QStringLiteral("inactiveWindowBorderColour")] = map[QStringLiteral("inactiveWindowBorderColor")];
        }
    };
    mirrorAliases(m_savedVars);

    m_pendingVars.clear();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::syncFromHyprland() {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket) return;

    auto queryOpt = [&](const QString& optName) -> QJsonObject {
        QJsonDocument doc = socket->queryJson(QStringLiteral("j/getoption %1").arg(optName));
        return doc.object();
    };

    QJsonObject obj = queryOpt(QStringLiteral("general:border_size"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowBorderSize")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:rounding"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowRounding")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("general:gaps_in"));
    if (obj.contains(QStringLiteral("custom"))) {
        m_savedVars[QStringLiteral("windowGapsIn")] = obj[QStringLiteral("custom")].toString().toInt();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowGapsIn")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("general:gaps_out"));
    if (obj.contains(QStringLiteral("custom"))) {
        m_savedVars[QStringLiteral("windowGapsOut")] = obj[QStringLiteral("custom")].toString().toInt();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowGapsOut")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:active_opacity"));
    if (obj.contains(QStringLiteral("float"))) {
        m_savedVars[QStringLiteral("windowOpacity")] = obj[QStringLiteral("float")].toDouble();
    }

    obj = queryOpt(QStringLiteral("decoration:blur:enabled"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurEnabled")] = (obj[QStringLiteral("int")].toInt() != 0);
    }

    obj = queryOpt(QStringLiteral("decoration:blur:size"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurSize")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:blur:passes"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurPasses")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:shadow:enabled"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("shadowEnabled")] = (obj[QStringLiteral("int")].toInt() != 0);
    }

    obj = queryOpt(QStringLiteral("decoration:shadow:range"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("shadowRange")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("input:touchpad:disable_while_typing"));
    if (obj.contains(QStringLiteral("bool"))) {
        m_savedVars[QStringLiteral("touchpadDisableTyping")] = obj[QStringLiteral("bool")].toBool();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("touchpadDisableTyping")] = (obj[QStringLiteral("int")].toInt() != 0);
    }
}

void CaelestiaVars::applyKeywordToHyprland(const QString& key, const QVariant& value) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket) return;

    if (key == QStringLiteral("windowBorderSize")) {
        socket->send(QStringLiteral("keyword general:border_size %1").arg(value.toInt()));
    } else if (key == QStringLiteral("windowRounding")) {
        socket->send(QStringLiteral("keyword decoration:rounding %1").arg(value.toInt()));
    } else if (key == QStringLiteral("windowGapsIn")) {
        socket->send(QStringLiteral("keyword general:gaps_in %1").arg(value.toInt()));
    } else if (key == QStringLiteral("windowGapsOut")) {
        socket->send(QStringLiteral("keyword general:gaps_out %1").arg(value.toInt()));
    } else if (key == QStringLiteral("workspaceGaps")) {
        socket->send(QStringLiteral("keyword general:gaps_workspaces %1").arg(value.toInt()));
    } else if (key == QStringLiteral("singleWindowGapsOut")) {
        socket->send(QStringLiteral("keyword workspace w[tv1]s[false], gapsout:%1").arg(value.toInt()));
        socket->send(QStringLiteral("keyword workspace f[1]s[false], gapsout:%1").arg(value.toInt()));
    } else if (key == QStringLiteral("windowOpacity")) {
        socket->send(QStringLiteral("keyword windowrule opacity %1 override, match:fullscreen false").arg(QString::number(value.toDouble(), 'f', 2)));
    } else if (key == QStringLiteral("activeWindowBorderColour") || key == QStringLiteral("activeWindowBorderColor")) {
        QVariantMap parsed = parseColor(value.toString());
        QString hex = parsed.value(QStringLiteral("hex")).toString();
        QString alpha = parsed.value(QStringLiteral("alphaHex")).toString();
        socket->send(QStringLiteral("keyword general:col.active_border 0x%1%2").arg(alpha, hex));
    } else if (key == QStringLiteral("inactiveWindowBorderColour") || key == QStringLiteral("inactiveWindowBorderColor")) {
        QVariantMap parsed = parseColor(value.toString());
        QString hex = parsed.value(QStringLiteral("hex")).toString();
        QString alpha = parsed.value(QStringLiteral("alphaHex")).toString();
        socket->send(QStringLiteral("keyword general:col.inactive_border 0x%1%2").arg(alpha, hex));
    } else if (key == QStringLiteral("blurEnabled")) {
        socket->send(QStringLiteral("keyword decoration:blur:enabled %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurSize")) {
        socket->send(QStringLiteral("keyword decoration:blur:size %1").arg(value.toInt()));
    } else if (key == QStringLiteral("blurPasses")) {
        socket->send(QStringLiteral("keyword decoration:blur:passes %1").arg(value.toInt()));
    } else if (key == QStringLiteral("blurXray")) {
        socket->send(QStringLiteral("keyword decoration:blur:xray %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurSpecialWs")) {
        socket->send(QStringLiteral("keyword decoration:blur:special %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurPopups")) {
        socket->send(QStringLiteral("keyword decoration:blur:popups %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurInputMethods")) {
        socket->send(QStringLiteral("keyword decoration:blur:input_methods %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("shadowEnabled")) {
        socket->send(QStringLiteral("keyword decoration:shadow:enabled %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("shadowRange")) {
        socket->send(QStringLiteral("keyword decoration:shadow:range %1").arg(value.toInt()));
    } else if (key == QStringLiteral("shadowRenderPower")) {
        socket->send(QStringLiteral("keyword decoration:shadow:render_power %1").arg(value.toInt()));
    } else if (key == QStringLiteral("shadowColour") || key == QStringLiteral("shadowColor")) {
        QVariantMap parsed = parseColor(value.toString());
        QString hex = parsed.value(QStringLiteral("hex")).toString();
        QString alpha = parsed.value(QStringLiteral("alphaHex")).toString();
        socket->send(QStringLiteral("keyword decoration:shadow:color 0x%1%2").arg(alpha, hex));
    } else if (key == QStringLiteral("touchpadDisableTyping")) {
        socket->send(QStringLiteral("keyword input:touchpad:disable_while_typing %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("touchpadScrollFactor")) {
        socket->send(QStringLiteral("keyword input:touchpad:scroll_factor %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("workspaceSwipeFingers")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_fingers %1").arg(value.toInt()));
    } else if (key == QStringLiteral("gestureFingersMore")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_fingers %1").arg(value.toInt()));
    } else if (key == QStringLiteral("resizeOnBorder")) {
        socket->send(QStringLiteral("keyword general:resize_on_border %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("extendBorderGrabArea")) {
        socket->send(QStringLiteral("keyword general:extend_border_grab_area %1").arg(value.toInt()));
    } else if (key == QStringLiteral("hoverIconOnBorder")) {
        socket->send(QStringLiteral("keyword general:hover_icon_on_border %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("allowTearing")) {
        socket->send(QStringLiteral("keyword general:allow_tearing %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("layout")) {
        socket->send(QStringLiteral("keyword general:layout %1").arg(value.toString()));
    } else if (key == QStringLiteral("windowRoundingPower")) {
        socket->send(QStringLiteral("keyword decoration:rounding_power %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("activeWindowOpacity")) {
        socket->send(QStringLiteral("keyword decoration:active_opacity %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("inactiveWindowOpacity")) {
        socket->send(QStringLiteral("keyword decoration:inactive_opacity %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("fullscreenWindowOpacity") || key == QStringLiteral("fullscreenOpacity")) {
        socket->send(QStringLiteral("keyword decoration:fullscreen_opacity %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("dimInactive")) {
        socket->send(QStringLiteral("keyword decoration:dim_inactive %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("dimStrength")) {
        socket->send(QStringLiteral("keyword decoration:dim_strength %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("dimAround")) {
        socket->send(QStringLiteral("keyword decoration:dim_around %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("dimSpecial")) {
        socket->send(QStringLiteral("keyword decoration:dim_special %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("snapEnabled")) {
        socket->send(QStringLiteral("keyword general:snap:enabled %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("snapWindowGap")) {
        socket->send(QStringLiteral("keyword general:snap:window_gap %1").arg(value.toInt()));
    } else if (key == QStringLiteral("snapMonitorGap")) {
        socket->send(QStringLiteral("keyword general:snap:monitor_gap %1").arg(value.toInt()));
    } else if (key == QStringLiteral("snapBorderOverlap")) {
        socket->send(QStringLiteral("keyword general:snap:border_overlap %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("snapRespectGaps")) {
        socket->send(QStringLiteral("keyword general:snap:respect_gaps %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurIgnoreOpacity")) {
        socket->send(QStringLiteral("keyword decoration:blur:ignore_opacity %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("blurNoise")) {
        socket->send(QStringLiteral("keyword decoration:blur:noise %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("blurContrast")) {
        socket->send(QStringLiteral("keyword decoration:blur:contrast %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("blurBrightness")) {
        socket->send(QStringLiteral("keyword decoration:blur:brightness %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("blurVibrancy")) {
        socket->send(QStringLiteral("keyword decoration:blur:vibrancy %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("blurVibrancyDarkness")) {
        socket->send(QStringLiteral("keyword decoration:blur:vibrancy_darkness %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("shadowOffset")) {
        socket->send(QStringLiteral("keyword decoration:shadow:offset %1").arg(value.toString()));
    } else if (key == QStringLiteral("shadowScale")) {
        socket->send(QStringLiteral("keyword decoration:shadow:scale %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("cursorNoHardwareCursors")) {
        socket->send(QStringLiteral("keyword cursor:no_hardware_cursors %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorEnableHyprcursor")) {
        socket->send(QStringLiteral("keyword cursor:enable_hyprcursor %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorNoWarps")) {
        socket->send(QStringLiteral("keyword cursor:no_warps %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorPersistentWarps")) {
        socket->send(QStringLiteral("keyword cursor:persistent_warps %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorWarpOnChangeWorkspace")) {
        socket->send(QStringLiteral("keyword cursor:warp_on_change_workspace %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorZoomFactor")) {
        socket->send(QStringLiteral("keyword cursor:zoom_factor %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("cursorInactiveTimeout")) {
        socket->send(QStringLiteral("keyword cursor:inactive_timeout %1").arg(value.toInt()));
    } else if (key == QStringLiteral("cursorHideOnKeyPress")) {
        socket->send(QStringLiteral("keyword cursor:hide_on_key_press %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorHideOnTouch")) {
        socket->send(QStringLiteral("keyword cursor:hide_on_touch %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorHideOnTablet")) {
        socket->send(QStringLiteral("keyword cursor:hide_on_tablet %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("kbLayout")) {
        socket->send(QStringLiteral("keyword input:kb_layout %1").arg(value.toString()));
    } else if (key == QStringLiteral("kbVariant")) {
        socket->send(QStringLiteral("keyword input:kb_variant %1").arg(value.toString()));
    } else if (key == QStringLiteral("kbOptions")) {
        socket->send(QStringLiteral("keyword input:kb_options %1").arg(value.toString()));
    } else if (key == QStringLiteral("numlockByDefault")) {
        socket->send(QStringLiteral("keyword input:numlock_by_default %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("keyRepeatRate")) {
        socket->send(QStringLiteral("keyword input:repeat_rate %1").arg(value.toInt()));
    } else if (key == QStringLiteral("keyRepeatDelay")) {
        socket->send(QStringLiteral("keyword input:repeat_delay %1").arg(value.toInt()));
    } else if (key == QStringLiteral("mouseSensitivity")) {
        socket->send(QStringLiteral("keyword input:sensitivity %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("mouseAccelProfile")) {
        socket->send(QStringLiteral("keyword input:accel_profile %1").arg(value.toString()));
    } else if (key == QStringLiteral("followMouse")) {
        socket->send(QStringLiteral("keyword input:follow_mouse %1").arg(value.toInt()));
    } else if (key == QStringLiteral("mouseNaturalScroll")) {
        socket->send(QStringLiteral("keyword input:natural_scroll %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("mouseScrollFactor")) {
        socket->send(QStringLiteral("keyword input:scroll_factor %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("leftHandedMode")) {
        socket->send(QStringLiteral("keyword input:left_handed %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("mouseRefocus")) {
        socket->send(QStringLiteral("keyword input:mouse_refocus %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("floatSwitchOverrideFocus")) {
        socket->send(QStringLiteral("keyword input:float_switch_override_focus %1").arg(value.toInt()));
    } else if (key == QStringLiteral("touchpadTapToClick")) {
        socket->send(QStringLiteral("keyword input:touchpad:tap-to-click %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("touchpadClickfingerBehavior")) {
        socket->send(QStringLiteral("keyword input:touchpad:clickfinger_behavior %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("touchpadMiddleButtonEmulation")) {
        socket->send(QStringLiteral("keyword input:touchpad:middle_button_emulation %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("touchpadDragLock")) {
        socket->send(QStringLiteral("keyword input:touchpad:drag_lock %1").arg(value.toInt()));
    } else if (key == QStringLiteral("touchpadTapButtonMap")) {
        socket->send(QStringLiteral("keyword input:touchpad:tap_button_map %1").arg(value.toString()));
    } else if (key == QStringLiteral("workspaceSwipeCreateNew")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_create_new %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("workspaceSwipeForever")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_forever %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("workspaceSwipeCancelRatio")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_cancel_ratio %1").arg(value.toDouble()));
    } else if (key == QStringLiteral("workspaceSwipeDistance")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_distance %1").arg(value.toInt()));
    } else if (key == QStringLiteral("workspaceSwipeInvert")) {
        socket->send(QStringLiteral("keyword gestures:workspace_swipe_invert %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("vfr")) {
        socket->send(QStringLiteral("keyword misc:vfr %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("vrr")) {
        socket->send(QStringLiteral("keyword misc:vrr %1").arg(value.toInt()));
    } else if (key == QStringLiteral("focusOnActivate")) {
        socket->send(QStringLiteral("keyword misc:focus_on_activate %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("animateManualResizes")) {
        socket->send(QStringLiteral("keyword misc:animate_manual_resizes %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("animateMouseWindowDragging")) {
        socket->send(QStringLiteral("keyword misc:animate_mouse_windowdragging %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("disableHyprlandLogo")) {
        socket->send(QStringLiteral("keyword misc:disable_hyprland_logo %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("disableSplashRendering")) {
        socket->send(QStringLiteral("keyword misc:disable_splash_rendering %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("forceDefaultWallpaper")) {
        socket->send(QStringLiteral("keyword misc:force_default_wallpaper %1").arg(value.toInt()));
    } else if (key == QStringLiteral("mouseMoveEnablesDpms")) {
        socket->send(QStringLiteral("keyword misc:mouse_move_enables_dpms %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("keyPressEnablesDpms")) {
        socket->send(QStringLiteral("keyword misc:key_press_enables_dpms %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("disableAutoreload")) {
        socket->send(QStringLiteral("keyword misc:disable_autoreload %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("xwaylandEnabled")) {
        socket->send(QStringLiteral("keyword xwayland:enabled %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("xwaylandForceZeroScaling")) {
        socket->send(QStringLiteral("keyword xwayland:force_zero_scaling %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("xwaylandUseNearestNeighbor")) {
        socket->send(QStringLiteral("keyword xwayland:use_nearest_neighbor %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("noUpdateNews")) {
        socket->send(QStringLiteral("keyword ecosystem:no_update_news %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("noDonationNag")) {
        socket->send(QStringLiteral("keyword ecosystem:no_donation_nag %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("enforcePermissions")) {
        socket->send(QStringLiteral("keyword ecosystem:enforce_permissions %1").arg(value.toBool() ? 1 : 0));
    } else if (key == QStringLiteral("cursorTheme") || key == QStringLiteral("cursorSize")) {
        QString theme = m_savedVars.value(QStringLiteral("cursorTheme"), m_defaults.value(QStringLiteral("cursorTheme"))).toString();
        int size = m_savedVars.value(QStringLiteral("cursorSize"), m_defaults.value(QStringLiteral("cursorSize"))).toInt();
        if (key == QStringLiteral("cursorTheme")) theme = value.toString();
        if (key == QStringLiteral("cursorSize")) size = value.toInt();
        socket->setCursor(theme, size);
    } else {
        socket->keyword(key, value);
    }
}

bool CaelestiaVars::isDirty() const {
    return !m_pendingVars.isEmpty();
}

int CaelestiaVars::dirtyCount() const {
    return m_pendingVars.size();
}

QStringList CaelestiaVars::pendingKeys() const {
    return m_pendingVars.keys();
}

QVariantMap CaelestiaVars::currentVars() const {
    QVariantMap map = m_savedVars;
    const QVariantMap hyprOpts = FlightDeckWriter::instance()->hyprOptions();
    for (auto it = hyprOpts.constBegin(); it != hyprOpts.constEnd(); ++it) {
        if (!map.contains(it.key())) {
            map[it.key()] = it.value();
        }
    }
    return map;
}

QVariantMap CaelestiaVars::pendingVars() const {
    return m_pendingVars;
}

QVariant CaelestiaVars::get(const QString& key, const QVariant& fallback) const {
    if (m_pendingVars.contains(key)) {
        return m_pendingVars.value(key);
    }
    if (m_savedVars.contains(key)) {
        return m_savedVars.value(key);
    }
    if (FlightDeckWriter::instance()->hasHyprOption(key)) {
        return FlightDeckWriter::instance()->getHyprOption(key);
    }
    if (m_defaults.contains(key)) {
        return m_defaults.value(key);
    }
    return fallback;
}

QVariant CaelestiaVars::getDefault(const QString& key, const QVariant& fallback) const {
    if (m_defaults.contains(key)) {
        return m_defaults.value(key);
    }
    return fallback;
}

bool CaelestiaVars::isOverridden(const QString& key) const {
    return m_savedVars.contains(key) || m_pendingVars.contains(key) || FlightDeckWriter::instance()->hasHyprOption(key);
}

void CaelestiaVars::set(const QString& key, const QVariant& value) {
    m_savedVars[key] = value;
    m_pendingVars.remove(key);

    auto syncAlias = [&](const QString& k1, const QString& k2) {
        if (key == k1) {
            m_savedVars[k2] = value;
            m_pendingVars.remove(k2);
        } else if (key == k2) {
            m_savedVars[k1] = value;
            m_pendingVars.remove(k1);
        }
    };
    syncAlias(QStringLiteral("shadowColour"), QStringLiteral("shadowColor"));
    syncAlias(QStringLiteral("inactiveShadowColour"), QStringLiteral("inactiveShadowColor"));
    syncAlias(QStringLiteral("activeWindowBorderColour"), QStringLiteral("activeWindowBorderColor"));
    syncAlias(QStringLiteral("inactiveWindowBorderColour"), QStringLiteral("inactiveWindowBorderColor"));

    FlightDeckWriter::instance()->setHyprOption(key, value);

    applyKeywordToHyprland(key, value);
    save();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::setVar(const QString& key, const QVariant& value) {
    set(key, value);
}

void CaelestiaVars::resetKey(const QString& key) {
    if (m_pendingVars.contains(key)) {
        m_pendingVars.remove(key);
        emit pendingChanged();
        emit dirtyChanged();
    }
}

void CaelestiaVars::remove(const QString& key) {
    m_savedVars.remove(key);
    m_pendingVars.remove(key);
    save();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::resetToDefault(const QString& key) {
    m_savedVars.remove(key);
    m_pendingVars.remove(key);

    auto removeAlias = [&](const QString& k1, const QString& k2) {
        if (key == k1) {
            m_savedVars.remove(k2);
            m_pendingVars.remove(k2);
        } else if (key == k2) {
            m_savedVars.remove(k1);
            m_pendingVars.remove(k1);
        }
    };
    removeAlias(QStringLiteral("shadowColour"), QStringLiteral("shadowColor"));
    removeAlias(QStringLiteral("inactiveShadowColour"), QStringLiteral("inactiveShadowColor"));
    removeAlias(QStringLiteral("activeWindowBorderColour"), QStringLiteral("activeWindowBorderColor"));
    removeAlias(QStringLiteral("inactiveWindowBorderColour"), QStringLiteral("inactiveWindowBorderColor"));

    save();
    if (m_defaults.contains(key)) {
        applyKeywordToHyprland(key, m_defaults.value(key));
    }
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::discardAll() {
    m_pendingVars.clear();
    emit pendingChanged();
    emit dirtyChanged();
}

QStringList CaelestiaVars::getBinds(const QString& key) const {
    const QVariant val = get(key);
    if (val.typeId() == QMetaType::QVariantList || val.typeId() == QMetaType::QStringList) {
        return val.toStringList();
    }
    const QString str = val.toString();
    return str.isEmpty() ? QStringList() : QStringList{ str };
}

void CaelestiaVars::setBinds(const QString& key, const QStringList& binds) {
    if (binds.size() == 1) {
        set(key, binds.first());
    } else {
        set(key, QVariant::fromValue(binds));
    }
}

QString CaelestiaVars::formatLua() const {
    QVariantMap fullVars = m_savedVars;
    for (auto it = m_pendingVars.constBegin(); it != m_pendingVars.constEnd(); ++it) {
        fullVars[it.key()] = it.value();
    }

    QString out;
    out += QStringLiteral("local scheme = require(\"scheme.current\")\n\n");
    out += QStringLiteral("return {\n");

    auto writeSection = [&out, &fullVars](const QString& title, const QStringList& keys) {
        out += QStringLiteral("    -- ") + title + QStringLiteral("\n");
        for (const QString& key : keys) {
            if (!fullVars.contains(key)) continue;

            const QVariant val = fullVars.value(key);
            QString valStr;
            if (val.typeId() == QMetaType::Bool) {
                valStr = val.toBool() ? QStringLiteral("true") : QStringLiteral("false");
            } else if (val.typeId() == QMetaType::QVariantList || val.typeId() == QMetaType::QStringList) {
                QStringList items;
                const QStringList rawList = val.toStringList();
                for (const QString& s : rawList) {
                    items.append(QStringLiteral("\"") + s + QStringLiteral("\""));
                }
                valStr = QStringLiteral("{ ") + items.join(QStringLiteral(", ")) + QStringLiteral(" }");
            } else if (key == QStringLiteral("windowOpacity")) {
                valStr = QString::number(val.toDouble(), 'f', 2);
            } else if (key == QStringLiteral("touchpadScrollFactor")) {
                valStr = QString::number(val.toDouble(), 'g', 4);
            } else if (val.typeId() == QMetaType::Double || val.typeId() == QMetaType::Float) {
                if (val.toDouble() == std::floor(val.toDouble())) {
                    valStr = QString::number(static_cast<qint64>(std::round(val.toDouble())));
                } else {
                    valStr = QString::number(val.toDouble(), 'g', 6);
                }
            } else if (val.typeId() == QMetaType::Int || val.typeId() == QMetaType::LongLong || val.typeId() == QMetaType::UInt || val.typeId() == QMetaType::ULongLong) {
                valStr = QString::number(val.toLongLong());
            } else {
                const QString s = val.toString();
                if (s.startsWith(QLatin1String("\"")) && s.endsWith(QLatin1String("\""))) {
                    valStr = s;
                } else if (s.contains(QLatin1String("..")) || s.contains(QLatin1String("scheme."))) {
                    // String contains lua variable concatenation
                    valStr = s;
                } else {
                    valStr = QStringLiteral("\"") + s + QStringLiteral("\"");
                }
            }

            const QString padding = QString(static_cast<qsizetype>(std::max(1, static_cast<int>(28 - key.length()))), QLatin1Char(' '));
            out += QStringLiteral("    %1%2= %3,\n").arg(key, padding, valStr);
        }
        out += QStringLiteral("\n");
    };

    writeSection(QStringLiteral("Apps"), {
        QStringLiteral("terminal"), QStringLiteral("browser"), QStringLiteral("editor"),
        QStringLiteral("fileExplorer"), QStringLiteral("audioSettings")
    });

    writeSection(QStringLiteral("Touchpad"), {
        QStringLiteral("touchpadDisableTyping"), QStringLiteral("touchpadScrollFactor"),
        QStringLiteral("gestureFingers"), QStringLiteral("workspaceSwipeFingers"),
        QStringLiteral("gestureFingersMore")
    });

    writeSection(QStringLiteral("Blur"), {
        QStringLiteral("blurEnabled"), QStringLiteral("blurSpecialWs"), QStringLiteral("blurPopups"),
        QStringLiteral("blurInputMethods"), QStringLiteral("blurSize"), QStringLiteral("blurPasses"),
        QStringLiteral("blurXray")
    });

    writeSection(QStringLiteral("Shadow"), {
        QStringLiteral("shadowEnabled"), QStringLiteral("shadowRange"),
        QStringLiteral("shadowRenderPower"), QStringLiteral("shadowColour")
    });

    writeSection(QStringLiteral("Gaps"), {
        QStringLiteral("workspaceGaps"), QStringLiteral("windowGapsIn"),
        QStringLiteral("windowGapsOut"), QStringLiteral("singleWindowGapsOut")
    });

    writeSection(QStringLiteral("Window styling"), {
        QStringLiteral("windowOpacity"), QStringLiteral("windowRounding"),
        QStringLiteral("windowBorderSize"), QStringLiteral("activeWindowBorderColour"),
        QStringLiteral("inactiveWindowBorderColour")
    });

    writeSection(QStringLiteral("Misc"), {
        QStringLiteral("volumeStep"), QStringLiteral("volumeMax"),
        QStringLiteral("cursorTheme"), QStringLiteral("cursorSize"),
        QStringLiteral("sleepGestureCmd")
    });

    // Keybinds
    QStringList kbKeys;
    for (auto it = fullVars.constBegin(); it != fullVars.constEnd(); ++it) {
        if (it.key().startsWith(QLatin1String("kb"))) {
            kbKeys.append(it.key());
        }
    }
    kbKeys.sort();
    if (!kbKeys.isEmpty()) {
        writeSection(QStringLiteral("Keybinds"), kbKeys);
    }

    out += QStringLiteral("}\n");
    return out;
}

bool CaelestiaVars::save() {
    const QString path = varsFilePath();
    const QFileInfo fi(path);
    if (!fi.dir().exists()) {
        fi.dir().mkpath(QStringLiteral("."));
    }

    const QString lua = formatLua();
    QString validationError;
    if (!LuaValidator::validate(lua, &validationError)) {
        qWarning() << "Lua validation failed for hypr-vars.lua:" << validationError;
        emit saveFailed(QStringLiteral("Lua syntax error: %1").arg(validationError));
        return false;
    }

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        emit saveFailed(file.errorString());
        return false;
    }

    file.write(lua.toUtf8());
    file.close();

    // Also persist native Hyprland options into astra-flightdeck.lua
    FlightDeckWriter::instance()->save();

    for (auto it = m_pendingVars.constBegin(); it != m_pendingVars.constEnd(); ++it) {
        m_savedVars[it.key()] = it.value();
    }
    m_pendingVars.clear();

    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
    emit saveSucceeded();
    return true;
}

void CaelestiaVars::reload() {
    loadFromFile();
}

} // namespace FlightDeck::Caelestia
