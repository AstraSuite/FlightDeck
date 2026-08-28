#pragma once

#include "configlist.hpp"
#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class BarScrollActions : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, workspaces, true)
    CONFIG_PROPERTY(bool, volume, true)
    CONFIG_PROPERTY(bool, brightness, true)

public:
    explicit BarScrollActions(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarPopouts : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, activeWindow, true)
    CONFIG_PROPERTY(bool, tray, true)
    CONFIG_PROPERTY(bool, statusIcons, true)

public:
    explicit BarPopouts(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarWorkspaces : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, shown, 5)
    CONFIG_PROPERTY(bool, activeIndicator, true)
    CONFIG_PROPERTY(bool, occupiedBg, false)
    CONFIG_PROPERTY(bool, showWindows, true)
    CONFIG_PROPERTY(bool, showWindowsOnSpecialWorkspaces, true)
    CONFIG_PROPERTY(int, maxWindowIcons, 5)
    CONFIG_PROPERTY(bool, activeTrail, false)
    CONFIG_GLOBAL_PROPERTY(bool, perMonitorWorkspaces, true)
    CONFIG_PROPERTY(bool, useIcon, true)
    CONFIG_PROPERTY(QString, label, u" "_s)
    CONFIG_PROPERTY(QString, occupiedLabel, u" 󰮯"_s)
    CONFIG_PROPERTY(QString, activeLabel, u" 󰮯"_s)
    CONFIG_PROPERTY(QString, capitalisation, u"preserve"_s)
    CONFIG_GLOBAL_PROPERTY(QVariantList, specialWorkspaceIcons)
    CONFIG_GLOBAL_PROPERTY(QVariantList, windowIcons,
        { vmap({
            { u"regex"_s, u"steam(_app_(default|[0-9]+))?"_s },
            { u"icon"_s, u"sports_esports"_s },
        }) })
    CONFIG_GLOBAL_PROPERTY(QVariantList, wsIcons)

public:
    explicit BarWorkspaces(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarActiveWindow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, showOnHover, true)

public:
    explicit BarActiveWindow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarTray : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, recolour, false)
    CONFIG_PROPERTY(bool, compact, false)
    CONFIG_GLOBAL_PROPERTY(QVariantList, iconSubs)
    CONFIG_GLOBAL_PROPERTY(QStringList, hiddenIcons)

public:
    explicit BarTray(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showDate, false)
    CONFIG_PROPERTY(bool, showIcon, true)

public:
    explicit BarClock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarDock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, monitorCenter, true)
    CONFIG_PROPERTY(bool, recolourIcons, false)

public:
    explicit BarDock(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarGithub : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)

public:
    explicit BarGithub(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarSpotify : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, background, false)
    CONFIG_PROPERTY(bool, showVisualiser, true)
    CONFIG_PROPERTY(int, maxTitleLength, 25)
    CONFIG_PROPERTY(bool, inverted, false)
    CONFIG_PROPERTY(bool, horizontalVolume, false)
    CONFIG_PROPERTY(bool, autoHide, false)

public:
    explicit BarSpotify(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BarSections : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_SUBOBJECT(EntryList, start)
    CONFIG_SUBOBJECT(EntryList, center)
    CONFIG_SUBOBJECT(EntryList, end)

public:
    explicit BarSections(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_start(new EntryList(this, defaults({
              LIST_ENTRY(logo, true),
              LIST_ENTRY(workspaces, true),
          })))
        , m_center(new EntryList(this, defaults({
              LIST_ENTRY(activeWindow, true),
          })))
        , m_end(new EntryList(this, defaults({
              LIST_ENTRY(tray, true),
              LIST_ENTRY(clock, true),
              LIST_ENTRY(statusIcons, true),
              LIST_ENTRY(power, true),
          }))) {}

    void loadFromJson(const QJsonValue& json) override;

private:
    static QVariantList defaults(const QVariantList& entries) { return entries; }
};

inline void BarSections::loadFromJson(const QJsonValue& json) {
    if (!json.isArray()) {
        ConfigObject::loadFromJson(json);
        return;
    }

    QMap<QString, bool> enabledById;
    for (const auto& value : json.toArray()) {
        const auto obj = value.toObject();
        enabledById.insert(obj.value(QStringLiteral("id")).toString(),
            obj.value(QStringLiteral("enabled")).toBool());
    }

    const auto migrated = [&enabledById](const QVariantList& entries) {
        QVariantList result;
        for (const auto& value : entries) {
            auto props = value.toMap();
            const auto id = props.value(QStringLiteral("id")).toString();
            if (enabledById.contains(id))
                props.insert(QStringLiteral("enabled"), enabledById.value(id));
            result.append(props);
        }
        return result;
    };

    m_start->loadFromJson(QJsonArray::fromVariantList(migrated(defaults({
        LIST_ENTRY(logo, true),
        LIST_ENTRY(workspaces, true),
    }))));
    m_center->loadFromJson(QJsonArray::fromVariantList(migrated(defaults({
        LIST_ENTRY(activeWindow, true),
    }))));
    m_end->loadFromJson(QJsonArray::fromVariantList(migrated(defaults({
        LIST_ENTRY(tray, true),
        LIST_ENTRY(clock, true),
        LIST_ENTRY(statusIcons, true),
        LIST_ENTRY(power, true),
    }))));

    markPropertyLoaded(QStringLiteral("start"));
    markPropertyLoaded(QStringLiteral("center"));
    markPropertyLoaded(QStringLiteral("end"));
}

class BarConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, persistent, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(int, dragThreshold, 20)
    CONFIG_PROPERTY(QString, position, u"left"_s)
    CONFIG_SUBOBJECT(BarScrollActions, scrollActions)
    CONFIG_SUBOBJECT(BarPopouts, popouts)
    CONFIG_SUBOBJECT(BarWorkspaces, workspaces)
    CONFIG_SUBOBJECT(BarActiveWindow, activeWindow)
    CONFIG_SUBOBJECT(BarTray, tray)
    CONFIG_SUBOBJECT(BarClock, clock)
    CONFIG_SUBOBJECT(BarDock, dock)
    CONFIG_SUBOBJECT(BarGithub, github)
    CONFIG_SUBOBJECT(BarSpotify, spotify)
    CONFIG_LIST(EntryList, statusIcons,
        {
            LIST_ENTRY(lockStatus, true),
            LIST_ENTRY(audio, false),
            LIST_ENTRY(microphone, false),
            LIST_ENTRY(kbLayout, false),
            LIST_ENTRY(network, true),
            LIST_ENTRY(bluetooth, true),
            LIST_ENTRY(battery, true),
            LIST_ENTRY(peripheralBattery, false),
            LIST_ENTRY(notifications, true),
        })
    CONFIG_SUBOBJECT(BarSections, entries)
    CONFIG_PROPERTY(QStringList, excludedScreens)
    CONFIG_PROPERTY(QStringList, peripheralBatteryExcluded)

public:
    explicit BarConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_scrollActions(new BarScrollActions(this))
        , m_popouts(new BarPopouts(this))
        , m_workspaces(new BarWorkspaces(this))
        , m_activeWindow(new BarActiveWindow(this))
        , m_tray(new BarTray(this))
        , m_clock(new BarClock(this))
        , m_dock(new BarDock(this))
        , m_github(new BarGithub(this))
        , m_spotify(new BarSpotify(this))
        , m_entries(new BarSections(this)) {}
};

}
