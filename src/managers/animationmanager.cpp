#include "animationmanager.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../caelestia/flightdeckwriter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QMap>

namespace FlightDeck::Managers {

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
    auto writer = FlightDeck::Caelestia::FlightDeckWriter::instance();
    connect(writer, &FlightDeck::Caelestia::FlightDeckWriter::bezierCurvesChanged, this, [this]() {
        refresh();
    });
    connect(writer, &FlightDeck::Caelestia::FlightDeckWriter::animationTargetsChanged, this, [this]() {
        refresh();
    });

    refresh();
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
    const QString curveName = name.trimmed().isEmpty() ? QStringLiteral("custom") : name.trimmed();
    const QString bezierCmd = QStringLiteral("%1, %2, %3, %4, %5").arg(curveName).arg(x1, 0, 'f', 3).arg(y1, 0, 'f', 3).arg(x2, 0, 'f', 3).arg(y2, 0, 'f', 3);
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("bezier"), bezierCmd);
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("animation"), QStringLiteral("windows, 1, 6, %1, popin").arg(curveName));
}

void AnimationManager::addBezierCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2) {
    if (name.trimmed().isEmpty()) return;

    FlightDeck::Caelestia::FlightDeckWriter::instance()->addBezierCurve(name, x1, y1, x2, y2);
    FlightDeck::Caelestia::FlightDeckWriter::instance()->save();

    testCurve(name, x1, y1, x2, y2);
    refresh();
}

void AnimationManager::removeBezierCurve(const QString& name) {
    FlightDeck::Caelestia::FlightDeckWriter::instance()->removeBezierCurve(name);
    FlightDeck::Caelestia::FlightDeckWriter::instance()->save();
    refresh();
}

void AnimationManager::setTargetEnabled(const QString& target, bool enabled) {
    FlightDeck::Caelestia::FlightDeckWriter::instance()->setAnimationTargetEnabled(target, enabled);
    FlightDeck::Caelestia::FlightDeckWriter::instance()->save();
    refresh();
}

void AnimationManager::updateTarget(const QString& target, bool enabled, qreal speed, const QString& curve, const QString& style) {
    FlightDeck::Caelestia::FlightDeckWriter::instance()->setAnimationTarget(target, enabled, speed, curve, style);
    FlightDeck::Caelestia::FlightDeckWriter::instance()->save();
    refresh();
}

bool AnimationManager::save() {
    return FlightDeck::Caelestia::FlightDeckWriter::instance()->save();
}

void AnimationManager::applyPreset(const QString& presetName) {
    const QString animDir = QDir::homePath() + QStringLiteral("/.config/caelestia/animations");
    const QString animPath = animDir + QStringLiteral("/") + presetName + QStringLiteral(".lua");
    if (!QFile::exists(animPath)) {
        QDir().mkpath(animDir);
        QFile f(animPath);
        if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QString presetLua = QStringLiteral("-- Caelestia %1 animation preset\n").arg(presetName);
            if (presetName == QLatin1String("snappy")) {
                presetLua += QStringLiteral(
                    "hl.curve(\"overshot\", { type = \"bezier\", points = { { 0.13, 0.99 }, { 0.29, 1.08 } } })\n"
                    "hl.animation({ leaf = \"windows\", enabled = true, speed = 5, bezier = \"overshot\", style = \"popin\" })\n"
                    "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 4, bezier = \"overshot\", style = \"slide\" })\n"
                );
            } else if (presetName == QLatin1String("gentle")) {
                presetLua += QStringLiteral(
                    "hl.curve(\"gentleDecel\", { type = \"bezier\", points = { { 0.05, 0.7 }, { 0.1, 1.0 } } })\n"
                    "hl.animation({ leaf = \"windows\", enabled = true, speed = 7, bezier = \"gentleDecel\", style = \"popin 80%\" })\n"
                    "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 6, bezier = \"gentleDecel\", style = \"slide\" })\n"
                );
            } else {
                presetLua += QStringLiteral(
                    "hl.curve(\"standard\", { type = \"bezier\", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })\n"
                    "hl.animation({ leaf = \"windows\", enabled = true, speed = 6, bezier = \"standard\", style = \"popin 80%\" })\n"
                    "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 5, bezier = \"standard\", style = \"slide\" })\n"
                );
            }
            f.write(presetLua.toUtf8());
            f.close();
        }
    }
    if (QFile::exists(animPath)) {
        Hyprland::HyprlandSocket::instance()->evalLua(QStringLiteral("dofile(\"%1\")").arg(animPath));
    }
}

void AnimationManager::scanPresets() {
    m_presets.clear();
    const QString animDir = QDir::homePath() + QStringLiteral("/.config/caelestia/animations");
    QDir dir(animDir);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }
    const QStringList files = dir.entryList({ QStringLiteral("*.lua") }, QDir::Files);
    for (const QString& f : files) {
        m_presets.append(QFileInfo(f).baseName());
    }
    if (m_presets.isEmpty()) {
        m_presets = { QStringLiteral("default"), QStringLiteral("snappy"), QStringLiteral("gentle"), QStringLiteral("material3") };
    }
    if (!m_presets.isEmpty() && m_activePreset.isEmpty()) {
        m_activePreset = m_presets.first();
    }
    emit presetsChanged();
}

void AnimationManager::refresh() {
    QMap<QString, QVariantMap> curveMap;
    QMap<QString, QVariantMap> targetMap;

    static const QVariantList defaultCurves{
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("ease")}, {QStringLiteral("x1"), 0.25}, {QStringLiteral("y1"), 0.1}, {QStringLiteral("x2"), 0.25}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeIn")}, {QStringLiteral("x1"), 0.42}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 1.0}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeOut")}, {QStringLiteral("x1"), 0.0}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.58}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("easeInOut")}, {QStringLiteral("x1"), 0.42}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.58}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_standard")}, {QStringLiteral("x1"), 0.2}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.0}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_decel")}, {QStringLiteral("x1"), 0.05}, {QStringLiteral("y1"), 0.7}, {QStringLiteral("x2"), 0.1}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("md3_accel")}, {QStringLiteral("x1"), 0.3}, {QStringLiteral("y1"), 0.0}, {QStringLiteral("x2"), 0.8}, {QStringLiteral("y2"), 0.15}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("overshot")}, {QStringLiteral("x1"), 0.05}, {QStringLiteral("y1"), 0.9}, {QStringLiteral("x2"), 0.1}, {QStringLiteral("y2"), 1.1}, {QStringLiteral("isReadOnly"), true} },
        QVariantMap{ {QStringLiteral("name"), QStringLiteral("fluent")}, {QStringLiteral("x1"), 0.0}, {QStringLiteral("y1"), 0.8}, {QStringLiteral("x2"), 0.2}, {QStringLiteral("y2"), 1.0}, {QStringLiteral("isReadOnly"), true} }
    };
    for (const auto& c : defaultCurves) {
        curveMap[c.toMap().value(QStringLiteral("name")).toString()] = c.toMap();
    }

    static const QVariantList defaultTargets{
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windows")}, {QStringLiteral("name"), QStringLiteral("windows")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 4.0}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsIn")}, {QStringLiteral("name"), QStringLiteral("windowsIn")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.5}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 85%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsOut")}, {QStringLiteral("name"), QStringLiteral("windowsOut")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.0}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_accel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("windowsMove")}, {QStringLiteral("name"), QStringLiteral("windowsMove")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.5}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_standard")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("workspaces")}, {QStringLiteral("name"), QStringLiteral("workspaces")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 4.0}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("slide")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("specialWorkspace")}, {QStringLiteral("name"), QStringLiteral("specialWorkspace")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 4.0}, {QStringLiteral("duration"), 4.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("slidevert")} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fade")}, {QStringLiteral("name"), QStringLiteral("fade")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.0}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fadeIn")}, {QStringLiteral("name"), QStringLiteral("fadeIn")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.0}, {QStringLiteral("duration"), 3.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("fadeOut")}, {QStringLiteral("name"), QStringLiteral("fadeOut")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 2.5}, {QStringLiteral("duration"), 2.5}, {QStringLiteral("curve"), QStringLiteral("md3_accel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("border")}, {QStringLiteral("name"), QStringLiteral("border")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 5.0}, {QStringLiteral("duration"), 5.0}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QString()} },
        QVariantMap{ {QStringLiteral("target"), QStringLiteral("layers")}, {QStringLiteral("name"), QStringLiteral("layers")}, {QStringLiteral("enabled"), true}, {QStringLiteral("speed"), 3.5}, {QStringLiteral("duration"), 3.5}, {QStringLiteral("curve"), QStringLiteral("md3_decel")}, {QStringLiteral("style"), QStringLiteral("popin 80%")} }
    };
    for (const auto& t : defaultTargets) {
        targetMap[t.toMap().value(QStringLiteral("target")).toString()] = t.toMap();
    }

    auto socket = Hyprland::HyprlandSocket::instance();
    if (socket && socket->isOnline()) {
        QJsonDocument doc = socket->queryJson(QStringLiteral("animations"));
        if (doc.isArray()) {
            QJsonArray rootArr = doc.array();
            if (rootArr.size() >= 1 && rootArr[0].isArray()) {
                QJsonArray anims = rootArr[0].toArray();
                for (const auto& val : anims) {
                    QJsonObject obj = val.toObject();
                    QString name = obj.value(QStringLiteral("name")).toString();
                    if (name.isEmpty()) continue;
                    bool enabled = obj.value(QStringLiteral("enabled")).toBool(true);
                    qreal speed = obj.value(QStringLiteral("speed")).toDouble(5.0);
                    QString bezier = obj.value(QStringLiteral("bezier")).toString();
                    QString style = obj.value(QStringLiteral("style")).toString();

                    QVariantMap m = targetMap.value(name);
                    m[QStringLiteral("target")] = name;
                    m[QStringLiteral("name")] = name;
                    m[QStringLiteral("enabled")] = enabled;
                    m[QStringLiteral("speed")] = speed;
                    m[QStringLiteral("duration")] = speed;
                    if (!bezier.isEmpty()) m[QStringLiteral("curve")] = bezier;
                    if (!bezier.isEmpty()) m[QStringLiteral("bezier")] = bezier;
                    if (!style.isEmpty()) m[QStringLiteral("style")] = style;
                    targetMap[name] = m;
                }
            }
            if (rootArr.size() >= 2 && rootArr[1].isArray()) {
                QJsonArray beziers = rootArr[1].toArray();
                for (const auto& val : beziers) {
                    QJsonObject obj = val.toObject();
                    QString name = obj.value(QStringLiteral("name")).toString();
                    if (name.isEmpty()) continue;
                    qreal x1 = obj.value(QStringLiteral("X0")).toDouble();
                    qreal y1 = obj.value(QStringLiteral("Y0")).toDouble();
                    qreal x2 = obj.value(QStringLiteral("X1")).toDouble();
                    qreal y2 = obj.value(QStringLiteral("Y1")).toDouble();

                    QVariantMap m = curveMap.value(name);
                    m[QStringLiteral("name")] = name;
                    m[QStringLiteral("x1")] = x1;
                    m[QStringLiteral("y1")] = y1;
                    m[QStringLiteral("x2")] = x2;
                    m[QStringLiteral("y2")] = y2;
                    m[QStringLiteral("isReadOnly")] = true;
                    curveMap[name] = m;
                }
            }
        }
    }

    auto writer = FlightDeck::Caelestia::FlightDeckWriter::instance();
    for (const auto& cVal : writer->bezierCurves()) {
        QVariantMap c = cVal.toMap();
        QString name = c.value(QStringLiteral("name")).toString();
        if (!name.isEmpty()) {
            curveMap[name] = c;
        }
    }
    for (const auto& tVal : writer->animationTargets()) {
        QVariantMap t = tVal.toMap();
        QString name = t.value(QStringLiteral("target")).toString();
        if (name.isEmpty()) name = t.value(QStringLiteral("name")).toString();
        if (!name.isEmpty()) {
            targetMap[name] = t;
        }
    }

    m_curves.clear();
    for (auto it = curveMap.constBegin(); it != curveMap.constEnd(); ++it) {
        m_curves.append(it.value());
    }

    m_targets.clear();
    for (auto it = targetMap.constBegin(); it != targetMap.constEnd(); ++it) {
        m_targets.append(it.value());
    }

    emit curvesChanged();
    emit targetsChanged();
}

} // namespace FlightDeck::Managers
