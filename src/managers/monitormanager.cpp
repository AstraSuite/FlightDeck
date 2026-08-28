#include "monitormanager.hpp"
#include "../hyprland/hyprlandstate.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../caelestia/astrahelmwriter.hpp"

namespace Helm::Managers {

MonitorManager* MonitorManager::instance() {
    static MonitorManager inst;
    return &inst;
}

MonitorManager* MonitorManager::create(QQmlEngine*, QJSEngine*) {
    return instance();
}

MonitorManager::MonitorManager(QObject* parent)
    : QObject(parent) {
    connect(Hyprland::HyprlandState::instance(), &Hyprland::HyprlandState::monitorsChanged, this, &MonitorManager::monitorsChanged);
}

QVariantList MonitorManager::liveMonitors() const {
    return Hyprland::HyprlandState::instance()->monitors();
}

QVariantList MonitorManager::configuredMonitors() const {
    return Caelestia::AstraHelmWriter::instance()->monitors();
}

void MonitorManager::applyMonitor(const QString& name, const QString& mode, const QString& pos, qreal scale, int transform, bool disabled) {
    // 1. Update in AstraHelmWriter
    Caelestia::AstraHelmWriter::instance()->setMonitorConfig(name, mode, pos, scale, transform, disabled);

    // 2. Dispatch keyword to running Hyprland for live preview
    if (!disabled) {
        QString transformStr = transform > 0 ? QStringLiteral(",transform,%1").arg(transform) : QString();
        QString monRule = QStringLiteral("%1,%2,%3,%4%5").arg(name, mode, pos).arg(scale).arg(transformStr);
        Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("monitor"), monRule);
    } else {
        Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("monitor"), QStringLiteral("%1,disable").arg(name));
    }

    emit monitorsChanged();
}

void MonitorManager::saveMonitors() {
    Caelestia::AstraHelmWriter::instance()->save();
}

void MonitorManager::refresh() {
    Hyprland::HyprlandState::instance()->refresh();
    emit monitorsChanged();
}

} // namespace Helm::Managers
