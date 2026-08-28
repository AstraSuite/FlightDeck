#include "astrahelmwriter.hpp"
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

namespace Helm::Caelestia {

AstraHelmWriter* AstraHelmWriter::instance() {
    static AstraHelmWriter inst;
    return &inst;
}

AstraHelmWriter* AstraHelmWriter::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QString AstraHelmWriter::astraHelmFilePath() {
    return QDir::homePath() + QStringLiteral("/.config/caelestia/astra-helm.lua");
}

AstraHelmWriter::AstraHelmWriter(QObject* parent)
    : QObject(parent) {
    loadFromFile();
}

bool AstraHelmWriter::isDirty() const {
    return m_isDirty;
}

int AstraHelmWriter::dirtyCount() const {
    return m_isDirty ? 1 : 0;
}

QVariantList AstraHelmWriter::monitors() const {
    return m_monitors;
}

void AstraHelmWriter::setMonitors(const QVariantList& monitors) {
    if (m_monitors != monitors) {
        m_monitors = monitors;
        m_isDirty = true;
        emit monitorsChanged();
        emit dirtyChanged();
    }
}

QVariantList AstraHelmWriter::windowRules() const {
    return m_windowRules;
}

void AstraHelmWriter::setWindowRules(const QVariantList& rules) {
    if (m_windowRules != rules) {
        m_windowRules = rules;
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList AstraHelmWriter::layerRules() const {
    return m_layerRules;
}

void AstraHelmWriter::setLayerRules(const QVariantList& rules) {
    if (m_layerRules != rules) {
        m_layerRules = rules;
        m_isDirty = true;
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

QVariantList AstraHelmWriter::customBinds() const {
    return m_customBinds;
}

void AstraHelmWriter::setCustomBinds(const QVariantList& binds) {
    if (m_customBinds != binds) {
        m_customBinds = binds;
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

QStringList AstraHelmWriter::autostartCommands() const {
    return m_autostartCommands;
}

void AstraHelmWriter::setAutostartCommands(const QStringList& cmds) {
    if (m_autostartCommands != cmds) {
        m_autostartCommands = cmds;
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

QVariantMap AstraHelmWriter::pluginConfigs() const {
    return m_pluginConfigs;
}

void AstraHelmWriter::setPluginConfigs(const QVariantMap& plugins) {
    if (m_pluginConfigs != plugins) {
        m_pluginConfigs = plugins;
        m_isDirty = true;
        emit pluginsChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::addWindowRule(const QVariantMap& rule) {
    m_windowRules.append(rule);
    m_isDirty = true;
    emit windowRulesChanged();
    emit dirtyChanged();
}

void AstraHelmWriter::removeWindowRule(int index) {
    if (index >= 0 && index < m_windowRules.size()) {
        m_windowRules.removeAt(index);
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::updateWindowRule(int index, const QVariantMap& rule) {
    if (index >= 0 && index < m_windowRules.size()) {
        m_windowRules[index] = rule;
        m_isDirty = true;
        emit windowRulesChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::addLayerRule(const QVariantMap& rule) {
    m_layerRules.append(rule);
    m_isDirty = true;
    emit layerRulesChanged();
    emit dirtyChanged();
}

void AstraHelmWriter::removeLayerRule(int index) {
    if (index >= 0 && index < m_layerRules.size()) {
        m_layerRules.removeAt(index);
        m_isDirty = true;
        emit layerRulesChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::addAutostart(const QString& cmd) {
    if (!m_autostartCommands.contains(cmd)) {
        m_autostartCommands.append(cmd);
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::removeAutostart(int index) {
    if (index >= 0 && index < m_autostartCommands.size()) {
        m_autostartCommands.removeAt(index);
        m_isDirty = true;
        emit autostartChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst) {
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

void AstraHelmWriter::removeCustomBind(int index) {
    if (index >= 0 && index < m_customBinds.size()) {
        m_customBinds.removeAt(index);
        m_isDirty = true;
        emit customBindsChanged();
        emit dirtyChanged();
    }
}

void AstraHelmWriter::setMonitorConfig(const QString& output, const QString& mode, const QString& position, qreal scale, int transform, bool disabled) {
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

void AstraHelmWriter::loadFromFile() {
    const QString path = astraHelmFilePath();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }

    const QString content = QString::fromUtf8(file.readAll());
    file.close();

    // Simple parser for existing astra-helm.lua
    m_monitors.clear();
    m_windowRules.clear();
    m_layerRules.clear();
    m_customBinds.clear();
    m_autostartCommands.clear();

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

    // Parse autostart commands: hl.exec_cmd("...")
    QRegularExpression execRe(QStringLiteral(R"RAW(hl\.exec_cmd\("((?:\\.|[^"\\])*)"\))RAW"));
    QRegularExpressionMatchIterator execIt = execRe.globalMatch(content);
    while (execIt.hasNext()) {
        m_autostartCommands.append(execIt.next().captured(1));
    }

    // Parse custom binds: hl.bind("...", hl.dsp.exec("..."))
    QRegularExpression bindRe(QStringLiteral(R"RAW(hl\.bind\("([^"]+)",\s*hl\.dsp\.([a-zA-Z0-9_]+)\("((?:\\.|[^"\\])*)"\)\))RAW"));
    QRegularExpressionMatchIterator bindIt = bindRe.globalMatch(content);
    while (bindIt.hasNext()) {
        auto m = bindIt.next();
        QVariantMap b{
            { QStringLiteral("key"), m.captured(1) },
            { QStringLiteral("dispatcher"), m.captured(2) },
            { QStringLiteral("args"), m.captured(3) },
            { QStringLiteral("unbindFirst"), true }
        };
        m_customBinds.append(b);
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

QString AstraHelmWriter::formatLua() const {
    QString out;
    out += QStringLiteral("-- Generated by Astra Helm\n\n");

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

bool AstraHelmWriter::save() {
    const QString path = astraHelmFilePath();
    const QFileInfo fi(path);
    if (!fi.dir().exists()) {
        fi.dir().mkpath(QStringLiteral("."));
    }

    const QString lua = formatLua();
    QString validationError;
    if (!LuaValidator::validate(lua, &validationError)) {
        qWarning() << "Lua validation failed for astra-helm.lua:" << validationError;
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

void AstraHelmWriter::reload() {
    loadFromFile();
}

void AstraHelmWriter::discard() {
    loadFromFile();
}

QVariantList AstraHelmWriter::activeHyprlandClients() const {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("j/clients"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return QVariantList();
}

QVariantList AstraHelmWriter::activeHyprlandWindowRules() const {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("j/windowrules"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return QVariantList();
}

QVariantList AstraHelmWriter::activeHyprlandLayers() const {
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

} // namespace Helm::Caelestia
