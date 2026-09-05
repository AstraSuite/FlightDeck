#include "flightdeckwriter.hpp"
#include "luavalidator.hpp"
#include "../hyprland/hyprlandschema.hpp"
#include "../hyprland/hyprlandsocket.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QProcess>

namespace FlightDeck::Caelestia {

static QString escapeLuaString(const QString& str);
static QString unescapeLuaString(const QString& str);
static QString formatLuaBindFlags(const QVariantMap& flags);

FlightDeckWriter* FlightDeckWriter::instance() {
    static FlightDeckWriter inst;
    return &inst;
}

FlightDeckWriter* FlightDeckWriter::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QString FlightDeckWriter::flightDeckFilePath() {
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    const QString p1 = base + QStringLiteral("/caelestia/astra-flightdeck.lua");
    if (QFile::exists(p1)) return p1;
    const QString p2 = base + QStringLiteral("/caelestia/astra-helm.lua");
    if (QFile::exists(p2)) return p2;
    const QString p3 = base + QStringLiteral("/hypr/astra-flightdeck.lua");
    if (QFile::exists(p3)) return p3;
    return p1;
}

QString FlightDeckWriter::astraHelmFilePath() {
    return flightDeckFilePath();
}

FlightDeckWriter::FlightDeckWriter(QObject* parent)
    : QObject(parent) {
    loadFromFile();
}

bool FlightDeckWriter::isDirty() const {
    return m_isDirty;
}

int FlightDeckWriter::dirtyCount() const {
    return m_isDirty ? 1 : 0;
}

QVariantList FlightDeckWriter::monitors() const {
    return m_monitors;
}

void FlightDeckWriter::setMonitors(const QVariantList& monitors) {
    if (m_monitors != monitors) {
        m_monitors = monitors;
        m_isDirty = true;
        emit monitorsChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::windowRules() const {
    return m_windowRules;
}

void FlightDeckWriter::setWindowRules(const QVariantList& rules) {
    if (m_windowRules != rules) {
        m_windowRules = rules;
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::layerRules() const {
    return m_layerRules;
}

void FlightDeckWriter::setLayerRules(const QVariantList& rules) {
    if (m_layerRules != rules) {
        m_layerRules = rules;
        m_isDirty = true;
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::workspaceRules() const {
    return m_workspaceRules;
}

void FlightDeckWriter::setWorkspaceRules(const QVariantList& rules) {
    if (m_workspaceRules != rules) {
        m_workspaceRules = rules;
        m_isDirty = true;
        emit workspaceRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::customBinds() const {
    return m_customBinds;
}

void FlightDeckWriter::setCustomBinds(const QVariantList& binds) {
    if (m_customBinds != binds) {
        m_customBinds = binds;
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

QStringList FlightDeckWriter::autostartCommands() const {
    QStringList list;
    for (const auto& item : m_autostartEntries) {
        list.append(item.toMap().value(QStringLiteral("command")).toString());
    }
    return list;
}

void FlightDeckWriter::setAutostartCommands(const QStringList& cmds) {
    QVariantList entries;
    for (const QString& cmd : cmds) {
        QVariantMap entry;
        entry[QStringLiteral("command")] = cmd;
        entry[QStringLiteral("onReload")] = false;
        entries.append(entry);
    }
    setAutostartEntries(entries);
}

QVariantList FlightDeckWriter::autostartEntries() const {
    return m_autostartEntries;
}

void FlightDeckWriter::setAutostartEntries(const QVariantList& entries) {
    if (m_autostartEntries != entries) {
        m_autostartEntries = entries;
        m_autostartCommands.clear();
        for (const auto& item : m_autostartEntries) {
            m_autostartCommands.append(item.toMap().value(QStringLiteral("command")).toString());
        }
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

QVariantMap FlightDeckWriter::pluginConfigs() const {
    return m_pluginConfigs;
}

void FlightDeckWriter::setPluginConfigs(const QVariantMap& plugins) {
    if (m_pluginConfigs != plugins) {
        m_pluginConfigs = plugins;
        m_isDirty = true;
        emit pluginsChanged();
        emit dirtyChanged();
    }
}

QVariantMap FlightDeckWriter::hyprOptions() const {
    return m_hyprOptions;
}

void FlightDeckWriter::setHyprOptions(const QVariantMap& options) {
    if (m_hyprOptions != options) {
        m_hyprOptions = options;
        m_isDirty = true;
        emit hyprOptionsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::setHyprOption(const QString& key, const QVariant& value) {
    QString canonicalKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(key);
    if (m_hyprOptions.value(canonicalKey) != value) {
        m_hyprOptions[canonicalKey] = value;
        m_isDirty = true;
        emit hyprOptionsChanged();
        emit dirtyChanged();
    }
}

QVariant FlightDeckWriter::getHyprOption(const QString& key, const QVariant& fallback) const {
    QString canonicalKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(key);
    if (m_hyprOptions.contains(canonicalKey)) {
        return m_hyprOptions.value(canonicalKey);
    }
    if (m_hyprOptions.contains(key)) {
        return m_hyprOptions.value(key);
    }
    return fallback;
}

bool FlightDeckWriter::hasHyprOption(const QString& key) const {
    QString canonicalKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(key);
    return m_hyprOptions.contains(canonicalKey) || m_hyprOptions.contains(key);
}

void FlightDeckWriter::removeHyprOption(const QString& key) {
    QString canonicalKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(key);
    bool changed = false;
    if (m_hyprOptions.contains(canonicalKey)) {
        m_hyprOptions.remove(canonicalKey);
        changed = true;
    }
    if (m_hyprOptions.contains(key)) {
        m_hyprOptions.remove(key);
        changed = true;
    }
    if (changed) {
        m_isDirty = true;
        emit hyprOptionsChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::bezierCurves() const {
    return m_bezierCurves;
}

void FlightDeckWriter::setBezierCurves(const QVariantList& curves) {
    if (m_bezierCurves != curves) {
        m_bezierCurves = curves;
        m_isDirty = true;
        emit bezierCurvesChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::animationTargets() const {
    return m_animationTargets;
}

void FlightDeckWriter::setAnimationTargets(const QVariantList& targets) {
    if (m_animationTargets != targets) {
        m_animationTargets = targets;
        m_isDirty = true;
        emit animationTargetsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addBezierCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2) {
    if (name.trimmed().isEmpty()) return;

    for (int i = 0; i < m_bezierCurves.size(); ++i) {
        QVariantMap map = m_bezierCurves[i].toMap();
        if (map.value(QStringLiteral("name")).toString() == name) {
            map[QStringLiteral("x1")] = x1;
            map[QStringLiteral("y1")] = y1;
            map[QStringLiteral("x2")] = x2;
            map[QStringLiteral("y2")] = y2;
            map[QStringLiteral("isReadOnly")] = false;
            map[QStringLiteral("source")] = QStringLiteral("flightdeck");
            m_bezierCurves[i] = map;
            m_isDirty = true;
            emit bezierCurvesChanged();
            emit dirtyChanged();
            return;
        }
    }

    m_bezierCurves.append(QVariantMap{
        { QStringLiteral("name"), name },
        { QStringLiteral("x1"), x1 },
        { QStringLiteral("y1"), y1 },
        { QStringLiteral("x2"), x2 },
        { QStringLiteral("y2"), y2 },
        { QStringLiteral("isReadOnly"), false },
        { QStringLiteral("source"), QStringLiteral("flightdeck") }
    });

    m_isDirty = true;
    emit bezierCurvesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeBezierCurve(const QString& name) {
    for (int i = 0; i < m_bezierCurves.size(); ++i) {
        if (m_bezierCurves[i].toMap().value(QStringLiteral("name")).toString() == name) {
            m_bezierCurves.removeAt(i);
            m_isDirty = true;
            emit bezierCurvesChanged();
            emit dirtyChanged();
            return;
        }
    }
}

void FlightDeckWriter::setAnimationTarget(const QString& target, bool enabled, qreal speed, const QString& curve, const QString& style) {
    if (target.trimmed().isEmpty()) return;

    for (int i = 0; i < m_animationTargets.size(); ++i) {
        QVariantMap map = m_animationTargets[i].toMap();
        QString t = map.value(QStringLiteral("target")).toString();
        if (t.isEmpty()) t = map.value(QStringLiteral("name")).toString();
        if (t == target) {
            map[QStringLiteral("target")] = target;
            map[QStringLiteral("name")] = target;
            map[QStringLiteral("enabled")] = enabled;
            map[QStringLiteral("speed")] = speed;
            map[QStringLiteral("duration")] = speed;
            map[QStringLiteral("curve")] = curve;
            map[QStringLiteral("bezier")] = curve;
            map[QStringLiteral("style")] = style;
            map[QStringLiteral("isReadOnly")] = false;
            map[QStringLiteral("source")] = QStringLiteral("flightdeck");
            m_animationTargets[i] = map;
            m_isDirty = true;
            emit animationTargetsChanged();
            emit dirtyChanged();
            return;
        }
    }

    m_animationTargets.append(QVariantMap{
        { QStringLiteral("target"), target },
        { QStringLiteral("name"), target },
        { QStringLiteral("enabled"), enabled },
        { QStringLiteral("speed"), speed },
        { QStringLiteral("duration"), speed },
        { QStringLiteral("curve"), curve },
        { QStringLiteral("bezier"), curve },
        { QStringLiteral("style"), style },
        { QStringLiteral("isReadOnly"), false },
        { QStringLiteral("source"), QStringLiteral("flightdeck") }
    });

    m_isDirty = true;
    emit animationTargetsChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::setAnimationTargetEnabled(const QString& target, bool enabled) {
    for (int i = 0; i < m_animationTargets.size(); ++i) {
        QVariantMap map = m_animationTargets[i].toMap();
        QString t = map.value(QStringLiteral("target")).toString();
        if (t.isEmpty()) t = map.value(QStringLiteral("name")).toString();
        if (t == target) {
            map[QStringLiteral("enabled")] = enabled;
            map[QStringLiteral("isReadOnly")] = false;
            map[QStringLiteral("source")] = QStringLiteral("flightdeck");
            m_animationTargets[i] = map;
            m_isDirty = true;
            emit animationTargetsChanged();
            emit dirtyChanged();
            return;
        }
    }
}


static QString formatWindowRuleLua(const QVariantMap& rule) {
    QString windowRulesStr = QStringLiteral("hl.window_rule({\n");
    if (rule.contains(QStringLiteral("match"))) {
        const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
        windowRulesStr += QStringLiteral("    match = {\n");
        for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
            if (it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath")) continue;
            if (it.value().typeId() == QMetaType::Bool) {
                windowRulesStr += QStringLiteral("        %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
            } else {
                windowRulesStr += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), escapeLuaString(it.value().toString()));
            }
        }
        windowRulesStr += QStringLiteral("    },\n");
    }

    static const QMap<QString, QString> keyMap = {
        { QStringLiteral("noblur"), QStringLiteral("no_blur") },
        { QStringLiteral("no_blur"), QStringLiteral("no_blur") },
        { QStringLiteral("noshadow"), QStringLiteral("no_shadow") },
        { QStringLiteral("no_shadow"), QStringLiteral("no_shadow") },
        { QStringLiteral("nodim"), QStringLiteral("no_dim") },
        { QStringLiteral("no_dim"), QStringLiteral("no_dim") },
        { QStringLiteral("focusonactivate"), QStringLiteral("focus_on_activate") },
        { QStringLiteral("focus_on_activate"), QStringLiteral("focus_on_activate") },
        { QStringLiteral("keepaspectratio"), QStringLiteral("keep_aspect_ratio") },
        { QStringLiteral("keep_aspect_ratio"), QStringLiteral("keep_aspect_ratio") },
        { QStringLiteral("noinitialfocus"), QStringLiteral("no_initial_focus") },
        { QStringLiteral("no_initial_focus"), QStringLiteral("no_initial_focus") },
    };

    for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
        if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath") || it.key() == QStringLiteral("call") || it.key() == QStringLiteral("args")) continue;

        const QString k = keyMap.value(it.key(), it.key());
        if (it.value().typeId() == QMetaType::Bool) {
            if (it.value().toBool()) {
                windowRulesStr += QStringLiteral("    %1 = true,\n").arg(k);
            }
        } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
            windowRulesStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toString());
        } else if (!it.value().toString().trimmed().isEmpty()) {
            windowRulesStr += QStringLiteral("    %1 = \"%2\",\n").arg(k, escapeLuaString(it.value().toString()));
        }
    }
    windowRulesStr += QStringLiteral("})");
    return windowRulesStr;
}

void FlightDeckWriter::applyWindowRuleOverIPC(const QVariantMap& rule) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    socket->evalLua(formatWindowRuleLua(rule));
}

static QString formatLayerRuleLua(const QVariantMap& rule) {
    QString str = QStringLiteral("hl.layer_rule({\n");

    QVariantMap match;
    if (rule.contains(QStringLiteral("match"))) {
        match = rule.value(QStringLiteral("match")).toMap();
    }
    if (rule.contains(QStringLiteral("namespace")) && !match.contains(QStringLiteral("namespace"))) {
        const QString ns = rule.value(QStringLiteral("namespace")).toString().trimmed();
        if (!ns.isEmpty()) {
            match[QStringLiteral("namespace")] = ns;
        }
    }
    if (rule.contains(QStringLiteral("address")) && !match.contains(QStringLiteral("address"))) {
        const QString addr = rule.value(QStringLiteral("address")).toString().trimmed();
        if (!addr.isEmpty()) {
            match[QStringLiteral("address")] = addr;
        }
    }

    if (!match.isEmpty()) {
        str += QStringLiteral("    match = {\n");
        for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
            if (it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath")) continue;
            str += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), escapeLuaString(it.value().toString()));
        }
        str += QStringLiteral("    },\n");
    }

    static const QMap<QString, QString> keyMap = {
        { QStringLiteral("noanim"), QStringLiteral("no_anim") },
        { QStringLiteral("no_anim"), QStringLiteral("no_anim") },
        { QStringLiteral("dimaround"), QStringLiteral("dim_around") },
        { QStringLiteral("dim_around"), QStringLiteral("dim_around") },
        { QStringLiteral("ignorealpha"), QStringLiteral("ignore_alpha") },
        { QStringLiteral("ignore_alpha"), QStringLiteral("ignore_alpha") },
        { QStringLiteral("blurpopups"), QStringLiteral("blur_popups") },
        { QStringLiteral("blur_popups"), QStringLiteral("blur_popups") },
        { QStringLiteral("noblur"), QStringLiteral("no_blur") },
        { QStringLiteral("no_blur"), QStringLiteral("no_blur") },
        { QStringLiteral("blur"), QStringLiteral("blur") },
        { QStringLiteral("xray"), QStringLiteral("xray") },
        { QStringLiteral("animation"), QStringLiteral("animation") }
    };

    for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
        if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("namespace") || it.key() == QStringLiteral("address") ||
            it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath") ||
            it.key() == QStringLiteral("call") || it.key() == QStringLiteral("args")) {
            continue;
        }

        const QString k = keyMap.value(it.key(), it.key());
        if (it.value().typeId() == QMetaType::Bool) {
            if (it.value().toBool()) {
                str += QStringLiteral("    %1 = true,\n").arg(k);
            }
        } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
            str += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toString());
        } else if (!it.value().toString().trimmed().isEmpty()) {
            str += QStringLiteral("    %1 = \"%2\",\n").arg(k, escapeLuaString(it.value().toString()));
        }
    }
    str += QStringLiteral("})");
    return str;
}

void FlightDeckWriter::applyLayerRuleOverIPC(const QVariantMap& rule) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    socket->evalLua(formatLayerRuleLua(rule));
}

void FlightDeckWriter::applyWorkspaceRuleOverIPC(const QVariantMap& rule) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    QString ruleStr = QStringLiteral("hl.workspace_rule({\n");
    for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
        if (it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath")) continue;
        if (it.value().typeId() == QMetaType::Bool) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
        } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toString());
        } else {
            ruleStr += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), it.value().toString());
        }
    }
    ruleStr += QStringLiteral("})");

    socket->evalLua(ruleStr);
}

static QString formatCustomBindLua(const QVariantMap& bind) {
    const QString key = bind.value(QStringLiteral("key")).toString().trimmed();
    const QString dsp = bind.value(QStringLiteral("dispatcher")).toString().trimmed();
    const QString args = bind.value(QStringLiteral("args")).toString().trimmed();
    const QVariantMap flags = bind.value(QStringLiteral("flags")).toMap();
    const QString flagsStr = formatLuaBindFlags(flags);

    QString lua;
    if (dsp == QStringLiteral("exec") || dsp == QStringLiteral("exec_cmd")) {
        lua = QStringLiteral("hl.bind(\"%1\", hl.dsp.exec_cmd(\"%2\")%3)").arg(escapeLuaString(key), escapeLuaString(args), flagsStr);
    } else if (dsp == QStringLiteral("global")) {
        lua = QStringLiteral("hl.bind(\"%1\", hl.dsp.global(\"%2\")%3)").arg(escapeLuaString(key), escapeLuaString(args), flagsStr);
    } else if (args.isEmpty()) {
        lua = QStringLiteral("hl.bind(\"%1\", hl.dsp.%2()%3)").arg(escapeLuaString(key), dsp, flagsStr);
    } else {
        lua = QStringLiteral("hl.bind(\"%1\", hl.dsp.%2(\"%3\")%4)").arg(escapeLuaString(key), dsp, escapeLuaString(args), flagsStr);
    }
    return lua;
}

void FlightDeckWriter::applyCustomBindOverIPC(const QVariantMap& bind) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    const QString key = bind.value(QStringLiteral("key")).toString().trimmed();
    if (key.isEmpty()) return;

    if (socket->isLuaMode()) {
        if (bind.value(QStringLiteral("unbindFirst"), true).toBool()) {
            socket->evalLua(QStringLiteral("hl.unbind(\"%1\")").arg(escapeLuaString(key)));
        }
        socket->evalLua(formatCustomBindLua(bind));
    } else {
        if (bind.value(QStringLiteral("unbindFirst"), true).toBool()) {
            socket->send(QStringLiteral("keyword unbind %1").arg(key));
        }
        const QString dsp = bind.value(QStringLiteral("dispatcher")).toString().trimmed();
        const QString args = bind.value(QStringLiteral("args")).toString().trimmed();
        QString argPart = args.isEmpty() ? QString() : QStringLiteral(", %1").arg(args);
        socket->send(QStringLiteral("keyword bind %1, %2%3").arg(key, dsp, argPart));
    }
}

void FlightDeckWriter::unbindCustomBindOverIPC(const QString& key) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    const QString trimmedKey = key.trimmed();
    if (trimmedKey.isEmpty()) return;

    if (socket->isLuaMode()) {
        socket->evalLua(QStringLiteral("hl.unbind(\"%1\")").arg(escapeLuaString(trimmedKey)));
    } else {
        socket->send(QStringLiteral("keyword unbind %1").arg(trimmedKey));
    }
}

void FlightDeckWriter::addWorkspaceRule(const QVariantMap& rule) {
    QVariantMap r = rule;
    r[QStringLiteral("isReadOnly")] = false;
    r[QStringLiteral("source")] = QStringLiteral("flightdeck");
    m_workspaceRules.append(r);
    m_isDirty = true;
    applyWorkspaceRuleOverIPC(r);
    emit workspaceRulesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeWorkspaceRule(int index) {
    if (index >= 0 && index < m_workspaceRules.size()) {
        if (m_workspaceRules[index].toMap().value(QStringLiteral("isReadOnly")).toBool()) {
            return;
        }
        m_workspaceRules.removeAt(index);
        m_isDirty = true;
        emit workspaceRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateWorkspaceRule(int index, const QVariantMap& rule) {
    if (index >= 0 && index < m_workspaceRules.size()) {
        QVariantMap r = rule;
        r[QStringLiteral("isReadOnly")] = false;
        r[QStringLiteral("source")] = QStringLiteral("flightdeck");
        m_workspaceRules[index] = r;
        m_isDirty = true;
        applyWorkspaceRuleOverIPC(r);
        emit workspaceRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList FlightDeckWriter::activeHyprlandWorkspaceRules() const {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return {};
    QJsonDocument doc = socket->queryJson(QStringLiteral("workspacerules"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return {};
}

QVariantList FlightDeckWriter::activeHyprlandWorkspaces() const {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return {};
    QJsonDocument doc = socket->queryJson(QStringLiteral("workspaces"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return {};
}

void FlightDeckWriter::addWindowRule(const QVariantMap& rule) {
    QVariantMap r = rule;
    r[QStringLiteral("isReadOnly")] = false;
    r[QStringLiteral("source")] = QStringLiteral("flightdeck");
    m_windowRules.append(r);
    m_isDirty = true;
    applyWindowRuleOverIPC(r);
    emit windowRulesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeWindowRule(int index) {
    if (index >= 0 && index < m_windowRules.size()) {
        if (m_windowRules[index].toMap().value(QStringLiteral("isReadOnly")).toBool()) {
            return;
        }
        m_windowRules.removeAt(index);
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateWindowRule(int index, const QVariantMap& rule) {
    if (index >= 0 && index < m_windowRules.size()) {
        QVariantMap r = rule;
        r[QStringLiteral("isReadOnly")] = false;
        r[QStringLiteral("source")] = QStringLiteral("flightdeck");
        m_windowRules[index] = r;
        m_isDirty = true;
        applyWindowRuleOverIPC(r);
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addLayerRule(const QVariantMap& rule) {
    QVariantMap r = rule;
    r[QStringLiteral("isReadOnly")] = false;
    r[QStringLiteral("source")] = QStringLiteral("flightdeck");
    m_layerRules.append(r);
    m_isDirty = true;
    applyLayerRuleOverIPC(r);
    emit layerRulesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeLayerRule(int index) {
    if (index >= 0 && index < m_layerRules.size()) {
        if (m_layerRules[index].toMap().value(QStringLiteral("isReadOnly")).toBool()) {
            return;
        }
        m_layerRules.removeAt(index);
        m_isDirty = true;
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateLayerRule(int index, const QVariantMap& rule) {
    if (index >= 0 && index < m_layerRules.size()) {
        QVariantMap r = rule;
        r[QStringLiteral("isReadOnly")] = false;
        r[QStringLiteral("source")] = QStringLiteral("flightdeck");
        m_layerRules[index] = r;
        m_isDirty = true;
        applyLayerRuleOverIPC(r);
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addAutostart(const QString& cmd, bool onReload) {
    for (const auto& item : m_autostartEntries) {
        if (item.toMap().value(QStringLiteral("command")).toString() == cmd) {
            return;
        }
    }
    QVariantMap entry;
    entry[QStringLiteral("command")] = cmd;
    entry[QStringLiteral("onReload")] = onReload;
    entry[QStringLiteral("isReadOnly")] = false;
    entry[QStringLiteral("source")] = QStringLiteral("flightdeck");
    m_autostartEntries.append(entry);
    m_autostartCommands.append(cmd);
    m_isDirty = true;
    emit autostartChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeAutostart(int index) {
    if (index >= 0 && index < m_autostartEntries.size()) {
        if (m_autostartEntries[index].toMap().value(QStringLiteral("isReadOnly")).toBool()) {
            return;
        }
        m_autostartEntries.removeAt(index);
        m_autostartCommands.removeAt(index);
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateAutostart(int index, const QString& cmd, bool onReload) {
    if (index >= 0 && index < m_autostartEntries.size()) {
        if (m_autostartEntries[index].toMap().value(QStringLiteral("isReadOnly")).toBool()) {
            return;
        }
        QVariantMap entry;
        entry[QStringLiteral("command")] = cmd;
        entry[QStringLiteral("onReload")] = onReload;
        entry[QStringLiteral("isReadOnly")] = false;
        entry[QStringLiteral("source")] = QStringLiteral("flightdeck");
        m_autostartEntries[index] = entry;
        m_autostartCommands[index] = cmd;
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst) {
    addCustomBind(key, dispatcher, args, isUnbindFirst, QVariantMap());
}

void FlightDeckWriter::addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst, const QVariantMap& flags) {
    QVariantMap bindMap{
        { QStringLiteral("key"), key },
        { QStringLiteral("dispatcher"), dispatcher },
        { QStringLiteral("args"), args },
        { QStringLiteral("unbindFirst"), isUnbindFirst },
        { QStringLiteral("flags"), flags }
    };
    m_customBinds.append(bindMap);
    m_isDirty = true;
    applyCustomBindOverIPC(bindMap);
    emit customBindsChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeCustomBind(int index) {
    if (index >= 0 && index < m_customBinds.size()) {
        const QString key = m_customBinds[index].toMap().value(QStringLiteral("key")).toString();
        unbindCustomBindOverIPC(key);
        m_customBinds.removeAt(index);
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateCustomBind(int index, const QVariantMap& bindMap) {
    if (index >= 0 && index < m_customBinds.size()) {
        const QString oldKey = m_customBinds[index].toMap().value(QStringLiteral("key")).toString();
        const QString newKey = bindMap.value(QStringLiteral("key")).toString();
        if (!oldKey.isEmpty() && oldKey != newKey) {
            unbindCustomBindOverIPC(oldKey);
        }
        m_customBinds[index] = bindMap;
        m_isDirty = true;
        applyCustomBindOverIPC(bindMap);
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::setMonitorConfig(const QVariantMap& mon) {
    QString output = mon.value(QStringLiteral("output")).toString();
    if (output.isEmpty()) {
        output = mon.value(QStringLiteral("name")).toString();
    }
    if (output.isEmpty()) return;

    QVariantMap updated = mon;
    updated[QStringLiteral("output")] = output;

    int foundIndex = -1;
    for (int i = 0; i < m_monitors.size(); ++i) {
        if (m_monitors[i].toMap().value(QStringLiteral("output")).toString() == output) {
            foundIndex = i;
            break;
        }
    }

    if (foundIndex >= 0) {
        m_monitors[foundIndex] = updated;
    } else {
        m_monitors.append(updated);
    }

    m_isDirty = true;
    emit monitorsChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::setMonitorConfig(const QString& output, const QString& mode, const QString& position, qreal scale, int transform, bool disabled) {
    QVariantMap mon;
    mon[QStringLiteral("output")] = output;
    mon[QStringLiteral("mode")] = mode;
    mon[QStringLiteral("position")] = position;
    mon[QStringLiteral("scale")] = scale;
    mon[QStringLiteral("transform")] = transform;
    mon[QStringLiteral("disabled")] = disabled;
    setMonitorConfig(mon);
}

static QString escapeLuaString(const QString& str) {
    QString res;
    res.reserve(str.size() + 16);
    for (int i = 0; i < str.size(); ++i) {
        QChar c = str.at(i);
        if (c == QLatin1Char('\\')) {
            res += QStringLiteral("\\\\");
        } else if (c == QLatin1Char('"')) {
            res += QStringLiteral("\\\"");
        } else if (c == QLatin1Char('\n')) {
            res += QStringLiteral("\\n");
        } else if (c == QLatin1Char('\r')) {
            res += QStringLiteral("\\r");
        } else if (c == QLatin1Char('\t')) {
            res += QStringLiteral("\\t");
        } else {
            res += c;
        }
    }
    return res;
}

static QString unescapeLuaString(const QString& str) {
    QString res;
    res.reserve(str.size());
    for (int i = 0; i < str.size(); ++i) {
        QChar c = str.at(i);
        if (c == QLatin1Char('\\') && i + 1 < str.size()) {
            QChar n = str.at(i + 1);
            ++i;
            if (n == QLatin1Char('\\')) {
                res += QLatin1Char('\\');
            } else if (n == QLatin1Char('"')) {
                res += QLatin1Char('"');
            } else if (n == QLatin1Char('n')) {
                res += QLatin1Char('\n');
            } else if (n == QLatin1Char('r')) {
                res += QLatin1Char('\r');
            } else if (n == QLatin1Char('t')) {
                res += QLatin1Char('\t');
            } else {
                res += QLatin1Char('\\');
                res += n;
            }
        } else {
            res += c;
        }
    }
    return res;
}

static QVariantMap parseLuaTable(const QString& tableStr) {
    QVariantMap result;
    QVariantMap matchMap;

    static const QRegularExpression matchBlockRe(QStringLiteral(R"(match\s*=\s*\{([^}]+)\})"));
    auto matchMatch = matchBlockRe.match(tableStr);
    if (matchMatch.hasMatch()) {
        const QString matchContent = matchMatch.captured(1);
        static const QRegularExpression kvRe(QStringLiteral(R"(([a-zA-Z0-9_]+)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([a-zA-Z0-9_\.\-]+)))"));
        auto it = kvRe.globalMatch(matchContent);
        while (it.hasNext()) {
            auto m = it.next();
            QString k = m.captured(1).trimmed();
            QString v = !m.captured(2).isNull() ? m.captured(2) : (!m.captured(3).isNull() ? m.captured(3) : m.captured(4));
            matchMap[k] = unescapeLuaString(v);
        }
        result[QStringLiteral("match")] = matchMap;
    }

    QString topLevel = tableStr;
    topLevel.remove(matchBlockRe);

    static const QRegularExpression topKvRe(QStringLiteral(R"(([a-zA-Z0-9_]+)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([a-zA-Z0-9_\.\-]+)))"));
    auto topIt = topKvRe.globalMatch(topLevel);
    while (topIt.hasNext()) {
        auto m = topIt.next();
        QString k = m.captured(1).trimmed();
        if (k == QStringLiteral("match")) continue;

        QString strVal = !m.captured(2).isNull() ? m.captured(2) : (!m.captured(3).isNull() ? m.captured(3) : m.captured(4).trimmed());
        if (strVal == QStringLiteral("true")) {
            result[k] = true;
        } else if (strVal == QStringLiteral("false")) {
            result[k] = false;
        } else {
            bool ok = false;
            double d = strVal.toDouble(&ok);
            if (ok) {
                result[k] = d;
            } else {
                result[k] = unescapeLuaString(strVal);
            }
        }
    }

    if (result.contains(QStringLiteral("noblur"))) {
        result[QStringLiteral("no_blur")] = result.value(QStringLiteral("noblur"));
    }

    return result;
}

static QVariantList parseWindowRulesFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression ruleRe(QStringLiteral(R"(hl\.window_rule\s*\(\s*\{([\s\S]*?)\}\s*\))"));
    auto it = ruleRe.globalMatch(content);
    while (it.hasNext()) {
        QString body = it.next().captured(1);
        QVariantMap r = parseLuaTable(body);
        if (!r.isEmpty()) {
            list.append(r);
        }
    }
    return list;
}

static QVariantList parseLayerRulesFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression ruleRe(QStringLiteral(R"(hl\.layer_rule\s*\(\s*\{([\s\S]*?)\}\s*\))"));
    auto it = ruleRe.globalMatch(content);
    while (it.hasNext()) {
        QString body = it.next().captured(1);
        QVariantMap r = parseLuaTable(body);
        if (!r.isEmpty()) {
            if (!r.contains(QStringLiteral("namespace")) && r.contains(QStringLiteral("match"))) {
                QVariantMap m = r.value(QStringLiteral("match")).toMap();
                if (m.contains(QStringLiteral("namespace"))) {
                    r[QStringLiteral("namespace")] = m.value(QStringLiteral("namespace")).toString();
                }
            }
            list.append(r);
        }
    }
    return list;
}

static QVariantList parseWorkspaceRulesFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression ruleRe(QStringLiteral(R"(hl\.(?:workspace_rule|workspace)\s*\(\s*\{([\s\S]*?)\}\s*\))"));
    auto it = ruleRe.globalMatch(content);
    while (it.hasNext()) {
        QString body = it.next().captured(1);
        QVariantMap r = parseLuaTable(body);
        if (!r.isEmpty()) {
            list.append(r);
        }
    }
    return list;
}

static QVariantList parseCustomBindsFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression bindRe(QStringLiteral(R"RAW(hl\.bind\s*\(\s*["']([^"']+)["']\s*,\s*(?:hl\.dsp\.)?([a-zA-Z0-9_]+)\s*(?:\(\s*(?:["']((?:\\.|[^"\\])*)["'])?\s*\))?\s*(?:,\s*\{([^}]*)\})?\s*\))RAW"));
    auto it = bindRe.globalMatch(content);
    while (it.hasNext()) {
        auto m = it.next();
        QString key = unescapeLuaString(m.captured(1).trimmed());
        QString dsp = m.captured(2).trimmed();
        QString args = unescapeLuaString(m.captured(3).trimmed());
        QString flagsRaw = m.captured(4).trimmed();

        if (dsp == QStringLiteral("exec_cmd")) {
            dsp = QStringLiteral("exec");
        }

        QVariantMap flags;
        if (!flagsRaw.isEmpty()) {
            static const QRegularExpression flagPairRe(QStringLiteral(R"RAW(([a-zA-Z0-9_]+)\s*=\s*(true|false|"[^"]*"|'[^']*'|\d+))RAW"));
            auto fit = flagPairRe.globalMatch(flagsRaw);
            while (fit.hasNext()) {
                auto fm = fit.next();
                QString fKey = fm.captured(1).trimmed();
                QString fVal = fm.captured(2).trimmed();
                if (fVal == QStringLiteral("true")) {
                    flags[fKey] = true;
                } else if (fVal == QStringLiteral("false")) {
                    flags[fKey] = false;
                } else if (fVal.startsWith(QLatin1Char('"')) || fVal.startsWith(QLatin1Char('\''))) {
                    flags[fKey] = unescapeLuaString(fVal.mid(1, fVal.size() - 2));
                } else {
                    bool ok = false;
                    int num = fVal.toInt(&ok);
                    if (ok) flags[fKey] = num;
                    else flags[fKey] = fVal;
                }
            }
        }

        QVariantMap b{
            { QStringLiteral("key"), key },
            { QStringLiteral("dispatcher"), dsp },
            { QStringLiteral("args"), args },
            { QStringLiteral("unbindFirst"), true },
            { QStringLiteral("flags"), flags }
        };
        list.append(b);
    }
    return list;
}

static QVariantList parseAutostartEntriesFromContent(const QString& content) {
    QVariantList list;
    QSet<QString> seen;

    static const QRegularExpression startBlockRe(QStringLiteral(R"RAW(hl\.on\s*\(\s*["']hyprland\.start["']\s*,\s*function\s*\(\s*\)([\s\S]*?)end\s*\))RAW"));
    static const QRegularExpression execRe(QStringLiteral(R"RAW(hl\.exec_cmd\s*\(\s*["']((?:\\.|[^"\\])*)["']\s*\))RAW"));

    auto startBlockIt = startBlockRe.globalMatch(content);
    while (startBlockIt.hasNext()) {
        QString blockBody = startBlockIt.next().captured(1);
        auto execIt = execRe.globalMatch(blockBody);
        while (execIt.hasNext()) {
            QString cmd = unescapeLuaString(execIt.next().captured(1).trimmed());
            if (!cmd.isEmpty() && !seen.contains(cmd)) {
                seen.insert(cmd);
                QVariantMap entry;
                entry[QStringLiteral("command")] = cmd;
                entry[QStringLiteral("onReload")] = false;
                list.append(entry);
            }
        }
    }

    QString remaining = content;
    remaining.remove(startBlockRe);

    auto remainingIt = execRe.globalMatch(remaining);
    while (remainingIt.hasNext()) {
        QString cmd = unescapeLuaString(remainingIt.next().captured(1).trimmed());
        if (!cmd.isEmpty() && !seen.contains(cmd)) {
            seen.insert(cmd);
            QVariantMap entry;
            entry[QStringLiteral("command")] = cmd;
            entry[QStringLiteral("onReload")] = true;
            list.append(entry);
        }
    }

    return list;
}

static void extractOptionsFromJsonTree(const QJsonObject& obj, const QString& prefix, QVariantMap& outOptions) {
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    for (auto it = obj.constBegin(); it != obj.constEnd(); ++it) {
        QString key = it.key();
        if (it.value().isObject()) {
            QString newPrefix = prefix.isEmpty() ? key : (prefix + QLatin1Char(':') + key);
            extractOptionsFromJsonTree(it.value().toObject(), newPrefix, outOptions);
        } else {
            QString fullKey = prefix.isEmpty() ? key : (prefix + QLatin1Char(':') + key);
            QString canonKey = schema ? schema->toHyprKey(fullKey) : fullKey;
            if (!schema || !schema->hasOption(canonKey)) {
                QString dashed = fullKey;
                dashed.replace(QLatin1Char('_'), QLatin1Char('-'));
                if (schema && schema->hasOption(dashed)) {
                    canonKey = dashed;
                }
            }
            if (it.value().isBool()) {
                outOptions[canonKey] = it.value().toBool();
            } else if (it.value().isDouble()) {
                double d = it.value().toDouble();
                if (d == std::floor(d)) {
                    outOptions[canonKey] = static_cast<qint64>(d);
                } else {
                    outOptions[canonKey] = d;
                }
            } else if (it.value().isString()) {
                QString str = it.value().toString();
                if (str == QStringLiteral("true")) outOptions[canonKey] = true;
                else if (str == QStringLiteral("false")) outOptions[canonKey] = false;
                else outOptions[canonKey] = str;
            }
        }
    }
}

static void parseNestedLuaTable(const QString& tableBody, const QString& prefix, QVariantMap& outOptions) {
    int i = 0;
    int n = tableBody.length();
    while (i < n) {
        while (i < n && (tableBody[i].isSpace() || tableBody[i] == QLatin1Char(','))) i++;
        if (i >= n) break;
        if (tableBody.mid(i, 2) == QStringLiteral("--")) {
            while (i < n && tableBody[i] != QLatin1Char('\n')) i++;
            continue;
        }

        QString key;
        if (tableBody[i] == QLatin1Char('[') || tableBody[i] == QLatin1Char('"') || tableBody[i] == QLatin1Char('\'')) {
            bool bracket = (tableBody[i] == QLatin1Char('['));
            i++;
            while (i < n && (tableBody[i].isSpace() || tableBody[i] == QLatin1Char('"') || tableBody[i] == QLatin1Char('\''))) i++;
            int keyStart = i;
            while (i < n && tableBody[i] != QLatin1Char('"') && tableBody[i] != QLatin1Char('\'') && (!bracket || tableBody[i] != QLatin1Char(']'))) i++;
            key = tableBody.mid(keyStart, i - keyStart).trimmed();
            while (i < n && tableBody[i] != QLatin1Char('=')) i++;
        } else {
            int keyStart = i;
            while (i < n && (tableBody[i].isLetterOrNumber() || tableBody[i] == QLatin1Char('_') || tableBody[i] == QLatin1Char('.') || tableBody[i] == QLatin1Char('-') || tableBody[i] == QLatin1Char(':'))) i++;
            key = tableBody.mid(keyStart, i - keyStart).trimmed();
        }

        if (key.isEmpty()) { i++; continue; }

        while (i < n && (tableBody[i].isSpace() || tableBody[i] == QLatin1Char('='))) i++;
        if (i >= n) break;

        if (tableBody[i] == QLatin1Char('{')) {
            int braceDepth = 1;
            int blockStart = i + 1;
            i++;
            while (i < n && braceDepth > 0) {
                if (tableBody[i] == QLatin1Char('{')) braceDepth++;
                else if (tableBody[i] == QLatin1Char('}')) braceDepth--;
                if (braceDepth > 0) i++;
            }
            QString subBody = tableBody.mid(blockStart, i - blockStart);
            i++;
            QString newPrefix = prefix.isEmpty() ? key : (prefix + QLatin1Char(':') + key);
            parseNestedLuaTable(subBody, newPrefix, outOptions);
        } else {
            int valStart = i;
            while (i < n && tableBody[i] != QLatin1Char(',') && tableBody[i] != QLatin1Char('\n') && tableBody[i] != QLatin1Char('}')) i++;
            QString valStr = tableBody.mid(valStart, i - valStart).trimmed();
            int commentIdx = valStr.indexOf(QStringLiteral("--"));
            if (commentIdx != -1) {
                valStr = valStr.left(commentIdx).trimmed();
            }

            QString fullKey = prefix.isEmpty() ? key : (prefix + QLatin1Char(':') + key);

            QString canonKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(fullKey);
            if (!FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(canonKey)) {
                QString dashed = fullKey;
                dashed.replace(QLatin1Char('_'), QLatin1Char('-'));
                if (FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(dashed)) {
                    canonKey = dashed;
                }
            }

            if (!canonKey.contains(QLatin1Char(':'))) {
                continue;
            }

            if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
                outOptions[canonKey] = unescapeLuaString(valStr.mid(1, valStr.length() - 2));
            } else if (valStr == QStringLiteral("true")) {
                outOptions[canonKey] = true;
            } else if (valStr == QStringLiteral("false")) {
                outOptions[canonKey] = false;
            } else {
                bool ok = false;
                double d = valStr.toDouble(&ok);
                if (ok) {
                    if (valStr.contains(QLatin1Char('.'))) outOptions[canonKey] = d;
                    else outOptions[canonKey] = valStr.toInt();
                } else {
                    outOptions[canonKey] = valStr;
                }
            }
        }
    }
}

static const char* LUA_TREE_LOADER_SCRIPT = R"RAW(
local records = {}
local current_source = ""
local config_root_dir = ""
local current_event = nil

local function escape_string(s)
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"):gsub("\b", "\\b"):gsub("\f", "\\f")
    s = s:gsub("[%c]", function(c) return string.format("\\u%04x", string.byte(c)) end)
    return '"' .. s .. '"'
end

local encode
encode = function(v)
    local t = type(v)
    if t == "nil" then return "null"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null"
        elseif v == math.floor(v) and math.abs(v) < 1e15 then return tostring(math.floor(v)) end
        return tostring(v)
    elseif t == "string" then return escape_string(v)
    elseif t == "table" then
        local n = #v
        local is_dict = false
        local count = 0
        for k, _ in pairs(v) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then
                is_dict = true; break
            end
        end
        if not is_dict and count ~= n then is_dict = true end
        if is_dict then
            local parts = {}
            local keys = {}
            for k in pairs(v) do keys[#keys+1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do
                parts[#parts+1] = escape_string(tostring(k)) .. ":" .. encode(v[k])
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
        local parts = {}
        for i = 1, n do parts[i] = encode(v[i]) end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    return "null"
end

local function record(call, ...)
    records[#records+1] = { call = call, args = {...}, source = current_source }
end

hl = {}
hl.config = function(t) record("config", t) end
hl.env = function(name, value) record("env", name, value) end
hl.monitor = function(t) record("monitor", t) end
hl.curve = function(name, t) record("curve", name, t) end
hl.animation = function(t) record("animation", t) end
hl.window_rule = function(t) record("window_rule", t) end
hl.layer_rule = function(t) record("layer_rule", t) end
hl.workspace_rule = function(t) record("workspace_rule", t) end
hl.workspace = function(t) record("workspace_rule", t) end
hl.gesture = function(t) record("gesture", t) end
hl.permission = function(...) record("permission", ...) end
hl.device = function(t) record("device", t) end
hl.bind = function(keys, dispatcher, flags) record("bind", keys, dispatcher, flags) end
hl.unbind = function(keys) record("unbind", keys) end
hl.plugin = { load = function(path) record("plugin_load", path) end }
local _plugin_sink = {}
setmetatable(_plugin_sink, { __index = function() return _plugin_sink end, __newindex = function() end, __call = function() return _plugin_sink end })
setmetatable(hl.plugin, { __index = function() return _plugin_sink end })
hl.define_submap = function(name, reset_or_fn, fn)
    local body = fn or reset_or_fn
    if type(body) == "function" then pcall(body) end
end
hl.on = function(event, callback)
    if type(callback) == "function" then
        local prev = current_event
        current_event = event
        pcall(callback)
        current_event = prev
    end
end
hl.exec_cmd = function(cmd, rules) record("exec_cmd", cmd, current_event) end
hl.dispatch = function(d) record("dispatch_immediate", d) end
hl.timer = function() end
hl.version = function() return "0.0.0" end
hl.print = function() end
setmetatable(hl, {__index = function() return function() end end})

local function make_dispatcher_factory(qualified_name)
    return function(...)
        return { __dsp = qualified_name, args = {...} }
    end
end
local function make_dsp_namespace(prefix)
    return setmetatable({}, {
        __index = function(_, name) return make_dispatcher_factory(prefix .. "." .. name) end,
        __call = function(_, ...) return make_dispatcher_factory(prefix)(...) end,
    })
end
hl.dsp = setmetatable({
    cursor = make_dsp_namespace("cursor"),
    group = make_dsp_namespace("group"),
    window = make_dsp_namespace("window"),
    workspace = make_dsp_namespace("workspace"),
}, {
    __index = function(_, name) return make_dispatcher_factory(name) end,
})

local _real_loadfile = loadfile
function dofile(path)
    local prev = current_source
    current_source = path
    local f, err = _real_loadfile(path)
    if f then
        local ok, res = pcall(f)
        current_source = prev
        return res
    end
    current_source = prev
end

local _real_require = require
function require(modname)
    if config_root_dir ~= "" then
        local rel = config_root_dir .. modname:gsub("%.", "/")
        for _, candidate in ipairs({ rel .. ".lua", rel .. "/init.lua" }) do
            local f = _real_loadfile(candidate)
            if f then
                local prev = current_source
                current_source = candidate
                local ok, res = pcall(f)
                current_source = prev
                if ok then return res end
            end
        end
    end
    local ok, res = pcall(_real_require, modname)
    if ok then return res end
    return nil
end

local user_file = arg[1]
if not user_file then os.exit(2) end
current_source = user_file
config_root_dir = user_file:match("(.*/)") or ""
local entry = _real_loadfile(user_file)
if entry then pcall(entry) end
for _, r in ipairs(records) do print(encode(r)) end
)RAW";

void FlightDeckWriter::loadFromFile() {
    m_monitors.clear();
    m_windowRules.clear();
    m_layerRules.clear();
    m_workspaceRules.clear();
    m_customBinds.clear();
    m_autostartCommands.clear();
    m_autostartEntries.clear();
    m_hyprOptions.clear();
    m_bezierCurves.clear();
    m_animationTargets.clear();

    const QString managedFilePath = flightDeckFilePath();
    const QString canonicalManagedPath = QFileInfo(managedFilePath).canonicalFilePath();

    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    const QString luaEntrypoint = base + QStringLiteral("/hypr/hyprland.lua");
    const QString confEntrypoint = base + QStringLiteral("/hypr/hyprland.conf");

    bool dynamicLoadSuccess = false;

    // 1. If hyprland.lua exists, run dynamic Lua tree loader
    if (QFile::exists(luaEntrypoint)) {
        QProcess proc;
        proc.start(QStringLiteral("lua"), QStringList() << QStringLiteral("-") << luaEntrypoint);
        proc.write(LUA_TREE_LOADER_SCRIPT);
        proc.closeWriteChannel();

        if (proc.waitForFinished(5000) && proc.exitCode() == 0) {
            const QByteArray stdoutBytes = proc.readAllStandardOutput();
            const QList<QByteArray> lines = stdoutBytes.split('\n');

            for (const QByteArray& line : lines) {
                if (line.trimmed().isEmpty()) continue;

                QJsonParseError parseErr;
                QJsonDocument doc = QJsonDocument::fromJson(line, &parseErr);
                if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) continue;

                QJsonObject obj = doc.object();
                QString call = obj.value(QStringLiteral("call")).toString();
                QJsonArray args = obj.value(QStringLiteral("args")).toArray();
                QString sourcePath = obj.value(QStringLiteral("source")).toString();

                QString canonSource = QFileInfo(sourcePath).canonicalFilePath();
                if (canonSource.isEmpty()) canonSource = sourcePath;

                bool isManaged = (!canonicalManagedPath.isEmpty() && canonSource == canonicalManagedPath)
                              || canonSource == managedFilePath
                              || canonSource.contains(QStringLiteral("astra-flightdeck"))
                              || canonSource.contains(QStringLiteral("flightdeck"));

                if (call == QLatin1String("window_rule") && !args.isEmpty()) {
                    QVariantMap r = args[0].toObject().toVariantMap();
                    r[QStringLiteral("isReadOnly")] = !isManaged;
                    r[QStringLiteral("source")] = isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system");
                    r[QStringLiteral("sourcePath")] = sourcePath;

                    bool exists = false;
                    for (const auto& existing : m_windowRules) {
                        if (existing.toMap() == r) { exists = true; break; }
                    }
                    if (!exists) m_windowRules.append(r);
                } else if (call == QLatin1String("layer_rule") && !args.isEmpty()) {
                    QVariantMap r = args[0].toObject().toVariantMap();
                    r[QStringLiteral("isReadOnly")] = !isManaged;
                    r[QStringLiteral("source")] = isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system");
                    r[QStringLiteral("sourcePath")] = sourcePath;
                    if (!r.contains(QStringLiteral("namespace")) && r.contains(QStringLiteral("match"))) {
                        QVariantMap m = r.value(QStringLiteral("match")).toMap();
                        if (m.contains(QStringLiteral("namespace"))) {
                            r[QStringLiteral("namespace")] = m.value(QStringLiteral("namespace")).toString();
                        }
                    }
                    bool exists = false;
                    for (const auto& existing : m_layerRules) {
                        if (existing.toMap() == r) { exists = true; break; }
                    }
                    if (!exists) m_layerRules.append(r);
                } else if (call == QLatin1String("workspace_rule") && !args.isEmpty()) {
                    QVariantMap r = args[0].toObject().toVariantMap();
                    r[QStringLiteral("isReadOnly")] = !isManaged;
                    r[QStringLiteral("source")] = isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system");
                    r[QStringLiteral("sourcePath")] = sourcePath;

                    bool exists = false;
                    for (const auto& existing : m_workspaceRules) {
                        if (existing.toMap() == r) { exists = true; break; }
                    }
                    if (!exists) m_workspaceRules.append(r);
                } else if (call == QLatin1String("exec_cmd") && !args.isEmpty()) {
                    QString cmd = args[0].toString();
                    if (!cmd.isEmpty()) {
                        QString ev = args.size() > 1 ? args[1].toString() : QString();
                        QVariantMap entry;
                        entry[QStringLiteral("command")] = cmd;
                        entry[QStringLiteral("onReload")] = (ev != QLatin1String("hyprland.start"));
                        entry[QStringLiteral("isReadOnly")] = !isManaged;
                        entry[QStringLiteral("source")] = isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system");
                        entry[QStringLiteral("sourcePath")] = sourcePath;

                        if (!m_autostartCommands.contains(cmd)) {
                            m_autostartEntries.append(entry);
                            m_autostartCommands.append(cmd);
                        }
                    }
                } else if (call == QLatin1String("monitor") && !args.isEmpty()) {
                    QVariantMap m = args[0].toObject().toVariantMap();
                    if (!m.isEmpty()) {
                        if (isManaged) {
                            m_monitors.append(m);
                        }
                    }
                } else if (call == QLatin1String("bind") && args.size() >= 2) {
                    QString key = args[0].toString();
                    QJsonObject dspObj = args[1].toObject();
                    QString dsp = dspObj.value(QStringLiteral("__dsp")).toString();
                    QJsonArray dspArgs = dspObj.value(QStringLiteral("args")).toArray();
                    QString argStr = dspArgs.isEmpty() ? QString() : dspArgs[0].toString();
                    if (dsp == QLatin1String("exec_cmd")) dsp = QStringLiteral("exec");

                    QVariantMap flagsMap;
                    if (args.size() >= 3 && args[2].isObject()) {
                        flagsMap = args[2].toObject().toVariantMap();
                    }

                    QVariantMap b{
                        { QStringLiteral("key"), key },
                        { QStringLiteral("dispatcher"), dsp },
                        { QStringLiteral("args"), argStr },
                        { QStringLiteral("unbindFirst"), true },
                        { QStringLiteral("flags"), flagsMap },
                        { QStringLiteral("isReadOnly"), !isManaged },
                        { QStringLiteral("source"), isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system") }
                    };
                    if (isManaged) {
                        m_customBinds.append(b);
                    }
                } else if (call == QLatin1String("config") && !args.isEmpty()) {
                    if (isManaged && args[0].isObject()) {
                        extractOptionsFromJsonTree(args[0].toObject(), QString(), m_hyprOptions);
                    }
                } else if (call == QLatin1String("curve") && args.size() >= 2) {
                    QString name = args[0].toString();
                    QJsonObject curveObj = args[1].toObject();
                    QJsonArray pointsArr = curveObj.value(QStringLiteral("points")).toArray();
                    qreal x1 = 0.25, y1 = 0.1, x2 = 0.25, y2 = 1.0;
                    if (pointsArr.size() >= 2) {
                        QJsonArray p1 = pointsArr[0].toArray();
                        QJsonArray p2 = pointsArr[1].toArray();
                        if (p1.size() >= 2) { x1 = p1[0].toDouble(); y1 = p1[1].toDouble(); }
                        if (p2.size() >= 2) { x2 = p2[0].toDouble(); y2 = p2[1].toDouble(); }
                    }
                    QVariantMap curveMap{
                        { QStringLiteral("name"), name },
                        { QStringLiteral("x1"), x1 },
                        { QStringLiteral("y1"), y1 },
                        { QStringLiteral("x2"), x2 },
                        { QStringLiteral("y2"), y2 },
                        { QStringLiteral("isReadOnly"), !isManaged },
                        { QStringLiteral("source"), isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system") },
                        { QStringLiteral("sourcePath"), sourcePath }
                    };
                    bool exists = false;
                    for (int i = 0; i < m_bezierCurves.size(); ++i) {
                        if (m_bezierCurves[i].toMap().value(QStringLiteral("name")).toString() == name) {
                            m_bezierCurves[i] = curveMap;
                            exists = true;
                            break;
                        }
                    }
                    if (!exists) {
                        m_bezierCurves.append(curveMap);
                    }
                } else if (call == QLatin1String("animation") && !args.isEmpty()) {
                    QJsonObject animObj = args[0].toObject();
                    QString leaf = animObj.value(QStringLiteral("leaf")).toString();
                    if (leaf.isEmpty()) leaf = animObj.value(QStringLiteral("name")).toString();
                    bool enabled = animObj.value(QStringLiteral("enabled")).toBool(true);
                    qreal speed = animObj.contains(QStringLiteral("speed")) ? animObj.value(QStringLiteral("speed")).toDouble(5.0) : animObj.value(QStringLiteral("duration")).toDouble(5.0);
                    QString bezier = animObj.value(QStringLiteral("bezier")).toString();
                    if (bezier.isEmpty()) bezier = animObj.value(QStringLiteral("curve")).toString();
                    QString style = animObj.value(QStringLiteral("style")).toString();

                    QVariantMap animMap{
                        { QStringLiteral("target"), leaf },
                        { QStringLiteral("name"), leaf },
                        { QStringLiteral("enabled"), enabled },
                        { QStringLiteral("speed"), speed },
                        { QStringLiteral("duration"), speed },
                        { QStringLiteral("curve"), bezier },
                        { QStringLiteral("bezier"), bezier },
                        { QStringLiteral("style"), style },
                        { QStringLiteral("isReadOnly"), !isManaged },
                        { QStringLiteral("source"), isManaged ? QStringLiteral("flightdeck") : QStringLiteral("system") },
                        { QStringLiteral("sourcePath"), sourcePath }
                    };
                    bool exists = false;
                    for (int i = 0; i < m_animationTargets.size(); ++i) {
                        QVariantMap existing = m_animationTargets[i].toMap();
                        QString t = existing.value(QStringLiteral("target")).toString();
                        if (t.isEmpty()) t = existing.value(QStringLiteral("name")).toString();
                        if (t == leaf) {
                            m_animationTargets[i] = animMap;
                            exists = true;
                            break;
                        }
                    }
                    if (!exists) {
                        m_animationTargets.append(animMap);
                    }
                }
            }

            dynamicLoadSuccess = true;
        }
    }

    // 2. Load flightdeck managed file explicitly to populate options and user configurations
    QFile file(managedFilePath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(file.readAll());
        file.close();

        // Parse hl.config({ ... }) options
        int searchIdx = 0;
        while ((searchIdx = content.indexOf(QStringLiteral("hl.config"), searchIdx)) != -1) {
            int openBrace = content.indexOf(QLatin1Char('{'), searchIdx);
            if (openBrace == -1) break;

            int braceDepth = 1;
            int i = openBrace + 1;
            int len = content.length();
            while (i < len && braceDepth > 0) {
                if (content[i] == QLatin1Char('{')) braceDepth++;
                else if (content[i] == QLatin1Char('}')) braceDepth--;
                if (braceDepth > 0) i++;
            }

            if (braceDepth == 0) {
                QString cfgBody = content.mid(openBrace + 1, i - (openBrace + 1));
                parseNestedLuaTable(cfgBody, QString(), m_hyprOptions);
                searchIdx = i + 1;
            } else {
                searchIdx = openBrace + 1;
            }
        }

        // If dynamic loader didn't run, load monitors/rules/autostart/binds from managed file as fallback
        if (!dynamicLoadSuccess) {
            QRegularExpression monRe(QStringLiteral(R"(hl\.monitor\(\{([^}]+)\}\))"));
            QRegularExpressionMatchIterator monIt = monRe.globalMatch(content);
            while (monIt.hasNext()) {
                QString body = monIt.next().captured(1);
                QVariantMap mon;
                QRegularExpression kvRe(QStringLiteral(R"(([a-zA-Z0-9_]+)\s*=\s*([^,\n]+))"));
                QRegularExpressionMatchIterator kvIt = kvRe.globalMatch(body);
                while (kvIt.hasNext()) {
                    QRegularExpressionMatch kv = kvIt.next();
                    QString k = kv.captured(1).trimmed();
                    QString v = kv.captured(2).trimmed();
                    if (v.startsWith(QLatin1Char('"')) && v.endsWith(QLatin1Char('"'))) {
                        mon[k] = unescapeLuaString(v.mid(1, v.length() - 2));
                    } else if (v == QStringLiteral("true")) {
                        mon[k] = true;
                    } else if (v == QStringLiteral("false")) {
                        mon[k] = false;
                    } else {
                        mon[k] = v.toDouble();
                    }
                }
                if (!mon.isEmpty()) m_monitors.append(mon);
            }

            for (const auto& rItem : parseWindowRulesFromContent(content)) {
                QVariantMap r = rItem.toMap();
                r[QStringLiteral("isReadOnly")] = false;
                r[QStringLiteral("source")] = QStringLiteral("flightdeck");
                m_windowRules.append(r);
            }

            for (const auto& rItem : parseLayerRulesFromContent(content)) {
                QVariantMap r = rItem.toMap();
                r[QStringLiteral("isReadOnly")] = false;
                r[QStringLiteral("source")] = QStringLiteral("flightdeck");
                m_layerRules.append(r);
            }

            for (const auto& rItem : parseWorkspaceRulesFromContent(content)) {
                QVariantMap r = rItem.toMap();
                r[QStringLiteral("isReadOnly")] = false;
                r[QStringLiteral("source")] = QStringLiteral("flightdeck");
                m_workspaceRules.append(r);
            }

            for (const auto& entryItem : parseAutostartEntriesFromContent(content)) {
                QVariantMap entry = entryItem.toMap();
                entry[QStringLiteral("isReadOnly")] = false;
                entry[QStringLiteral("source")] = QStringLiteral("flightdeck");
                const QString cmd = entry.value(QStringLiteral("command")).toString();
                if (!m_autostartCommands.contains(cmd)) {
                    m_autostartEntries.append(entry);
                    m_autostartCommands.append(cmd);
                }
            }

            for (const auto& b : parseCustomBindsFromContent(content)) {
                m_customBinds.append(b);
            }

            QRegularExpression curveRe(QStringLiteral(R"(hl\.curve\(\s*["']([^"']+)["']\s*,\s*\{[^}]*points\s*=\s*\{\s*\{\s*([0-9\.\-]+)\s*,\s*([0-9\.\-]+)\s*\}\s*,\s*\{\s*([0-9\.\-]+)\s*,\s*([0-9\.\-]+)\s*\}\s*\}\s*\}\s*\))"));
            QRegularExpressionMatchIterator curveIt = curveRe.globalMatch(content);
            while (curveIt.hasNext()) {
                QRegularExpressionMatch m = curveIt.next();
                m_bezierCurves.append(QVariantMap{
                    { QStringLiteral("name"), m.captured(1) },
                    { QStringLiteral("x1"), m.captured(2).toDouble() },
                    { QStringLiteral("y1"), m.captured(3).toDouble() },
                    { QStringLiteral("x2"), m.captured(4).toDouble() },
                    { QStringLiteral("y2"), m.captured(5).toDouble() },
                    { QStringLiteral("isReadOnly"), false },
                    { QStringLiteral("source"), QStringLiteral("flightdeck") }
                });
            }

            QRegularExpression animRe(QStringLiteral(R"(hl\.animation\(\s*\{([^}]+)\}\s*\))"));
            QRegularExpressionMatchIterator animIt = animRe.globalMatch(content);
            while (animIt.hasNext()) {
                QString body = animIt.next().captured(1);
                QVariantMap anim;
                anim[QStringLiteral("isReadOnly")] = false;
                anim[QStringLiteral("source")] = QStringLiteral("flightdeck");
                QRegularExpression kvRe(QStringLiteral(R"(([a-zA-Z0-9_]+)\s*=\s*([^,\n]+))"));
                QRegularExpressionMatchIterator kvIt = kvRe.globalMatch(body);
                while (kvIt.hasNext()) {
                    QRegularExpressionMatch kv = kvIt.next();
                    QString k = kv.captured(1).trimmed();
                    QString v = kv.captured(2).trimmed();
                    if (v.startsWith(QLatin1Char('"')) && v.endsWith(QLatin1Char('"'))) {
                        anim[k] = unescapeLuaString(v.mid(1, v.length() - 2));
                    } else if (v == QStringLiteral("true")) {
                        anim[k] = true;
                    } else if (v == QStringLiteral("false")) {
                        anim[k] = false;
                    } else {
                        anim[k] = v.toDouble();
                    }
                }
                QString leaf = anim.value(QStringLiteral("leaf")).toString();
                if (leaf.isEmpty()) leaf = anim.value(QStringLiteral("name")).toString();
                if (!leaf.isEmpty()) {
                    anim[QStringLiteral("target")] = leaf;
                    anim[QStringLiteral("name")] = leaf;
                    if (!anim.contains(QStringLiteral("duration")) && anim.contains(QStringLiteral("speed"))) {
                        anim[QStringLiteral("duration")] = anim.value(QStringLiteral("speed"));
                    }
                    if (!anim.contains(QStringLiteral("curve")) && anim.contains(QStringLiteral("bezier"))) {
                        anim[QStringLiteral("curve")] = anim.value(QStringLiteral("bezier"));
                    }
                    m_animationTargets.append(anim);
                }
            }
        }
    }

    m_isDirty = false;
    emit monitorsChanged();
    emit windowRulesChanged();
    emit layerRulesChanged();
    emit workspaceRulesChanged();
    emit customBindsChanged();
    emit autostartChanged();
    emit pluginsChanged();
    emit hyprOptionsChanged();
    emit bezierCurvesChanged();
    emit animationTargetsChanged();
    emit dirtyChanged();
}

static QString formatLuaBindFlags(const QVariantMap& flags) {
    if (flags.isEmpty()) return QString();

    QStringList parts;
    QStringList keys = flags.keys();
    keys.sort();

    for (const QString& key : keys) {
        const QVariant val = flags.value(key);
        if (key == QStringLiteral("description")) {
            const QString desc = val.toString().trimmed();
            if (!desc.isEmpty()) {
                parts.append(QStringLiteral("description = \"%1\"").arg(escapeLuaString(desc)));
            }
        } else if (key == QStringLiteral("device")) {
            if (val.typeId() == QMetaType::QVariantMap) {
                const QVariantMap devMap = val.toMap();
                QStringList devParts;
                if (devMap.contains(QStringLiteral("inclusive"))) {
                    devParts.append(QStringLiteral("inclusive = %1").arg(devMap.value(QStringLiteral("inclusive")).toBool() ? QStringLiteral("true") : QStringLiteral("false")));
                }
                if (devMap.contains(QStringLiteral("list"))) {
                    const QStringList devList = devMap.value(QStringLiteral("list")).toStringList();
                    QStringList escapedList;
                    for (const auto& d : devList) {
                        escapedList.append(QStringLiteral("\"%1\"").arg(escapeLuaString(d)));
                    }
                    devParts.append(QStringLiteral("list = { %1 }").arg(escapedList.join(QStringLiteral(", "))));
                }
                parts.append(QStringLiteral("device = { %1 }").arg(devParts.join(QStringLiteral(", "))));
            } else if (!val.toString().isEmpty()) {
                parts.append(QStringLiteral("device = \"%1\"").arg(escapeLuaString(val.toString())));
            }
        } else if (val.typeId() == QMetaType::Bool) {
            if (val.toBool()) {
                parts.append(QStringLiteral("%1 = true").arg(key));
            }
        } else if (val.typeId() == QMetaType::Int || val.typeId() == QMetaType::LongLong) {
            parts.append(QStringLiteral("%1 = %2").arg(key).arg(val.toLongLong()));
        } else if (!val.toString().isEmpty()) {
            parts.append(QStringLiteral("%1 = \"%2\"").arg(key, escapeLuaString(val.toString())));
        }
    }

    if (parts.isEmpty()) return QString();
    return QStringLiteral(", { %1 }").arg(parts.join(QStringLiteral(", ")));
}

QString FlightDeckWriter::formatLua() const {
    QString out;
    out += QStringLiteral("-- Generated by FlightDeck\n\n");

    // Hyprland Config Options
    if (!m_hyprOptions.isEmpty()) {
        QString hyprConfig = FlightDeck::Hyprland::HyprlandSchema::instance()->serializeToLuaConfig(m_hyprOptions);
        if (!hyprConfig.isEmpty()) {
            out += QStringLiteral("-- Hyprland Configuration Options\n");
            out += hyprConfig;
            out += QStringLiteral("\n");
        }
    }

    // Monitors
    if (!m_monitors.isEmpty()) {
        out += QStringLiteral("-- Monitors\n");
        for (const auto& item : m_monitors) {
            const QVariantMap mon = item.toMap();
            QString output = mon.value(QStringLiteral("output")).toString();
            if (mon.value(QStringLiteral("identify_by_description")).toBool() || mon.value(QStringLiteral("identifyByDescription")).toBool()) {
                QString desc = mon.value(QStringLiteral("description")).toString();
                if (!desc.isEmpty()) {
                    QString prefix = desc.split(QLatin1Char(',')).first().trimmed();
                    if (!prefix.isEmpty()) {
                        output = QStringLiteral("desc:") + prefix;
                    }
                }
            }

            out += QStringLiteral("hl.monitor({\n");
            out += QStringLiteral("    output = \"%1\",\n").arg(escapeLuaString(output));
            out += QStringLiteral("    disabled = %1,\n").arg(mon.value(QStringLiteral("disabled")).toBool() ? QStringLiteral("true") : QStringLiteral("false"));
            if (!mon.value(QStringLiteral("disabled")).toBool()) {
                if (mon.contains(QStringLiteral("mode")) && !mon.value(QStringLiteral("mode")).toString().isEmpty()) {
                    out += QStringLiteral("    mode = \"%1\",\n").arg(escapeLuaString(mon.value(QStringLiteral("mode")).toString()));
                }
                if (mon.contains(QStringLiteral("position")) && !mon.value(QStringLiteral("position")).toString().isEmpty()) {
                    out += QStringLiteral("    position = \"%1\",\n").arg(escapeLuaString(mon.value(QStringLiteral("position")).toString()));
                }
                if (mon.contains(QStringLiteral("scale"))) {
                    out += QStringLiteral("    scale = %1,\n").arg(mon.value(QStringLiteral("scale")).toDouble());
                }
                if (mon.contains(QStringLiteral("transform")) && mon.value(QStringLiteral("transform")).toInt() > 0) {
                    out += QStringLiteral("    transform = %1,\n").arg(mon.value(QStringLiteral("transform")).toInt());
                }
                if (mon.contains(QStringLiteral("bitdepth")) && !mon.value(QStringLiteral("bitdepth")).isNull()) {
                    out += QStringLiteral("    bitdepth = %1,\n").arg(mon.value(QStringLiteral("bitdepth")).toInt());
                }
                if (mon.contains(QStringLiteral("vrr")) && !mon.value(QStringLiteral("vrr")).isNull()) {
                    out += QStringLiteral("    vrr = %1,\n").arg(mon.value(QStringLiteral("vrr")).toInt());
                }
                if (mon.contains(QStringLiteral("cm")) && !mon.value(QStringLiteral("cm")).toString().isEmpty()) {
                    out += QStringLiteral("    cm = \"%1\",\n").arg(escapeLuaString(mon.value(QStringLiteral("cm")).toString()));
                }
                if (mon.contains(QStringLiteral("sdrbrightness")) && !mon.value(QStringLiteral("sdrbrightness")).isNull()) {
                    out += QStringLiteral("    sdrbrightness = %1,\n").arg(mon.value(QStringLiteral("sdrbrightness")).toDouble());
                }
                if (mon.contains(QStringLiteral("sdrsaturation")) && !mon.value(QStringLiteral("sdrsaturation")).isNull()) {
                    out += QStringLiteral("    sdrsaturation = %1,\n").arg(mon.value(QStringLiteral("sdrsaturation")).toDouble());
                }
                if (mon.contains(QStringLiteral("sdr_min_luminance")) && !mon.value(QStringLiteral("sdr_min_luminance")).isNull()) {
                    out += QStringLiteral("    sdr_min_luminance = %1,\n").arg(mon.value(QStringLiteral("sdr_min_luminance")).toDouble());
                }
                if (mon.contains(QStringLiteral("sdr_max_luminance")) && !mon.value(QStringLiteral("sdr_max_luminance")).isNull()) {
                    out += QStringLiteral("    sdr_max_luminance = %1,\n").arg(mon.value(QStringLiteral("sdr_max_luminance")).toDouble());
                }
                if (mon.contains(QStringLiteral("min_luminance")) && !mon.value(QStringLiteral("min_luminance")).isNull()) {
                    out += QStringLiteral("    min_luminance = %1,\n").arg(mon.value(QStringLiteral("min_luminance")).toDouble());
                }
                if (mon.contains(QStringLiteral("max_luminance")) && !mon.value(QStringLiteral("max_luminance")).isNull()) {
                    out += QStringLiteral("    max_luminance = %1,\n").arg(mon.value(QStringLiteral("max_luminance")).toDouble());
                }
                if (mon.contains(QStringLiteral("max_avg_luminance")) && !mon.value(QStringLiteral("max_avg_luminance")).isNull()) {
                    out += QStringLiteral("    max_avg_luminance = %1,\n").arg(mon.value(QStringLiteral("max_avg_luminance")).toDouble());
                }
                if (mon.contains(QStringLiteral("mirror")) && !mon.value(QStringLiteral("mirror")).toString().isEmpty() && mon.value(QStringLiteral("mirror")).toString() != QLatin1String("none")) {
                    out += QStringLiteral("    mirror = \"%1\",\n").arg(escapeLuaString(mon.value(QStringLiteral("mirror")).toString()));
                }
            }
            out += QStringLiteral("})\n");
        }
        out += QStringLiteral("\n");
    }

    // Window Rules (only serialize user-defined rules)
    if (!m_windowRules.isEmpty()) {
        QString windowRulesStr;
        for (const auto& item : m_windowRules) {
            const QVariantMap rule = item.toMap();
            if (rule.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            windowRulesStr += formatWindowRuleLua(rule) + QStringLiteral("\n");
        }
        if (!windowRulesStr.isEmpty()) {
            out += QStringLiteral("-- Window rules\n") + windowRulesStr + QStringLiteral("\n");
        }
    }

    // Layer Rules (only serialize user-defined rules)
    if (!m_layerRules.isEmpty()) {
        QString layerRulesStr;
        for (const auto& item : m_layerRules) {
            const QVariantMap rule = item.toMap();
            if (rule.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            layerRulesStr += formatLayerRuleLua(rule) + QStringLiteral("\n");
        }
        if (!layerRulesStr.isEmpty()) {
            out += QStringLiteral("-- Layer rules\n") + layerRulesStr + QStringLiteral("\n");
        }
    }

    // Workspace Rules (only serialize user-defined rules)
    if (!m_workspaceRules.isEmpty()) {
        QString workspaceRulesStr;
        for (const auto& item : m_workspaceRules) {
            const QVariantMap rule = item.toMap();
            if (rule.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            workspaceRulesStr += QStringLiteral("hl.workspace_rule({\n");
            for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
                if (it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source") || it.key() == QStringLiteral("sourcePath") || it.key() == QStringLiteral("call") || it.key() == QStringLiteral("args")) continue;
                if (it.value().typeId() == QMetaType::Bool) {
                    workspaceRulesStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
                    workspaceRulesStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toString());
                } else {
                    workspaceRulesStr += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), escapeLuaString(it.value().toString()));
                }
            }
            workspaceRulesStr += QStringLiteral("})\n");
        }
        if (!workspaceRulesStr.isEmpty()) {
            out += QStringLiteral("-- Workspace rules\n") + workspaceRulesStr + QStringLiteral("\n");
        }
    }

    // Custom Binds
    if (!m_customBinds.isEmpty()) {
        out += QStringLiteral("-- Custom Keybinds\n");
        for (const auto& item : m_customBinds) {
            const QVariantMap bind = item.toMap();
            const QString key = bind.value(QStringLiteral("key")).toString();
            const QString dsp = bind.value(QStringLiteral("dispatcher")).toString();
            const QString args = bind.value(QStringLiteral("args")).toString();
            const QVariantMap flags = bind.value(QStringLiteral("flags")).toMap();
            const QString flagsStr = formatLuaBindFlags(flags);

            if (bind.value(QStringLiteral("unbindFirst")).toBool()) {
                out += QStringLiteral("hl.unbind(\"%1\")\n").arg(escapeLuaString(key));
            }
            if (dsp == QStringLiteral("exec") || dsp == QStringLiteral("exec_cmd")) {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.exec_cmd(\"%2\")%3)\n").arg(escapeLuaString(key), escapeLuaString(args), flagsStr);
            } else if (dsp == QStringLiteral("global")) {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.global(\"%2\")%3)\n").arg(escapeLuaString(key), escapeLuaString(args), flagsStr);
            } else if (args.isEmpty()) {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2()%3)\n").arg(escapeLuaString(key), dsp, flagsStr);
            } else {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2(\"%3\")%4)\n").arg(escapeLuaString(key), dsp, escapeLuaString(args), flagsStr);
            }
        }
        out += QStringLiteral("\n");
    }

    // Autostart (only serialize user-defined commands, skip read-only system commands)
    if (!m_autostartEntries.isEmpty()) {
        QStringList startupCmds;
        QStringList reloadCmds;
        for (const auto& item : m_autostartEntries) {
            const QVariantMap entry = item.toMap();
            if (entry.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            const QString cmd = entry.value(QStringLiteral("command")).toString();
            if (cmd.isEmpty()) continue;
            if (entry.value(QStringLiteral("onReload")).toBool()) {
                reloadCmds.append(cmd);
            } else {
                startupCmds.append(cmd);
            }
        }

        if (!startupCmds.isEmpty() || !reloadCmds.isEmpty()) {
            out += QStringLiteral("-- Autostart\n");
            if (!startupCmds.isEmpty()) {
                out += QStringLiteral("hl.on(\"hyprland.start\", function()\n");
                for (const QString& cmd : startupCmds) {
                    out += QStringLiteral("    hl.exec_cmd(\"%1\")\n").arg(escapeLuaString(cmd));
                }
                out += QStringLiteral("end)\n\n");
            }

            if (!reloadCmds.isEmpty()) {
                for (const QString& cmd : reloadCmds) {
                    out += QStringLiteral("hl.exec_cmd(\"%1\")\n").arg(escapeLuaString(cmd));
                }
                out += QStringLiteral("\n");
            }
        }
    }

    // Bezier Curves (only serialize user-defined curves)
    if (!m_bezierCurves.isEmpty()) {
        QString curvesStr;
        for (const auto& item : m_bezierCurves) {
            const QVariantMap curve = item.toMap();
            if (curve.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            const QString name = curve.value(QStringLiteral("name")).toString();
            if (name.isEmpty()) continue;
            qreal x1 = curve.value(QStringLiteral("x1")).toDouble();
            qreal y1 = curve.value(QStringLiteral("y1")).toDouble();
            qreal x2 = curve.value(QStringLiteral("x2")).toDouble();
            qreal y2 = curve.value(QStringLiteral("y2")).toDouble();

            curvesStr += QStringLiteral("hl.curve(\"%1\", { type = \"bezier\", points = { { %2, %3 }, { %4, %5 } } })\n")
                .arg(escapeLuaString(name))
                .arg(x1, 0, 'f', 2)
                .arg(y1, 0, 'f', 2)
                .arg(x2, 0, 'f', 2)
                .arg(y2, 0, 'f', 2);
        }
        if (!curvesStr.isEmpty()) {
            out += QStringLiteral("-- Bezier Curves\n") + curvesStr + QStringLiteral("\n");
        }
    }

    // Animation Targets (only serialize user-defined animations)
    if (!m_animationTargets.isEmpty()) {
        QString animStr;
        for (const auto& item : m_animationTargets) {
            const QVariantMap anim = item.toMap();
            if (anim.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            QString leaf = anim.value(QStringLiteral("target")).toString();
            if (leaf.isEmpty()) leaf = anim.value(QStringLiteral("name")).toString();
            if (leaf.isEmpty()) continue;

            bool enabled = anim.value(QStringLiteral("enabled")).toBool();
            qreal speed = anim.contains(QStringLiteral("speed")) ? anim.value(QStringLiteral("speed")).toDouble() : anim.value(QStringLiteral("duration")).toDouble();
            QString bezier = anim.contains(QStringLiteral("bezier")) ? anim.value(QStringLiteral("bezier")).toString() : anim.value(QStringLiteral("curve")).toString();
            QString style = anim.value(QStringLiteral("style")).toString();

            animStr += QStringLiteral("hl.animation({\n");
            animStr += QStringLiteral("    leaf = \"%1\",\n").arg(escapeLuaString(leaf));
            animStr += QStringLiteral("    enabled = %1,\n").arg(enabled ? QStringLiteral("true") : QStringLiteral("false"));
            animStr += QStringLiteral("    speed = %1,\n").arg(speed);
            if (!bezier.isEmpty()) {
                animStr += QStringLiteral("    bezier = \"%1\",\n").arg(escapeLuaString(bezier));
            }
            if (!style.isEmpty()) {
                animStr += QStringLiteral("    style = \"%1\",\n").arg(escapeLuaString(style));
            }
            animStr += QStringLiteral("})\n");
        }
        if (!animStr.isEmpty()) {
            out += QStringLiteral("-- Animation Targets\n") + animStr + QStringLiteral("\n");
        }
    }

    return out;
}

bool FlightDeckWriter::save() {
    const QString path = flightDeckFilePath();
    const QFileInfo fi(path);
    if (!fi.dir().exists()) {
        fi.dir().mkpath(QStringLiteral("."));
    }

    const QString lua = formatLua();
    QString validationError;
    if (!LuaValidator::validate(lua, &validationError)) {
        qWarning() << "Lua validation failed for flightdeck config:" << validationError;
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

    // Instantly apply user-configured window rules and layer rules over IPC
    for (const auto& item : m_windowRules) {
        const QVariantMap r = item.toMap();
        if (!r.value(QStringLiteral("isReadOnly")).toBool()) {
            applyWindowRuleOverIPC(r);
        }
    }
    for (const auto& item : m_layerRules) {
        const QVariantMap r = item.toMap();
        if (!r.value(QStringLiteral("isReadOnly")).toBool()) {
            applyLayerRuleOverIPC(r);
        }
    }
    for (const auto& item : m_customBinds) {
        applyCustomBindOverIPC(item.toMap());
    }

    for (const auto& item : m_bezierCurves) {
        const QVariantMap curve = item.toMap();
        if (!curve.value(QStringLiteral("isReadOnly")).toBool()) {
            const QString name = curve.value(QStringLiteral("name")).toString();
            if (name.isEmpty()) continue;
            qreal x1 = curve.value(QStringLiteral("x1")).toDouble();
            qreal y1 = curve.value(QStringLiteral("y1")).toDouble();
            qreal x2 = curve.value(QStringLiteral("x2")).toDouble();
            qreal y2 = curve.value(QStringLiteral("y2")).toDouble();
            const QString bezierCmd = QStringLiteral("%1, %2, %3, %4, %5").arg(name).arg(x1, 0, 'f', 3).arg(y1, 0, 'f', 3).arg(x2, 0, 'f', 3).arg(y2, 0, 'f', 3);
            Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("bezier"), bezierCmd);
        }
    }
    for (const auto& item : m_animationTargets) {
        const QVariantMap anim = item.toMap();
        if (!anim.value(QStringLiteral("isReadOnly")).toBool()) {
            QString leaf = anim.value(QStringLiteral("target")).toString();
            if (leaf.isEmpty()) leaf = anim.value(QStringLiteral("name")).toString();
            if (leaf.isEmpty()) continue;
            bool enabled = anim.value(QStringLiteral("enabled")).toBool();
            qreal speed = anim.contains(QStringLiteral("speed")) ? anim.value(QStringLiteral("speed")).toDouble() : anim.value(QStringLiteral("duration")).toDouble();
            QString bezier = anim.contains(QStringLiteral("bezier")) ? anim.value(QStringLiteral("bezier")).toString() : anim.value(QStringLiteral("curve")).toString();
            QString style = anim.value(QStringLiteral("style")).toString();
            QString animCmd = QStringLiteral("%1, %2, %3, %4").arg(leaf).arg(enabled ? 1 : 0).arg(speed).arg(bezier.isEmpty() ? QStringLiteral("default") : bezier);
            if (!style.isEmpty()) {
                animCmd += QStringLiteral(", %1").arg(style);
            }
            Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("animation"), animCmd);
        }
    }

    auto socket = Hyprland::HyprlandSocket::instance();
    if (socket && socket->isOnline()) {
        socket->reload();
    }

    m_isDirty = false;
    emit dirtyChanged();
    emit saveSucceeded();
    return true;
}

void FlightDeckWriter::reload() {
    loadFromFile();
}

void FlightDeckWriter::discard() {
    loadFromFile();
}

QVariantList FlightDeckWriter::activeHyprlandClients() const {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("j/clients"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return QVariantList();
}

QVariantList FlightDeckWriter::activeHyprlandWindowRules() const {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("j/windowrules"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return QVariantList();
}

QVariantList FlightDeckWriter::activeHyprlandLayers() const {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("j/layers"));
    QVariantList list;
    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        for (auto it = obj.constBegin(); it != obj.constEnd(); ++it) {
            const QJsonObject monObj = it.value().toObject();
            const QJsonObject levels = monObj.value(QStringLiteral("levels")).toObject();
            for (auto lvlIt = levels.constBegin(); lvlIt != levels.constEnd(); ++lvlIt) {
                const QJsonArray arr = lvlIt.value().toArray();
                for (const auto& item : arr) {
                    const QJsonObject lObj = item.toObject();
                    const QString ns = lObj.value(QStringLiteral("namespace")).toString();
                    if (!ns.isEmpty() && !list.contains(ns)) {
                        list.append(ns);
                    }
                }
            }
        }
    }
    return list;
}

} // namespace FlightDeck::Caelestia
