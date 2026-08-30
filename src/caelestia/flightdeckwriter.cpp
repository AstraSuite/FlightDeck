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
    if (m_hyprOptions.value(key) != value) {
        m_hyprOptions[key] = value;
        m_isDirty = true;
        emit hyprOptionsChanged();
        emit dirtyChanged();
    }
}

QVariant FlightDeckWriter::getHyprOption(const QString& key, const QVariant& fallback) const {
    if (m_hyprOptions.contains(key)) {
        return m_hyprOptions.value(key);
    }
    return fallback;
}

bool FlightDeckWriter::hasHyprOption(const QString& key) const {
    return m_hyprOptions.contains(key);
}

void FlightDeckWriter::addWindowRule(const QVariantMap& rule) {
    QVariantMap r = rule;
    r[QStringLiteral("isReadOnly")] = false;
    r[QStringLiteral("source")] = QStringLiteral("flightdeck");
    m_windowRules.append(r);
    m_isDirty = true;
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

        // Parse hl.config({ ... }) options
        static const QRegularExpression configRe(QStringLiteral(R"(hl\.config\s*\(\s*\{([\s\S]*?)\}\s*\))"));
        auto cfgIt = configRe.globalMatch(content);
        while (cfgIt.hasNext()) {
            QString cfgBody = cfgIt.next().captured(1);
            static const QRegularExpression kvRe(QStringLiteral(R"(([a-zA-Z0-9_]+)\s*=\s*([^,\n}]+))"));
            auto it = kvRe.globalMatch(cfgBody);
            while (it.hasNext()) {
                auto m = it.next();
                QString k = m.captured(1).trimmed();
                QString valStr = m.captured(2).trimmed();
                if (valStr.startsWith(QLatin1Char('{'))) continue;
                if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
                    m_hyprOptions[k] = valStr.mid(1, valStr.length() - 2);
                } else if (valStr == QStringLiteral("true")) {
                    m_hyprOptions[k] = true;
                } else if (valStr == QStringLiteral("false")) {
                    m_hyprOptions[k] = false;
                } else {
                    bool ok = false;
                    double d = valStr.toDouble(&ok);
                    if (ok) {
                        if (valStr.contains(QLatin1Char('.'))) m_hyprOptions[k] = d;
                        else m_hyprOptions[k] = valStr.toInt();
                    } else {
                        m_hyprOptions[k] = valStr;
                    }
                }
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
        out += QStringLiteral("-- Hyprland Configuration Options\nhl.config({\n");

        auto writeSection = [&out](const QString& sectionName, const QMap<QString, QVariant>& map, int indentLevel) {
            if (map.isEmpty()) return;
            QString indent(indentLevel * 4, QLatin1Char(' '));
            out += QStringLiteral("%1%2 = {\n").arg(indent, sectionName);
            for (auto it = map.constBegin(); it != map.constEnd(); ++it) {
                QString valStr;
                const QVariant& v = it.value();
                if (v.typeId() == QMetaType::Bool) {
                    valStr = v.toBool() ? QStringLiteral("true") : QStringLiteral("false");
                } else if (v.typeId() == QMetaType::Double || v.typeId() == QMetaType::Float) {
                    valStr = QString::number(v.toDouble(), 'g', 6);
                } else if (v.typeId() == QMetaType::Int || v.typeId() == QMetaType::LongLong) {
                    valStr = QString::number(v.toLongLong());
                } else {
                    valStr = QStringLiteral("\"") + v.toString().replace(QLatin1Char('"'), QLatin1String("\\\"")) + QStringLiteral("\"");
                }
                out += QStringLiteral("%1    %2 = %3,\n").arg(indent, it.key(), valStr);
            }
            out += QStringLiteral("%1},\n").arg(indent);
        };

        QMap<QString, QVariant> generalOpts;
        QMap<QString, QVariant> generalSnapOpts;
        QMap<QString, QVariant> decorOpts;
        QMap<QString, QVariant> decorBlurOpts;
        QMap<QString, QVariant> decorShadowOpts;
        QMap<QString, QVariant> inputOpts;
        QMap<QString, QVariant> inputTouchpadOpts;
        QMap<QString, QVariant> gesturesOpts;
        QMap<QString, QVariant> miscOpts;
        QMap<QString, QVariant> cursorOpts;
        QMap<QString, QVariant> dwindleOpts;
        QMap<QString, QVariant> masterOpts;
        QMap<QString, QVariant> scrollingOpts;
        QMap<QString, QVariant> xwlOpts;
        QMap<QString, QVariant> ecoOpts;

        for (auto it = m_hyprOptions.constBegin(); it != m_hyprOptions.constEnd(); ++it) {
            const QString& k = it.key();
            const QVariant& v = it.value();
            if (k == QStringLiteral("mouseAccelProfile") || k == QStringLiteral("input:accel_profile")) inputOpts[QStringLiteral("accel_profile")] = v;
            else if (k == QStringLiteral("mouseSensitivity") || k == QStringLiteral("input:sensitivity")) inputOpts[QStringLiteral("sensitivity")] = v;
            else if (k == QStringLiteral("mouseNaturalScroll") || k == QStringLiteral("input:natural_scroll")) inputOpts[QStringLiteral("natural_scroll")] = v;
            else if (k == QStringLiteral("mouseScrollFactor") || k == QStringLiteral("input:scroll_factor")) inputOpts[QStringLiteral("scroll_factor")] = v;
            else if (k == QStringLiteral("leftHandedMode") || k == QStringLiteral("input:left_handed")) inputOpts[QStringLiteral("left_handed")] = v;
            else if (k == QStringLiteral("followMouse") || k == QStringLiteral("input:follow_mouse")) inputOpts[QStringLiteral("follow_mouse")] = v;
            else if (k == QStringLiteral("mouseRefocus") || k == QStringLiteral("input:mouse_refocus")) inputOpts[QStringLiteral("mouse_refocus")] = v;
            else if (k == QStringLiteral("floatSwitchOverrideFocus") || k == QStringLiteral("input:float_switch_override_focus")) inputOpts[QStringLiteral("float_switch_override_focus")] = v;
            else if (k == QStringLiteral("kbLayout") || k == QStringLiteral("input:kb_layout")) inputOpts[QStringLiteral("kb_layout")] = v;
            else if (k == QStringLiteral("kbVariant") || k == QStringLiteral("input:kb_variant")) inputOpts[QStringLiteral("kb_variant")] = v;
            else if (k == QStringLiteral("kbOptions") || k == QStringLiteral("input:kb_options")) inputOpts[QStringLiteral("kb_options")] = v;
            else if (k == QStringLiteral("numlockByDefault") || k == QStringLiteral("input:numlock_by_default")) inputOpts[QStringLiteral("numlock_by_default")] = v;
            else if (k == QStringLiteral("keyRepeatRate") || k == QStringLiteral("input:repeat_rate")) inputOpts[QStringLiteral("repeat_rate")] = v;
            else if (k == QStringLiteral("keyRepeatDelay") || k == QStringLiteral("input:repeat_delay")) inputOpts[QStringLiteral("repeat_delay")] = v;
            else if (k == QStringLiteral("touchpadTapToClick") || k == QStringLiteral("input:touchpad:tap-to-click")) inputTouchpadOpts[QStringLiteral("tap_to_click")] = v;
            else if (k == QStringLiteral("touchpadClickfingerBehavior") || k == QStringLiteral("input:touchpad:clickfinger_behavior")) inputTouchpadOpts[QStringLiteral("clickfinger_behavior")] = v;
            else if (k == QStringLiteral("touchpadMiddleButtonEmulation") || k == QStringLiteral("input:touchpad:middle_button_emulation")) inputTouchpadOpts[QStringLiteral("middle_button_emulation")] = v;
            else if (k == QStringLiteral("touchpadDragLock") || k == QStringLiteral("input:touchpad:drag_lock")) inputTouchpadOpts[QStringLiteral("drag_lock")] = v;
            else if (k == QStringLiteral("touchpadTapButtonMap") || k == QStringLiteral("input:touchpad:tap_button_map")) inputTouchpadOpts[QStringLiteral("tap_button_map")] = v;
            else if (k == QStringLiteral("resizeOnBorder") || k == QStringLiteral("general:resize_on_border")) generalOpts[QStringLiteral("resize_on_border")] = v;
            else if (k == QStringLiteral("extendBorderGrabArea") || k == QStringLiteral("general:extend_border_grab_area")) generalOpts[QStringLiteral("extend_border_grab_area")] = v;
            else if (k == QStringLiteral("hoverIconOnBorder") || k == QStringLiteral("general:hover_icon_on_border")) generalOpts[QStringLiteral("hover_icon_on_border")] = v;
            else if (k == QStringLiteral("allowTearing") || k == QStringLiteral("general:allow_tearing")) generalOpts[QStringLiteral("allow_tearing")] = v;
            else if (k == QStringLiteral("layout") || k == QStringLiteral("general:layout")) generalOpts[QStringLiteral("layout")] = v;
            else if (k == QStringLiteral("snapEnabled") || k == QStringLiteral("general:snap:enabled")) generalSnapOpts[QStringLiteral("enabled")] = v;
            else if (k == QStringLiteral("snapWindowGap") || k == QStringLiteral("general:snap:window_gap")) generalSnapOpts[QStringLiteral("window_gap")] = v;
            else if (k == QStringLiteral("snapMonitorGap") || k == QStringLiteral("general:snap:monitor_gap")) generalSnapOpts[QStringLiteral("monitor_gap")] = v;
            else if (k == QStringLiteral("snapBorderOverlap") || k == QStringLiteral("general:snap:border_overlap")) generalSnapOpts[QStringLiteral("border_overlap")] = v;
            else if (k == QStringLiteral("snapRespectGaps") || k == QStringLiteral("general:snap:respect_gaps")) generalSnapOpts[QStringLiteral("respect_gaps")] = v;
            else if (k == QStringLiteral("windowRoundingPower") || k == QStringLiteral("decoration:rounding_power")) decorOpts[QStringLiteral("rounding_power")] = v;
            else if (k == QStringLiteral("activeWindowOpacity") || k == QStringLiteral("decoration:active_opacity")) decorOpts[QStringLiteral("active_opacity")] = v;
            else if (k == QStringLiteral("inactiveWindowOpacity") || k == QStringLiteral("decoration:inactive_opacity")) decorOpts[QStringLiteral("inactive_opacity")] = v;
            else if (k == QStringLiteral("fullscreenWindowOpacity") || k == QStringLiteral("fullscreenOpacity") || k == QStringLiteral("decoration:fullscreen_opacity")) decorOpts[QStringLiteral("fullscreen_opacity")] = v;
            else if (k == QStringLiteral("dimInactive") || k == QStringLiteral("decoration:dim_inactive")) decorOpts[QStringLiteral("dim_inactive")] = v;
            else if (k == QStringLiteral("dimStrength") || k == QStringLiteral("decoration:dim_strength")) decorOpts[QStringLiteral("dim_strength")] = v;
            else if (k == QStringLiteral("dimAround") || k == QStringLiteral("decoration:dim_around")) decorOpts[QStringLiteral("dim_around")] = v;
            else if (k == QStringLiteral("dimSpecial") || k == QStringLiteral("decoration:dim_special")) decorOpts[QStringLiteral("dim_special")] = v;
            else if (k == QStringLiteral("blurIgnoreOpacity") || k == QStringLiteral("decoration:blur:ignore_opacity")) decorBlurOpts[QStringLiteral("ignore_opacity")] = v;
            else if (k == QStringLiteral("blurNoise") || k == QStringLiteral("decoration:blur:noise")) decorBlurOpts[QStringLiteral("noise")] = v;
            else if (k == QStringLiteral("blurContrast") || k == QStringLiteral("decoration:blur:contrast")) decorBlurOpts[QStringLiteral("contrast")] = v;
            else if (k == QStringLiteral("blurBrightness") || k == QStringLiteral("decoration:blur:brightness")) decorBlurOpts[QStringLiteral("brightness")] = v;
            else if (k == QStringLiteral("blurVibrancy") || k == QStringLiteral("decoration:blur:vibrancy")) decorBlurOpts[QStringLiteral("vibrancy")] = v;
            else if (k == QStringLiteral("blurVibrancyDarkness") || k == QStringLiteral("decoration:blur:vibrancy_darkness")) decorBlurOpts[QStringLiteral("vibrancy_darkness")] = v;
            else if (k == QStringLiteral("shadowOffset") || k == QStringLiteral("decoration:shadow:offset")) decorShadowOpts[QStringLiteral("offset")] = v;
            else if (k == QStringLiteral("shadowScale") || k == QStringLiteral("decoration:shadow:scale")) decorShadowOpts[QStringLiteral("scale")] = v;
            else if (k == QStringLiteral("workspaceSwipeCreateNew") || k == QStringLiteral("gestures:workspace_swipe_create_new")) gesturesOpts[QStringLiteral("workspace_swipe_create_new")] = v;
            else if (k == QStringLiteral("workspaceSwipeForever") || k == QStringLiteral("gestures:workspace_swipe_forever")) gesturesOpts[QStringLiteral("workspace_swipe_forever")] = v;
            else if (k == QStringLiteral("workspaceSwipeCancelRatio") || k == QStringLiteral("gestures:workspace_swipe_cancel_ratio")) gesturesOpts[QStringLiteral("workspace_swipe_cancel_ratio")] = v;
            else if (k == QStringLiteral("workspaceSwipeDistance") || k == QStringLiteral("gestures:workspace_swipe_distance")) gesturesOpts[QStringLiteral("workspace_swipe_distance")] = v;
            else if (k == QStringLiteral("workspaceSwipeInvert") || k == QStringLiteral("gestures:workspace_swipe_invert")) gesturesOpts[QStringLiteral("workspace_swipe_invert")] = v;
            else if (k == QStringLiteral("vfr") || k == QStringLiteral("misc:vfr")) miscOpts[QStringLiteral("vfr")] = v;
            else if (k == QStringLiteral("vrr") || k == QStringLiteral("misc:vrr")) miscOpts[QStringLiteral("vrr")] = v;
            else if (k == QStringLiteral("focusOnActivate") || k == QStringLiteral("misc:focus_on_activate")) miscOpts[QStringLiteral("focus_on_activate")] = v;
            else if (k == QStringLiteral("animateManualResizes") || k == QStringLiteral("misc:animate_manual_resizes")) miscOpts[QStringLiteral("animate_manual_resizes")] = v;
            else if (k == QStringLiteral("animateMouseWindowDragging") || k == QStringLiteral("misc:animate_mouse_windowdragging")) miscOpts[QStringLiteral("animate_mouse_windowdragging")] = v;
            else if (k == QStringLiteral("disableHyprlandLogo") || k == QStringLiteral("misc:disable_hyprland_logo")) miscOpts[QStringLiteral("disable_hyprland_logo")] = v;
            else if (k == QStringLiteral("disableSplashRendering") || k == QStringLiteral("misc:disable_splash_rendering")) miscOpts[QStringLiteral("disable_splash_rendering")] = v;
            else if (k == QStringLiteral("forceDefaultWallpaper") || k == QStringLiteral("misc:force_default_wallpaper")) miscOpts[QStringLiteral("force_default_wallpaper")] = v;
            else if (k == QStringLiteral("mouseMoveEnablesDpms") || k == QStringLiteral("misc:mouse_move_enables_dpms")) miscOpts[QStringLiteral("mouse_move_enables_dpms")] = v;
            else if (k == QStringLiteral("keyPressEnablesDpms") || k == QStringLiteral("misc:key_press_enables_dpms")) miscOpts[QStringLiteral("key_press_enables_dpms")] = v;
            else if (k == QStringLiteral("disableAutoreload") || k == QStringLiteral("misc:disable_autoreload")) miscOpts[QStringLiteral("disable_autoreload")] = v;
            else if (k == QStringLiteral("cursorNoHardwareCursors") || k == QStringLiteral("cursor:no_hardware_cursors")) cursorOpts[QStringLiteral("no_hardware_cursors")] = v;
            else if (k == QStringLiteral("cursorEnableHyprcursor") || k == QStringLiteral("cursor:enable_hyprcursor")) cursorOpts[QStringLiteral("enable_hyprcursor")] = v;
            else if (k == QStringLiteral("cursorNoWarps") || k == QStringLiteral("cursor:no_warps")) cursorOpts[QStringLiteral("no_warps")] = v;
            else if (k == QStringLiteral("cursorPersistentWarps") || k == QStringLiteral("cursor:persistent_warps")) cursorOpts[QStringLiteral("persistent_warps")] = v;
            else if (k == QStringLiteral("cursorWarpOnChangeWorkspace") || k == QStringLiteral("cursor:warp_on_change_workspace")) cursorOpts[QStringLiteral("warp_on_change_workspace")] = v;
            else if (k == QStringLiteral("cursorZoomFactor") || k == QStringLiteral("cursor:zoom_factor")) cursorOpts[QStringLiteral("zoom_factor")] = v;
            else if (k == QStringLiteral("cursorInactiveTimeout") || k == QStringLiteral("cursor:inactive_timeout")) cursorOpts[QStringLiteral("inactive_timeout")] = v;
            else if (k == QStringLiteral("cursorHideOnKeyPress") || k == QStringLiteral("cursor:hide_on_key_press")) cursorOpts[QStringLiteral("hide_on_key_press")] = v;
            else if (k == QStringLiteral("cursorHideOnTouch") || k == QStringLiteral("cursor:hide_on_touch")) cursorOpts[QStringLiteral("hide_on_touch")] = v;
            else if (k == QStringLiteral("cursorHideOnTablet") || k == QStringLiteral("cursor:hide_on_tablet")) cursorOpts[QStringLiteral("hide_on_tablet")] = v;
            else if (k == QStringLiteral("dwindlePreserveSplit") || k == QStringLiteral("dwindle:preserve_split")) dwindleOpts[QStringLiteral("preserve_split")] = v;
            else if (k == QStringLiteral("dwindlePseudotile") || k == QStringLiteral("dwindle:pseudotile")) dwindleOpts[QStringLiteral("pseudotile")] = v;
            else if (k == QStringLiteral("dwindleForceSplit") || k == QStringLiteral("dwindle:force_split")) dwindleOpts[QStringLiteral("force_split")] = v;
            else if (k == QStringLiteral("dwindleSmartSplit") || k == QStringLiteral("dwindle:smart_split")) dwindleOpts[QStringLiteral("smart_split")] = v;
            else if (k == QStringLiteral("dwindleDefaultSplitRatio") || k == QStringLiteral("dwindle:default_split_ratio")) dwindleOpts[QStringLiteral("default_split_ratio")] = v;
            else if (k == QStringLiteral("dwindleSplitWidthMultiplier") || k == QStringLiteral("dwindle:split_width_multiplier")) dwindleOpts[QStringLiteral("split_width_multiplier")] = v;
            else if (k == QStringLiteral("dwindleSmartResizing") || k == QStringLiteral("dwindle:smart_resizing")) dwindleOpts[QStringLiteral("smart_resizing")] = v;
            else if (k == QStringLiteral("dwindleSpecialScaleFactor") || k == QStringLiteral("dwindle:special_scale_factor")) dwindleOpts[QStringLiteral("special_scale_factor")] = v;
            else if (k == QStringLiteral("masterOrientation") || k == QStringLiteral("master:orientation")) masterOpts[QStringLiteral("orientation")] = v;
            else if (k == QStringLiteral("masterMfact") || k == QStringLiteral("master:mfact")) masterOpts[QStringLiteral("mfact")] = v;
            else if (k == QStringLiteral("masterNewStatus") || k == QStringLiteral("master:new_status")) masterOpts[QStringLiteral("new_status")] = v;
            else if (k == QStringLiteral("masterNewOnTop") || k == QStringLiteral("master:new_on_top")) masterOpts[QStringLiteral("new_on_top")] = v;
            else if (k == QStringLiteral("masterNewOnActive") || k == QStringLiteral("master:new_on_active")) masterOpts[QStringLiteral("new_on_active")] = v;
            else if (k == QStringLiteral("masterSmartResizing") || k == QStringLiteral("master:smart_resizing")) masterOpts[QStringLiteral("smart_resizing")] = v;
            else if (k == QStringLiteral("masterSpecialScaleFactor") || k == QStringLiteral("master:special_scale_factor")) masterOpts[QStringLiteral("special_scale_factor")] = v;
            else if (k == QStringLiteral("scrollingColumnWidth") || k == QStringLiteral("scrolling:column_width")) scrollingOpts[QStringLiteral("column_width")] = v;
            else if (k == QStringLiteral("scrollingDirection") || k == QStringLiteral("scrolling:direction")) scrollingOpts[QStringLiteral("direction")] = v;
            else if (k == QStringLiteral("scrollingFullscreenOnOneColumn") || k == QStringLiteral("scrolling:fullscreen_on_one_column")) scrollingOpts[QStringLiteral("fullscreen_on_one_column")] = v;
            else if (k == QStringLiteral("scrollingFocusFitMethod") || k == QStringLiteral("scrolling:focus_fit_method")) scrollingOpts[QStringLiteral("focus_fit_method")] = v;
            else if (k == QStringLiteral("scrollingFollowFocus") || k == QStringLiteral("scrolling:follow_focus")) scrollingOpts[QStringLiteral("follow_focus")] = v;
            else if (k == QStringLiteral("xwaylandEnabled") || k == QStringLiteral("xwayland:enabled")) xwlOpts[QStringLiteral("enabled")] = v;
            else if (k == QStringLiteral("xwaylandForceZeroScaling") || k == QStringLiteral("xwayland:force_zero_scaling")) xwlOpts[QStringLiteral("force_zero_scaling")] = v;
            else if (k == QStringLiteral("xwaylandUseNearestNeighbor") || k == QStringLiteral("xwayland:use_nearest_neighbor")) xwlOpts[QStringLiteral("use_nearest_neighbor")] = v;
            else if (k == QStringLiteral("noUpdateNews") || k == QStringLiteral("ecosystem:no_update_news")) ecoOpts[QStringLiteral("no_update_news")] = v;
            else if (k == QStringLiteral("noDonationNag") || k == QStringLiteral("ecosystem:no_donation_nag")) ecoOpts[QStringLiteral("no_donation_nag")] = v;
            else if (k == QStringLiteral("enforcePermissions") || k == QStringLiteral("ecosystem:enforce_permissions")) ecoOpts[QStringLiteral("enforce_permissions")] = v;
        }

        if (!generalOpts.isEmpty() || !generalSnapOpts.isEmpty()) {
            out += QStringLiteral("    general = {\n");
            for (auto it = generalOpts.constBegin(); it != generalOpts.constEnd(); ++it) {
                QString valStr = (it.value().typeId() == QMetaType::Bool) ? (it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false")) : (it.value().typeId() == QMetaType::Int ? QString::number(it.value().toInt()) : QStringLiteral("\"") + it.value().toString() + QStringLiteral("\""));
                out += QStringLiteral("        %1 = %2,\n").arg(it.key(), valStr);
            }
            if (!generalSnapOpts.isEmpty()) {
                writeSection(QStringLiteral("snap"), generalSnapOpts, 2);
            }
            out += QStringLiteral("    },\n");
        }

        if (!decorOpts.isEmpty() || !decorBlurOpts.isEmpty() || !decorShadowOpts.isEmpty()) {
            out += QStringLiteral("    decoration = {\n");
            for (auto it = decorOpts.constBegin(); it != decorOpts.constEnd(); ++it) {
                QString valStr = (it.value().typeId() == QMetaType::Bool) ? (it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false")) : QString::number(it.value().toDouble(), 'g', 6);
                out += QStringLiteral("        %1 = %2,\n").arg(it.key(), valStr);
            }
            if (!decorBlurOpts.isEmpty()) writeSection(QStringLiteral("blur"), decorBlurOpts, 2);
            if (!decorShadowOpts.isEmpty()) writeSection(QStringLiteral("shadow"), decorShadowOpts, 2);
            out += QStringLiteral("    },\n");
        }

        if (!inputOpts.isEmpty() || !inputTouchpadOpts.isEmpty()) {
            out += QStringLiteral("    input = {\n");
            for (auto it = inputOpts.constBegin(); it != inputOpts.constEnd(); ++it) {
                QString valStr;
                if (it.value().typeId() == QMetaType::Bool) {
                    valStr = it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false");
                } else if (it.value().typeId() == QMetaType::Double) {
                    valStr = QString::number(it.value().toDouble(), 'g', 4);
                } else if (it.value().typeId() == QMetaType::Int) {
                    valStr = QString::number(it.value().toInt());
                } else {
                    valStr = QStringLiteral("\"") + it.value().toString() + QStringLiteral("\"");
                }
                out += QStringLiteral("        %1 = %2,\n").arg(it.key(), valStr);
            }
            if (!inputTouchpadOpts.isEmpty()) writeSection(QStringLiteral("touchpad"), inputTouchpadOpts, 2);
            out += QStringLiteral("    },\n");
        }

        if (!gesturesOpts.isEmpty()) writeSection(QStringLiteral("gestures"), gesturesOpts, 1);
        if (!miscOpts.isEmpty()) writeSection(QStringLiteral("misc"), miscOpts, 1);
        if (!cursorOpts.isEmpty()) writeSection(QStringLiteral("cursor"), cursorOpts, 1);
        if (!dwindleOpts.isEmpty()) writeSection(QStringLiteral("dwindle"), dwindleOpts, 1);
        if (!masterOpts.isEmpty()) writeSection(QStringLiteral("master"), masterOpts, 1);
        if (!scrollingOpts.isEmpty()) writeSection(QStringLiteral("scrolling"), scrollingOpts, 1);
        if (!xwlOpts.isEmpty()) writeSection(QStringLiteral("xwayland"), xwlOpts, 1);
        if (!ecoOpts.isEmpty()) writeSection(QStringLiteral("ecosystem"), ecoOpts, 1);

        out += QStringLiteral("})\n\n");
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
                if (it.value().typeId() == QMetaType::Bool) {
                    windowRulesStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toBool() ? QStringLiteral("true") : QStringLiteral("false"));
                } else if (it.value().typeId() == QMetaType::Double || it.value().typeId() == QMetaType::Int) {
                    windowRulesStr += QStringLiteral("    %1 = %2,\n").arg(it.key(), it.value().toString());
                } else {
                    windowRulesStr += QStringLiteral("    %1 = \"%2\",\n").arg(it.key(), it.value().toString());
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
            out += QStringLiteral("hl.bind(\"%1\", hl.dsp.%2(\"%3\"))\n").arg(key, dsp, args);
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
