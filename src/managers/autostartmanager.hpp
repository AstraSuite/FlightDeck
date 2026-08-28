#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QMap>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class AutostartManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList availableApps READ availableApps NOTIFY appsChanged)
    Q_PROPERTY(QVariantList activeCommands READ activeCommands NOTIFY activeCommandsChanged)

public:
    static AutostartManager* instance();
    static AutostartManager* create(QQmlEngine*, QJSEngine*);

    explicit AutostartManager(QObject* parent = nullptr);

    QVariantList availableApps() const;
    QVariantList activeCommands() const;

    Q_INVOKABLE void toggleApp(const QString& execCmd, bool enabled);
    Q_INVOKABLE void addCustomCommand(const QString& cmd, bool onReload = false);
    Q_INVOKABLE void updateCommand(int index, const QString& cmd, bool onReload = false);
    Q_INVOKABLE void removeCommand(int index);
    Q_INVOKABLE void scanApps();

    // Intelligent Flag & Command Helpers
    Q_INVOKABLE QVariantMap detectMinimizeFlags(const QString& cmdOrBinary) const;
    Q_INVOKABLE QVariantMap parseCommand(const QString& rawCmd, bool onReload = false, bool isReadOnly = false) const;
    Q_INVOKABLE QString buildFinalCommand(const QString& baseCmd, int delay = 0, bool startMinimized = false, const QString& minimizeFlag = QString()) const;

signals:
    void appsChanged();
    void activeCommandsChanged();

private:
    QVariantList m_apps;
    mutable QMap<QString, QString> m_minimizeFlagCache;
};

} // namespace FlightDeck::Managers
