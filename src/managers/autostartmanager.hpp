#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class AutostartManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList availableApps READ availableApps NOTIFY appsChanged)
    Q_PROPERTY(QStringList activeCommands READ activeCommands NOTIFY activeCommandsChanged)

public:
    static AutostartManager* instance();
    static AutostartManager* create(QQmlEngine*, QJSEngine*);

    explicit AutostartManager(QObject* parent = nullptr);

    QVariantList availableApps() const;
    QStringList activeCommands() const;

    Q_INVOKABLE void toggleApp(const QString& execCmd, bool enabled);
    Q_INVOKABLE void addCustomCommand(const QString& cmd);
    Q_INVOKABLE void updateCommand(int index, const QString& cmd);
    Q_INVOKABLE void removeCommand(int index);
    Q_INVOKABLE void scanApps();

signals:
    void appsChanged();
    void activeCommandsChanged();

private:
    QVariantList m_apps;
};

} // namespace FlightDeck::Managers
