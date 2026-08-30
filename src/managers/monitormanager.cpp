#include "monitormanager.hpp"
#include "../hyprland/hyprlandstate.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../caelestia/flightdeckwriter.hpp"

namespace FlightDeck::Managers {

MonitorManager* MonitorManager::instance() {
    static MonitorManager inst;
    return &inst;
}

MonitorManager* MonitorManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

MonitorManager::MonitorManager(QObject* parent)
    : QObject(parent) {
    connect(Hyprland::HyprlandState::instance(), &Hyprland::HyprlandState::monitorsChanged, this, &MonitorManager::monitorsChanged);
}

QVariantList MonitorManager::liveMonitors() const {
    QVariantList live = Hyprland::HyprlandState::instance()->monitors();
    QVariantList configured = Caelestia::FlightDeckWriter::instance()->monitors();

    QHash<QString, QVariantMap> confMap;
    for (const auto& item : configured) {
        QVariantMap m = item.toMap();
        QString out = m.value(QStringLiteral("output")).toString();
        if (!out.isEmpty()) {
            confMap.insert(out, m);
        }
    }

    QVariantList result;
    for (const auto& item : live) {
        QVariantMap mon = item.toMap();
        QString name = mon.value(QStringLiteral("name")).toString();
        QString desc = mon.value(QStringLiteral("description")).toString();
        QString descPrefix = desc.split(QLatin1Char(',')).first().trimmed();

        QVariantMap cm;
        if (confMap.contains(name)) {
            cm = confMap.value(name);
        } else if (!descPrefix.isEmpty() && confMap.contains(QStringLiteral("desc:") + descPrefix)) {
            cm = confMap.value(QStringLiteral("desc:") + descPrefix);
        }

        if (!cm.isEmpty()) {
            for (auto it = cm.constBegin(); it != cm.constEnd(); ++it) {
                if (it.key() != QStringLiteral("name") && it.key() != QStringLiteral("output")) {
                    mon[it.key()] = it.value();
                }
            }

            if (cm.contains(QStringLiteral("position"))) {
                QString posStr = cm.value(QStringLiteral("position")).toString();
                QStringList p = posStr.split(QLatin1Char('x'));
                if (p.size() == 2) {
                    mon[QStringLiteral("x")] = p[0].toInt();
                    mon[QStringLiteral("y")] = p[1].toInt();
                }
            }

            if (cm.contains(QStringLiteral("mode"))) {
                QString modeStr = cm.value(QStringLiteral("mode")).toString();
                if (modeStr.contains(QLatin1Char('@'))) {
                    QStringList mp = modeStr.split(QLatin1Char('@'));
                    QStringList res = mp[0].split(QLatin1Char('x'));
                    if (res.size() == 2) {
                        mon[QStringLiteral("width")] = res[0].toInt();
                        mon[QStringLiteral("height")] = res[1].toInt();
                    }
                    QString hzStr = mp[1];
                    hzStr.remove(QStringLiteral("Hz"), Qt::CaseInsensitive);
                    bool ok = false;
                    double hz = hzStr.toDouble(&ok);
                    if (ok && hz > 0) {
                        mon[QStringLiteral("refreshRate")] = hz;
                    }
                }
            }
        }
        result.append(mon);
    }
    return result.isEmpty() ? live : result;
}

QVariantList MonitorManager::configuredMonitors() const {
    return Caelestia::FlightDeckWriter::instance()->monitors();
}

void MonitorManager::applyMonitor(const QVariantMap& monitorData) {
    QString name = monitorData.value(QStringLiteral("output")).toString();
    if (name.isEmpty()) {
        name = monitorData.value(QStringLiteral("name")).toString();
    }
    if (name.isEmpty()) return;

    QVariantMap mon = monitorData;
    mon[QStringLiteral("output")] = name;

    // 1. Update in FlightDeckWriter
    Caelestia::FlightDeckWriter::instance()->setMonitorConfig(mon);

    // 2. Dispatch live monitor config to Hyprland
    Hyprland::HyprlandSocket::instance()->applyMonitor(mon);

    emit monitorsChanged();
}

void MonitorManager::applyMonitor(const QString& name, const QString& mode, const QString& pos, qreal scale, int transform, bool disabled) {
    QVariantMap mon;
    mon[QStringLiteral("output")] = name;
    mon[QStringLiteral("mode")] = mode;
    mon[QStringLiteral("position")] = pos;
    mon[QStringLiteral("scale")] = scale;
    mon[QStringLiteral("transform")] = transform;
    mon[QStringLiteral("disabled")] = disabled;

    applyMonitor(mon);
}

QVariantList MonitorManager::computeValidScales(int width, int height, qreal minScale, qreal maxScale) const {
    if (width <= 0 || height <= 0) {
        QVariantMap defaultOpt;
        defaultOpt[QStringLiteral("value")] = 1.0;
        defaultOpt[QStringLiteral("label")] = QStringLiteral("1.00");
        defaultOpt[QStringLiteral("percent")] = QStringLiteral("100%");
        return { defaultOpt };
    }

    QVariantList scales;
    QSet<QString> seenLabels;
    int minTick = qRound(minScale * 120.0);
    int maxTick = qRound(maxScale * 120.0);
    qint64 w120 = static_cast<qint64>(width) * 120;
    qint64 h120 = static_cast<qint64>(height) * 120;
    const int minEffective = 512;

    for (int tick = qMax(1, minTick); tick <= maxTick; ++tick) {
        if (w120 % tick != 0 || h120 % tick != 0) continue;
        if (w120 / tick < minEffective || h120 / tick < minEffective) break;

        qreal s = tick / 120.0;
        QString label = QString::number(s, 'f', 2);
        while (label.endsWith(QLatin1Char('0')) && label.contains(QLatin1Char('.'))) {
            label.chop(1);
        }
        if (label.endsWith(QLatin1Char('.'))) {
            label.chop(1);
        }

        if (!seenLabels.contains(label)) {
            seenLabels.insert(label);
            QVariantMap opt;
            opt[QStringLiteral("value")] = s;
            opt[QStringLiteral("label")] = label;
            opt[QStringLiteral("percent")] = QStringLiteral("%1%").arg(qRound(s * 100));
            scales.append(opt);
        }
    }

    if (scales.isEmpty()) {
        QVariantMap defaultOpt;
        defaultOpt[QStringLiteral("value")] = 1.0;
        defaultOpt[QStringLiteral("label")] = QStringLiteral("1.00");
        defaultOpt[QStringLiteral("percent")] = QStringLiteral("100%");
        scales.append(defaultOpt);
    }

    return scales;
}

QString MonitorManager::validateMirror(const QString& monitorName, const QString& mirrorTarget) const {
    if (mirrorTarget.isEmpty() || mirrorTarget == QLatin1String("none") || mirrorTarget == QLatin1String("Off")) {
        return QString();
    }
    if (monitorName == mirrorTarget) {
        return QStringLiteral("A monitor cannot mirror itself");
    }

    const QVariantList mons = liveMonitors();
    bool targetFound = false;
    for (const auto& item : mons) {
        QVariantMap m = item.toMap();
        QString mName = m.value(QStringLiteral("name")).toString();
        if (mName == mirrorTarget) {
            targetFound = true;
            if (m.value(QStringLiteral("disabled")).toBool()) {
                return QStringLiteral("Cannot mirror disabled monitor '%1'").arg(mirrorTarget);
            }
            QString targetMirror = m.value(QStringLiteral("mirror")).toString();
            if (targetMirror.isEmpty()) {
                targetMirror = m.value(QStringLiteral("mirror_of")).toString();
            }
            if (!targetMirror.isEmpty() && targetMirror != QLatin1String("none")) {
                return QStringLiteral("Cannot mirror '%1' — it is already mirroring '%2'").arg(mirrorTarget, targetMirror);
            }
            break;
        }
    }

    if (!targetFound) {
        return QStringLiteral("Mirror target '%1' not found").arg(mirrorTarget);
    }

    return QString();
}

void MonitorManager::saveMonitors() {
    Caelestia::FlightDeckWriter::instance()->save();
}

void MonitorManager::refresh() {
    Hyprland::HyprlandState::instance()->refresh();
    emit monitorsChanged();
}

} // namespace FlightDeck::Managers
