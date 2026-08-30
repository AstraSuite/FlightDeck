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
    const QString astraFlightDeckPath = QDir::homePath() + QStringLiteral("/.config/caelestia/astra-flightdeck.lua");
    if (QFile::exists(astraFlightDeckPath)) {
        return astraFlightDeckPath;
    }
    const QString astraHelmPath = QDir::homePath() + QStringLiteral("/.config/caelestia/astra-helm.lua");
    if (QFile::exists(astraHelmPath)) {
        return astraHelmPath;
    }
    return astraFlightDeckPath;
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

void FlightDeckWriter::applyWindowRuleOverIPC(const QVariantMap& rule) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    QString ruleStr = QStringLiteral("hl.window_rule({\n");
    if (rule.contains(QStringLiteral("match"))) {
        const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
        ruleStr += QStringLiteral("    match = {\n");
        for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
            if (it.value().typeId() == QMetaType::Bool) {
                ruleStr += QStringLiteral("        %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
            } else {
                ruleStr += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
            }
        }
        ruleStr += QStringLiteral("    },\n");
    }
    for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
        if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source")) continue;
        const QString k = (it.key() == QStringLiteral("noblur")) ? QStringLiteral("no_blur") : it.key();
        if (it.value().typeId() == QMetaType::Bool) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
        } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toString());
        } else {
            ruleStr += QStringLiteral("    %1 = \"%2\",\n").arg(k, it.value().toString());
        }
    }
    ruleStr += QStringLiteral("})");

    socket->evalLua(ruleStr);
}

void FlightDeckWriter::applyLayerRuleOverIPC(const QVariantMap& rule) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    QString ruleStr = QStringLiteral("hl.layer_rule({\n");
    if (rule.contains(QStringLiteral("match"))) {
        const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
        ruleStr += QStringLiteral("    match = {\n");
        for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
            ruleStr += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
        }
        ruleStr += QStringLiteral("    },\n");
    }
    for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
        if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source")) continue;
        const QString k = (it.key() == QStringLiteral("noblur")) ? QStringLiteral("no_blur") : it.key();
        if (it.value().typeId() == QMetaType::Bool) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
        } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
            ruleStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toString());
        } else {
            ruleStr += QStringLiteral("    %1 = \"%2\",\n").arg(k, it.value().toString());
        }
    }
    ruleStr += QStringLiteral("})");

    socket->evalLua(ruleStr);
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

static QVariantList parseCustomBindsFromContent(const QString& content) {
    QVariantList list;
    static const QRegularExpression bindRe(QStringLiteral(R"RAW(hl\.bind\s*\(\s*["']([^"']+)["']\s*,\s*(?:hl\.dsp\.)?([a-zA-Z0-9_]+)\s*\(\s*(?:["']((?:\\.|[^"'\\])*)["'])?\s*\))RAW"));
    auto it = bindRe.globalMatch(content);
    while (it.hasNext()) {
        auto m = it.next();
        QString key = m.captured(1).trimmed();
        QString dsp = m.captured(2).trimmed();
        QString args = m.captured(3).trimmed();
        if (dsp == QStringLiteral("exec_cmd")) {
            dsp = QStringLiteral("exec");
        }
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

static QVariantList parseAutostartEntriesFromContent(const QString& content) {
    QVariantList list;
    QSet<QString> seen;

    // 1. Find hl.on("hyprland.start", function() ... end) blocks (onReload = false)
    static const QRegularExpression startBlockRe(QStringLiteral(R"RAW(hl\.on\s*\(\s*["']hyprland\.start["']\s*,\s*function\s*\(\s*\)([\s\S]*?)end\s*\))RAW"));
    static const QRegularExpression execRe(QStringLiteral(R"RAW(hl\.exec_cmd\s*\(\s*["']((?:\\.|[^"'\\])*)["']\s*\))RAW"));

    auto startBlockIt = startBlockRe.globalMatch(content);
    while (startBlockIt.hasNext()) {
        QString blockBody = startBlockIt.next().captured(1);
        auto execIt = execRe.globalMatch(blockBody);
        while (execIt.hasNext()) {
            QString cmd = execIt.next().captured(1).trimmed();
            if (!cmd.isEmpty() && !seen.contains(cmd)) {
                seen.insert(cmd);
                QVariantMap entry;
                entry[QStringLiteral("command")] = cmd;
                entry[QStringLiteral("onReload")] = false;
                list.append(entry);
            }
        }
    }

    // 2. Remove hyprland.start blocks and parse remaining top-level / reload exec_cmds (onReload = true)
    QString remaining = content;
    remaining.remove(startBlockRe);

    auto remainingIt = execRe.globalMatch(remaining);
    while (remainingIt.hasNext()) {
        QString cmd = remainingIt.next().captured(1).trimmed();
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

static QStringList parseAutostartFromContent(const QString& content) {
    QStringList list;
    for (const auto& item : parseAutostartEntriesFromContent(content)) {
        list.append(item.toMap().value(QStringLiteral("command")).toString());
    }
    return list;
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

        int keyStart = i;
        while (i < n && (tableBody[i].isLetterOrNumber() || tableBody[i] == QLatin1Char('_') || tableBody[i] == QLatin1Char('.'))) i++;
        QString key = tableBody.mid(keyStart, i - keyStart).trimmed();
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
            QString fullKey = prefix.isEmpty() ? key : (prefix + QLatin1Char(':') + key);

            QString canonKey = FlightDeck::Hyprland::HyprlandSchema::instance()->toHyprKey(fullKey);
            if (!FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(canonKey)) {
                QString dashed = fullKey;
                dashed.replace(QLatin1Char('_'), QLatin1Char('-'));
                if (FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(dashed)) {
                    canonKey = dashed;
                }
            }

            if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
                outOptions[canonKey] = valStr.mid(1, valStr.length() - 2);
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

void FlightDeckWriter::loadFromFile() {
    m_monitors.clear();
    m_windowRules.clear();
    m_layerRules.clear();
    m_customBinds.clear();
    m_autostartCommands.clear();
    m_autostartEntries.clear();
    m_hyprOptions.clear();

    const QString path = flightDeckFilePath();
    QFile file(path);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(file.readAll());
        file.close();

        // Parse hl.config({ ... }) options with balanced brace matching
        int searchIdx = 0;
        while ((searchIdx = content.indexOf(QStringLiteral("hl.config"), searchIdx)) != -1) {
            int openBrace = content.indexOf(QLatin1Char('{'), searchIdx);
            if (openBrace == -1) break;

            int braceDepth = 1;
            int i = openBrace + 1;
            int len = content.length();
            while (i < len && braceDepth > 0) {
                if (content[i] == QLatin1Char('{')) {
                    braceDepth++;
                } else if (content[i] == QLatin1Char('}')) {
                    braceDepth--;
                }
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
        for (const auto& rItem : parseWindowRulesFromContent(content)) {
            QVariantMap r = rItem.toMap();
            r[QStringLiteral("isReadOnly")] = false;
            r[QStringLiteral("source")] = QStringLiteral("flightdeck");
            m_windowRules.append(r);
        }

        // Parse layer rules from flightdeck file
        for (const auto& rItem : parseLayerRulesFromContent(content)) {
            QVariantMap r = rItem.toMap();
            r[QStringLiteral("isReadOnly")] = false;
            r[QStringLiteral("source")] = QStringLiteral("flightdeck");
            m_layerRules.append(r);
        }

        // Parse autostart entries from flightdeck file
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

        // Parse custom binds from flightdeck file
        for (const auto& b : parseCustomBindsFromContent(content)) {
            m_customBinds.append(b);
        }
    }

    // Also load existing window rules and layer rules from ~/.config/hypr/hyprland/rules.lua (marked as system/read-only)
    const QString rulesPath = QDir::homePath() + QStringLiteral("/.config/hypr/hyprland/rules.lua");
    QFile rulesFile(rulesPath);
    if (rulesFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString rulesContent = QString::fromUtf8(rulesFile.readAll());
        rulesFile.close();

        const auto existingWindowRules = parseWindowRulesFromContent(rulesContent);
        for (const auto& rItem : existingWindowRules) {
            QVariantMap r = rItem.toMap();
            r[QStringLiteral("isReadOnly")] = true;
            r[QStringLiteral("source")] = QStringLiteral("system");

            bool alreadyCovered = false;
            const QVariantMap rMatch = r.value(QStringLiteral("match")).toMap();
            for (const auto& existing : m_windowRules) {
                const QVariantMap exMap = existing.toMap();
                if (!rMatch.isEmpty() && exMap.value(QStringLiteral("match")).toMap() == rMatch) {
                    alreadyCovered = true;
                    break;
                }
            }
            if (!alreadyCovered) {
                m_windowRules.append(r);
            }
        }

        const auto existingLayerRules = parseLayerRulesFromContent(rulesContent);
        for (const auto& rItem : existingLayerRules) {
            QVariantMap r = rItem.toMap();
            r[QStringLiteral("isReadOnly")] = true;
            r[QStringLiteral("source")] = QStringLiteral("system");

            bool alreadyCovered = false;
            const QString ns = r.value(QStringLiteral("namespace")).toString();
            const QVariantMap rMatch = r.value(QStringLiteral("match")).toMap();
            for (const auto& existing : m_layerRules) {
                const QVariantMap exMap = existing.toMap();
                if (!ns.isEmpty() && exMap.value(QStringLiteral("namespace")).toString() == ns) {
                    alreadyCovered = true;
                    break;
                }
                if (!rMatch.isEmpty() && exMap.value(QStringLiteral("match")).toMap() == rMatch) {
                    alreadyCovered = true;
                    break;
                }
            }
            if (!alreadyCovered) {
                m_layerRules.append(r);
            }
        }
    }

    // Also load existing autostart commands from ~/.config/hypr/hyprland/execs.lua (marked as read-only / system)
    const QString execsPath = QDir::homePath() + QStringLiteral("/.config/hypr/hyprland/execs.lua");
    QFile execsFile(execsPath);
    if (execsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString execsContent = QString::fromUtf8(execsFile.readAll());
        execsFile.close();

        for (const auto& entryItem : parseAutostartEntriesFromContent(execsContent)) {
            QVariantMap entry = entryItem.toMap();
            entry[QStringLiteral("isReadOnly")] = true;
            entry[QStringLiteral("source")] = QStringLiteral("system");
            const QString cmd = entry.value(QStringLiteral("command")).toString();
            if (!m_autostartCommands.contains(cmd)) {
                m_autostartEntries.append(entry);
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
    emit hyprOptionsChanged();
    emit dirtyChanged();
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

    // Window Rules (only serialize user-defined rules)
    if (!m_windowRules.isEmpty()) {
        QString windowRulesStr;
        for (const auto& item : m_windowRules) {
            const QVariantMap rule = item.toMap();
            if (rule.value(QStringLiteral("isReadOnly")).toBool()) {
                continue;
            }
            windowRulesStr += QStringLiteral("hl.window_rule({\n");
            if (rule.contains(QStringLiteral("match"))) {
                const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
                windowRulesStr += QStringLiteral("    match = {\n");
                for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
                    if (it.value().typeId() == QMetaType::Bool) {
                        windowRulesStr += QStringLiteral("        %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                    } else {
                        windowRulesStr += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                    }
                }
                windowRulesStr += QStringLiteral("    },\n");
            }
            for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
                if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source")) continue;
                if (it.key() == QStringLiteral("noblur")) continue; // written as no_blur
                const QString k = (it.key() == QStringLiteral("noblur")) ? QStringLiteral("no_blur") : it.key();
                if (it.value().typeId() == QMetaType::Bool) {
                    windowRulesStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
                    windowRulesStr += QStringLiteral("    %1 = %2,\n").arg(k, it.value().toString());
                } else {
                    windowRulesStr += QStringLiteral("    %1 = \"%2\",\n").arg(k, it.value().toString());
                }
            }
            windowRulesStr += QStringLiteral("})\n");
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
            layerRulesStr += QStringLiteral("hl.layer_rule({\n");
            if (rule.contains(QStringLiteral("match"))) {
                const QVariantMap match = rule.value(QStringLiteral("match")).toMap();
                layerRulesStr += QStringLiteral("    match = {\n");
                for (auto it = match.constBegin(); it != match.constEnd(); ++it) {
                    layerRulesStr += QStringLiteral("        %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
                layerRulesStr += QStringLiteral("    },\n");
            }
            for (auto it = rule.constBegin(); it != rule.constEnd(); ++it) {
                if (it.key() == QStringLiteral("match") || it.key() == QStringLiteral("isReadOnly") || it.key() == QStringLiteral("source")) continue;
                if (it.value().typeId() == QMetaType::Bool) {
                    layerRulesStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else {
                    layerRulesStr += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), it.value().toString());
                }
            }
            layerRulesStr += QStringLiteral("})\n");
        }
        if (!layerRulesStr.isEmpty()) {
            out += QStringLiteral("-- Layer rules\n") + layerRulesStr + QStringLiteral("\n");
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
            if (bind.value(QStringLiteral("unbindFirst")).toBool()) {
                out += QStringLiteral("hl.unbind(\"%1\")\n").arg(key);
            }
            if (dsp == QStringLiteral("exec") || dsp == QStringLiteral("exec_cmd")) {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.exec_cmd(\"%2\"))\n").arg(key, args);
            } else if (args.isEmpty()) {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2())\n").arg(key, dsp);
            } else {
                out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2(\"%3\"))\n").arg(key, dsp, args);
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
                    out += QStringLiteral("    hl.exec_cmd(\"%1\")\n").arg(cmd);
                }
                out += QStringLiteral("end)\n\n");
            }

            if (!reloadCmds.isEmpty()) {
                for (const QString& cmd : reloadCmds) {
                    out += QStringLiteral("hl.exec_cmd(\"%1\")\n").arg(cmd);
                }
                out += QStringLiteral("\n");
            }
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
