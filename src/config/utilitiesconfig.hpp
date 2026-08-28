#pragma once

#include "configlist.hpp"
#include "configobject.hpp"

#include <qstring.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UtilitiesToasts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, fullscreen, u"off"_s)
    CONFIG_GLOBAL_PROPERTY(bool, configLoaded, true)
    CONFIG_GLOBAL_PROPERTY(bool, chargingChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, gameModeChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, dndChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioOutputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, audioInputChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, capsLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, numLockChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLayoutChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, kbLimit, true)
    CONFIG_GLOBAL_PROPERTY(bool, vpnChanged, true)
    CONFIG_GLOBAL_PROPERTY(bool, nowPlaying, false)
    CONFIG_GLOBAL_PROPERTY(bool, transparency, false)
    CONFIG_GLOBAL_PROPERTY(qreal, transparencyBase, 0.85)

public:
    explicit UtilitiesToasts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesVpn : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, enabled, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, provider)
    CONFIG_GLOBAL_PROPERTY(QString, selectedProvider, u""_s)

public:
    explicit UtilitiesVpn(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesGameMode : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_GLOBAL_PROPERTY(bool, disableHyprlandAnimations, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableHyprlandBlur, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableHyprlandGaps, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableHyprlandShadows, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableShellTransparency, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableWindowTransparency, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableToastTransparency, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableDesktopLyrics, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableVisualizer, true)
    CONFIG_GLOBAL_PROPERTY(bool, disableShimeji, true)

    CONFIG_GLOBAL_PROPERTY(bool, autoEnable, true)
    CONFIG_GLOBAL_PROPERTY(QStringList, autoEnableRegexes)

public:
    explicit UtilitiesGameMode(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesCards : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, keepAwake, true)
    CONFIG_PROPERTY(bool, recorder, true)
    CONFIG_PROPERTY(bool, quickToggles, true)

public:
    explicit UtilitiesCards(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class UtilitiesConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, maxToasts, 4)
    CONFIG_SUBOBJECT(UtilitiesCards, cards)
    CONFIG_SUBOBJECT(UtilitiesToasts, toasts)
    CONFIG_SUBOBJECT(UtilitiesVpn, vpn)
    CONFIG_SUBOBJECT(UtilitiesGameMode, gameMode)
    CONFIG_LIST(EntryList, quickToggles,
        {
            LIST_ENTRY(wifi, true),
            LIST_ENTRY(bluetooth, true),
            LIST_ENTRY(quickshare, true),
            LIST_ENTRY(mic, true),
            LIST_ENTRY(settings, true),
            LIST_ENTRY(gameMode, true),
            LIST_ENTRY(dnd, true),
            LIST_ENTRY(vpn, false),
            LIST_ENTRY(wallpaper, true),
            LIST_ENTRY(badapple, true),
            LIST_ENTRY(pauseWallpaper, true),
            LIST_ENTRY(pipPause, true),
        })

public:
    explicit UtilitiesConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_cards(new UtilitiesCards(this))
        , m_toasts(new UtilitiesToasts(this))
        , m_vpn(new UtilitiesVpn(this))
        , m_gameMode(new UtilitiesGameMode(this)) {}
};

}
