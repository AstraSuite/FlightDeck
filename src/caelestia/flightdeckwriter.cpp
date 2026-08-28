#include "flightdeckwriter.hpp"
#include "luavalidator.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include "../hyprland/hyprlandsocket.hpp"

namespace FlightDeck::Caelestia {

FlightDeckWriter* FlightDeckWriter::instance() {
    static FlightDeckWriter inst;
    return &inst;
}

FlightDeckWriter* FlightDeckWriter::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QString FlightDeckWriter::flightDeckFilePath() {
    return QDir::homePath() + QStringLiteral("/.config/caelestia/astra-helm.lua");
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
    return m_autostartCommands;
}

void FlightDeckWriter::setAutostartCommands(const QStringList& cmds) {
    if (m_autostartCommands != cmds) {
        m_autostartCommands = cmds;
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

void FlightDeckWriter::addWindowRule(const QVariantMap& rule) {
    m_windowRules.append(rule);
    m_isDirty = true;
    emit windowRulesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeWindowRule(int index) {
    if (index >= 0 && index < m_windowRules.size()) {
        m_windowRules.removeAt(index);
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateWindowRule(int index, const QVariantMap& rule) {
    if (index >= 0 && index < m_windowRules.size()) {
        m_windowRules[index] = rule;
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addLayerRule(const QVariantMap& rule) {
    m_layerRules.append(rule);
    m_isDirty = true;
    emit layerRulesChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeLayerRule(int index) {
    if (index >= 0 && index < m_layerRules.size()) {
        m_layerRules.removeAt(index);
        m_isDirty = true;
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addAutostart(const QString& cmd) {
    if (!m_autostartCommands.contains(cmd)) {
        m_autostartCommands.append(cmd);
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::removeAutostart(int index) {
    if (index >= 0 && index < m_autostartCommands.size()) {
        m_autostartCommands.removeAt(index);
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateAutostart(int index, const QString& cmd) {
    if (index >= 0 && index < m_autostartCommands.size()) {
        m_autostartCommands[index] = cmd;
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst) {
    QVariantMap bindMap{
        { QStringLiteral("key"), key },
        { QStringLiteral("dispatcher"), dispatcher },
        { QStringLiteral("args"), args },
        { QStringLiteral("unbindFirst"), isUnbindFirst }
    };
    m_customBinds.append(bindMap);
    m_isDirty = true;
    emit customBindsChanged();
    emit dirtyChanged();
}

void FlightDeckWriter::removeCustomBind(int index) {
    if (index >= 0 && index < m_customBinds.size()) {
        m_customBinds.removeAt(index);
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::updateCustomBind(int index, const QVariantMap& bindMap) {
    if (index >= 0 && index < m_customBinds.size()) {
        m_customBinds[index] = bindMap;
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

void FlightDeckWriter::setMonitorConfig(const QString& output, const QString& mode, const QString& position, qreal scale, int transform, bool disabled) {
    int foundIndex = -1;
    for (int i = 0; i < m_monitors.size(); ++i) {
        if (m_monitors[i].toMap().value(QStringLiteral("output")).toString() == output) {
            foundIndex = i;
            break;
        }
    }

    QVariantMap mon{
        { QStringLiteral("output"), output },
        { QStringLiteral("mode"), mode },
        { QStringLiteral("position"), position },
        { QStringLiteral("scale"), scale },
        { QStringLiteral("transform"), transform },
        { QStringLiteral("disabled"), disabled }
    };

    if (foundIndex >= 0) {
        m_monitors[foundIndex] = mon;
    } else {
        m_monitors.append(mon);
    }

    m_isDirty = true;
    emit monitorsChanged();
    emit dirtyChanged();
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
            matchMap[k] = v;
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
                result[k] = strVal;
            }
        }
    }

    if (result.contains(QStringLiteral("no_blur"))) {
        result[QStringLiteral("noblur")] = result.value(QStringLiteral("no_blur"));
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

static QVariantList parseCustomBindsFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression bindRe(QStringLiteral(R"RAW(hl\.bind\s*\(\s*["']([^"']+)["']\s*,\s*(?:hl\.dsp\.)?([a-zA-Z0-9_]+)\s*\(\s*(?:["']((?:\\.|[^"'\\])*)["'])?\s*\))RAW"));
    auto it = bindRe.globalMatch(content);
    while (it.hasNext()) {
        auto m = it.next();
        QString key = m.captured(1).trimmed();
        QString dsp = m.captured(2).trimmed();
        QString args = m.captured(3).trimmed();
        QVariantMap b{
            { QStringLiteral("key"), key },
            { QStringLiteral("dispatcher"), dsp },
            { QStringLiteral("args"), args },
            { QStringLiteral("unbindFirst"), true }
        };
        list.append(b);
    }
    return list;
}

static QStringList parseAutostartFromContent(const QString& content) {
    QStringList list;
    static const QRegularExpression execRe(QStringLiteral(R"RAW(hl\.exec_cmd\s*\(\s*["']((?:\\.|[^"'\\])*)["']\s*\))RAW"));
    auto it = execRe.globalMatch(content);
    while (it.hasNext()) {
        QString cmd = it.next().captured(1).trimmed();
        if (!cmd.isEmpty() && !list.contains(cmd)) {
            list.append(cmd);
        }
    }
    return list;
}

void FlightDeckWriter::loadFromFile() {
    m_monitors.clear();
    m_windowRules.clear();
    m_layerRules.clear();
    m_customBinds.clear();
    m_autostartCommands.clear();

    const QString path = flightDeckFilePath();
    QFile file(path);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(file.readAll());
        file.close();

        // Parse monitors: hl.monitor({ ... })
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
                    mon[k] = v.mid(1, v.length() - 2);
                } else if (v == QStringLiteral("true")) {
                    mon[k] = true;
                } else if (v == QStringLiteral("false")) {
                    mon[k] = false;
                } else {
                    mon[k] = v.toDouble();
                }
            }
            if (!mon.isEmpty()) {
                m_monitors.append(mon);
            }
        }

        // Parse window rules from flightdeck file
        for (const auto& r : parseWindowRulesFromContent(content)) {
            m_windowRules.append(r);
        }

        // Parse layer rules from flightdeck file
        for (const auto& r : parseLayerRulesFromContent(content)) {
            m_layerRules.append(r);
        }

        // Parse autostart commands from flightdeck file
        for (const QString& cmd : parseAutostartFromContent(content)) {
            if (!m_autostartCommands.contains(cmd)) {
                m_autostartCommands.append(cmd);
            }
        }

        // Parse custom binds from flightdeck file
        for (const auto& b : parseCustomBindsFromContent(content)) {
            m_customBinds.append(b);
        }
    }

    // Also load existing window rules and layer rules from ~/.config/hypr/hyprland/rules.lua
    const QString rulesPath = QDir::homePath() + QStringLiteral("/.config/hypr/hyprland/rules.lua");
    QFile rulesFile(rulesPath);
    if (rulesFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString rulesContent = QString::fromUtf8(rulesFile.readAll());
        rulesFile.close();

        const auto existingWindowRules = parseWindowRulesFromContent(rulesContent);
        for (const auto& r : existingWindowRules) {
            if (!m_windowRules.contains(r)) {
                m_windowRules.append(r);
            }
        }

        const auto existingLayerRules = parseLayerRulesFromContent(rulesContent);
        for (const auto& r : existingLayerRules) {
            if (!m_layerRules.contains(r)) {
                m_layerRules.append(r);
            }
        }
    }

    // Also load existing autostart commands from ~/.config/hypr/hyprland/execs.lua
    const QString execsPath = QDir::homePath() + QStringLiteral("/.config/hypr/hyprland/execs.lua");
    QFile execsFile(execsPath);
    if (execsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString execsContent = QString::fromUtf8(execsFile.readAll());
        execsFile.close();

        for (const QString& cmd : parseAutostartFromContent(execsContent)) {
            if (!m_autostartCommands.contains(cmd)) {
                m_autostartCommands.append(cmd);
            }
        }
    }

    m_isDirty = false;
    emit monitorsChanged();
    emit windowRulesChanged();
    emit layerRulesChanged();
    emit customBindsChanged();
    emit autostartChanged();
    emit pluginsChanged();
    emit dirtyChanged();
}

QString FlightDeckWriter::formatLua() const {
    QString out;
    out += QStringLiteral("-- Generated by FlightDeck\n\n");

    // Monitors
    if (!m_monitors.isEmpty()) {
        out += QStringLiteral("-- Monitors\n");
        for (const auto& item : m_monitors) {
            const QVariantMap mon = item.toMap();
            out += QStringLiteral("hl.monitor({\n");
            out += QStringLiteral("    output = \"%1\",\n").arg(mon.value(QStringLiteral("output")).toString());
            out += QStringLiteral("    disabled = %1,\n").arg(mon.value(QStringLiteral("disabled")).toBool() ? QStringLiteral("true") : QStringLiteral("false"));
            if (mon.contains(QStringLiteral("mode"))) {
                out += QStringLiteral("    mode = \"%1\",\n").arg(mon.value(QStringLiteral("mode")).toString());
            }
            if (mon.contains(QStringLiteral("position"))) {
                out += QStringLiteral("    position = \"%1\",\n").arg(mon.value(QStringLiteral("position")).toString());
            }
            if (mon.contains(QStringLiteral("scale"))) {
                out += QStringLiteral("    scale = %1,\n").arg(mon.value(QStringLiteral("scale")).toDouble());
            }
            if (mon.contains(QStringLiteral("transform")) && mon.value(QStringLiteral("transform")).toInt() > 0) {
                out += QStringLiteral("    transform = %1,\n").arg(mon.value(QStringLiteral("transform")).toInt());
            }
            out += QStringLiteral("})\n");
        }
        out += QStringLiteral("\n");
    }

    // Window Rules
    if (!m_windowRules.isEmpty()) {
        out += QStringLiteral("-- Window rules\n");
        for (const auto& item : m_windowRules) {
            const QVariantMap rule = item.toMap();
            out += QStringLiteral("hl.window_rule({\n");
            if (rule.contains(QStringLiteral("match"))) {
                const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
                out += QStringLiteral("    match = {\n");
                for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
                    out += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
                out += QStringLiteral("    },\n");
            }
            for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
                if (it.key() == QStringLiteral("match")) continue;
                if (it.value().typeId() == QMetaType::Bool) {
                    out += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
                    out += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toString());
                } else {
                    out += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
            }
            out += QStringLiteral("})\n");
        }
        out += QStringLiteral("\n");
    }

    // Layer Rules
    if (!m_layerRules.isEmpty()) {
        out += QStringLiteral("-- Layer rules\n");
        for (const auto& item : m_layerRules) {
            const QVariantMap rule = item.toMap();
            out += QStringLiteral("hl.layer_rule({\n");
            if (rule.contains(QStringLiteral("match"))) {
                const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
                out += QStringLiteral("    match = {\n");
                for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
                    out += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
                out += QStringLiteral("    },\n");
            }
            for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
                if (it.key() == QStringLiteral("match")) continue;
                if (it.value().typeId() == QMetaType::Bool) {
                    out += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else {
                    out += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
            }
            out += QStringLiteral("})\n");
        }
        out += QStringLiteral("\n");
    }

    // Custom Binds
    if (!m_customBinds.isEmpty()) {
        out += QStringLiteral("-- Custom Keybinds\n");
        for (const auto& item : m_customBinds) {
            const QVariantMap bind = item.toMap();
            const QString key = bind.value(QStringLiteral("key")).toString();
            const QString dsp = bind.value(QStringLiteral("dispatcher")).toString();
            const QString args = bind.value(QStringLiteral("args")).toString();
            if (bind.value(QStringLiteral("unbindFirst")).toBool()) {
                out += QStringLiteral("hl.unbind(\"%1\")\n").arg(key);
            }
            out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2(\"%3\"))\n").arg(key, dsp, args);
        }
        out += QStringLiteral("\n");
    }

    // Autostart
    if (!m_autostartCommands.isEmpty()) {
        out += QStringLiteral("-- Autostart\n");
        out += QStringLiteral("hl.on(\"hyprland.start\", function()\n");
        for (const QString& cmd : m_autostartCommands) {
            out += QStringLiteral("    hl.exec_cmd(\"%1\")\n").arg(cmd);
        }
        out += QStringLiteral("end)\n\n");
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
