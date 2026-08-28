#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>

namespace Helm::Managers {

class MonitorManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList liveMonitors READ liveMonitors NOTIFY monitorsChanged)
    Q_PROPERTY(QVariantList configuredMonitors READ configuredMonitors NOTIFY monitorsChanged)

public:
    static MonitorManager* instance();
    static MonitorManager* create(QQmlEngine*, QJSEngine*);

    explicit MonitorManager(QObject* parent = nullptr);

    QVariantList liveMonitors() const;
    QVariantList configuredMonitors() const;

    Q_INVOKABLE void applyMonitor(const QString& name, const QString& mode, const QString& pos, qreal scale, int transform = 0, bool disabled = false);
    Q_INVOKABLE void saveMonitors();
    Q_INVOKABLE void refresh();

signals:
    void monitorsChanged();
};

} // namespace Helm::Managers
