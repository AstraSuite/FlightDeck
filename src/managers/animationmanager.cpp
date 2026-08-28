#include "animationmanager.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../caelestia/astrahelmwriter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>

namespace Helm::Managers {

AnimationManager* AnimationManager::instance() {
    static AnimationManager inst;
    return &inst;
}

AnimationManager* AnimationManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

AnimationManager::AnimationManager(QObject* parent)
    : QObject(parent) {
    m_curves = QVariantList{
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("ease")}, {QStringLiteral("x1"), 0.25}, {QStringLiteral("y1"), 0.1}, {QStringLiteral("x2"), 0.25}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeIn")}, {QStringLiteral("x1"), 0.42}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 1.0}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeOut")}, {QStringLiteral("x1"), 0.0}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.58}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeInOut")}, {QStringLiteral("x1"), 0.42}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.58}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_standard")}, {QStringLiteral("x1"), 0.2}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.0}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_decel")}, {QStringLiteral("x1"), 0.05}, {QStringLiteral("y1"), 0.7}, {QStringLiteral("x2"), 0.1}, {QStringLiteral("y2"), 1.0} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_accel")}, {QStringLiteral("x1"), 0.3}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.8}, {QStringLiteral("y2"), 0.15} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("overshot")}, {QStringLiteral("x1"), 0.05}, {QStringLiteral("y1"), 0.9}, {QStringLiteral("x2"), 0.1}, {QStringLiteral("y2"), 1.1} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("fluent")}, {QStringLiteral("x1"), 0.0}, {QStringLiteral("y1"), 0.8}, {QStringLiteral("x2"), 0.2}, {QStringLiteral("y2"), 1.0} }
    };

    m_targets = QVariantList{
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windows")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsIn")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 85%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsOut")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_accel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsMove")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_standard")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("workspaces")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("slide")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("specialWorkspace")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("slidevert")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fade")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fadeIn")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fadeOut")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 2.5}, {QStringLiteral("curve"), QStringLiteral("md3_accel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("border")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 5.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("layers")}, {QStringLiteral("enabled"), true}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} }
    };

    scanPresets();
}

QString AnimationManager::activePreset() const {
    return m_activePreset;
}

void AnimationManager::setActivePreset(const QString& preset) {
    if (m_activePreset != preset) {
        m_activePreset = preset;
        applyPreset(preset);
        emit presetChanged();
    }
}

QStringList AnimationManager::availablePresets() const {
    return m_presets;
}

QVariantList AnimationManager::bezierCurves() const {
    return m_curves;
}

QVariantList AnimationManager::animationTargets() const {
    return m_targets;
}

void AnimationManager::testCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2) {
    const QString bezierCmd = QStringLiteral("%1, %2, %3, %4, %5").arg(name).arg(x1, 0, 'f', 3).arg(y1, 0, 'f', 3).arg(x2, 0, 'f', 3).arg(y2, 0, 'f', 3);
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("bezier"), bezierCmd);
}

void AnimationManager::addBezierCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2) {
    if (name.trimmed().isEmpty()) return;

    for (int i = 0; i < m_curves.size(); ++i) {
        QVariantMap map = m_curves[i].toMap();
        if (map.value(QStringLiteral("name")).toString() == name) {
            map[QStringLiteral("x1")] = x1;
            map[QStringLiteral("y1")] = y1;
            map[QStringLiteral("x2")] = x2;
            map[QStringLiteral("y2")] = y2;
            m_curves[i] = map;
            testCurve(name, x1, y1, x2, y2);
            emit curvesChanged();
            return;
        }
    }

    m_curves.append(QVariantMap{
        { QStringLiteral("name"), name },
        { QStringLiteral("x1"), x1 },
        { QStringLiteral("y1"), y1 },
        { QStringLiteral("x2"), x2 },
        { QStringLiteral("y2"), y2 }
    });

    testCurve(name, x1, y1, x2, y2);
    emit curvesChanged();
}

void AnimationManager::removeBezierCurve(const QString& name) {
    for (int i = 0; i < m_curves.size(); ++i) {
        if (m_curves[i].toMap().value(QStringLiteral("name")).toString() == name) {
            m_curves.removeAt(i);
            emit curvesChanged();
            return;
        }
    }
}

void AnimationManager::setTargetEnabled(const QString& target, bool enabled) {
    for (int i = 0; i < m_targets.size(); ++i) {
        QVariantMap map = m_targets[i].toMap();
        if (map.value(QStringLiteral("target")).toString() == target) {
            map[QStringLiteral("enabled")] = enabled;
            m_targets[i] = map;
            emit targetsChanged();
            return;
        }
    }
}

void AnimationManager::applyPreset(const QString& presetName) {
    const QString animPath = QDir::homePath() + QStringLiteral("/.config/caelestia/animations/") + presetName + QStringLiteral(".lua");
    if (QFile::exists(animPath)) {
        Hyprland::HyprlandSocket::instance()->evalLua(QStringLiteral("dofile(\"%1\")").arg(animPath));
    }
}

void AnimationManager::scanPresets() {
    m_presets.clear();
    const QString animDir = QDir::homePath() + QStringLiteral("/.config/caelestia/animations");
    QDir dir(animDir);
    if (dir.exists()) {
        const QStringList files = dir.entryList({ QStringLiteral("*.lua") }, QDir::Files);
        for (const QString& f : files) {
            m_presets.append(QFileInfo(f).baseName());
        }
    }
    if (!m_presets.isEmpty() && m_activePreset.isEmpty()) {
        m_activePreset = m_presets.first();
    }
    emit presetsChanged();
}

} // namespace Helm::Managers
