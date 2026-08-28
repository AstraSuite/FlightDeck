#include "sessionconfig.hpp"
#include "rootconfig.hpp"

#include <qfile.h>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qmetaobject.h>
#include <qregularexpression.h>
#include <algorithm>

namespace caelestia::config {

namespace {

QString getRootFilePath(const QObject* obj) {
    const QObject* curr = obj;
    while (curr) {
        if (auto* root = qobject_cast<const RootConfig*>(curr))
            return root->filePath();
        curr = curr->parent();
    }
    return QString();
}

QStringList parseRawKeyOrder(const QString& filePath, const QString& sectionKey) {
    QStringList order;
    if (filePath.isEmpty())
        return order;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return order;

    const QString text = QString::fromUtf8(file.readAll());
    file.close();

    int sessionPos = text.indexOf(QStringLiteral("\"session\""));
    if (sessionPos == -1)
        sessionPos = 0;

    int sectionPos = text.indexOf(QStringLiteral("\"") + sectionKey + QStringLiteral("\""), sessionPos);
    if (sectionPos == -1)
        return order;

    int bracePos = text.indexOf(QLatin1Char('{'), sectionPos);
    if (bracePos == -1)
        return order;

    int depth = 1;
    int endPos = bracePos + 1;
    bool inString = false;
    bool escape = false;

    while (endPos < text.length() && depth > 0) {
        QChar ch = text.at(endPos);
        if (escape) {
            escape = false;
        } else if (ch == QLatin1Char('\\')) {
            escape = true;
        } else if (ch == QLatin1Char('"')) {
            inString = !inString;
        } else if (!inString) {
            if (ch == QLatin1Char('{'))
                depth++;
            else if (ch == QLatin1Char('}'))
                depth--;
        }
        endPos++;
    }

    QString block = text.mid(bracePos, endPos - bracePos);

    static const QRegularExpression keyRegex(QStringLiteral("\"([^\"]+)\"\\s*:"));
    auto it = keyRegex.globalMatch(block);
    while (it.hasNext()) {
        auto match = it.next();
        QString key = match.captured(1);
        if (!order.contains(key))
            order.append(key);
    }

    return order;
}

}

SessionIcons::SessionIcons(QObject* parent)
    : ConfigObject(parent) {}

void SessionIcons::loadFromJson(const QJsonValue& json) {
    ConfigObject::loadFromJson(json);

    if (!json.isObject())
        return;

    const auto obj = json.toObject();
    const auto* meta = metaObject();

    QSet<QString> known;
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        known.insert(QString::fromUtf8(meta->property(i).name()));
    }

    m_customIcons.clear();
    m_customIconKeys.clear();

    const QString filePath = getRootFilePath(this);
    const QStringList rawOrder = parseRawKeyOrder(filePath, QStringLiteral("icons"));

    for (const auto& key : rawOrder) {
        if (obj.contains(key)) {
            m_customIconKeys.append(key);
            if (!known.contains(key)) {
                const QString iconVal = obj.value(key).toString();
                m_customIcons.insert(key, iconVal);
                setProperty(key.toUtf8().constData(), iconVal);
                markPropertyLoaded(key);
                notifyPropertyChanged(key, iconVal);
            }
        }
    }

    for (auto it = obj.begin(); it != obj.end(); ++it) {
        const QString key = it.key();
        if (!m_customIconKeys.contains(key)) {
            m_customIconKeys.append(key);
            if (!known.contains(key)) {
                const QString iconVal = it.value().toString();
                m_customIcons.insert(key, iconVal);
                setProperty(key.toUtf8().constData(), iconVal);
                markPropertyLoaded(key);
                notifyPropertyChanged(key, iconVal);
            }
        }
    }
}

QJsonValue SessionIcons::toJson() const {
    const auto baseVal = ConfigObject::toJson();
    QJsonObject obj = baseVal.isObject() ? baseVal.toObject() : QJsonObject();

    for (const auto& key : m_customIconKeys) {
        if (isPropertyLoaded(key) && m_customIcons.contains(key))
            obj.insert(key, m_customIcons.value(key));
    }

    if (obj.isEmpty())
        return QJsonValue::Undefined;

    return obj;
}

void SessionIcons::clearLoadedKeys() {
    for (auto it = m_customIcons.keyBegin(); it != m_customIcons.keyEnd(); ++it) {
        setProperty(it->toUtf8().constData(), QVariant());
    }
    m_customIcons.clear();
    m_customIconKeys.clear();
    ConfigObject::clearLoadedKeys();
}

QStringList SessionIcons::unknownKeys() const {
    auto keys = ConfigObject::unknownKeys();
    for (auto it = m_customIcons.keyBegin(); it != m_customIcons.keyEnd(); ++it) {
        keys.removeAll(*it);
    }
    return keys;
}

void SessionIcons::syncValuesFromGlobal() {
    ConfigObject::syncValuesFromGlobal();

    if (!m_global)
        return;

    auto* globalIcons = qobject_cast<SessionIcons*>(m_global);
    if (!globalIcons)
        return;

    for (const auto& key : globalIcons->customIconKeys()) {
        if (!m_customIconKeys.contains(key))
            m_customIconKeys.append(key);
        if (!isPropertyLoaded(key) && globalIcons->customIcons().contains(key)) {
            const QString val = globalIcons->customIcons().value(key);
            m_customIcons.insert(key, val);
            setProperty(key.toUtf8().constData(), val);
        }
    }
}

void SessionIcons::resyncFromGlobal() {
    ConfigObject::resyncFromGlobal();

    if (!m_global)
        return;

    auto* globalIcons = qobject_cast<SessionIcons*>(m_global);
    if (!globalIcons)
        return;

    for (const auto& key : globalIcons->customIconKeys()) {
        if (!m_customIconKeys.contains(key))
            m_customIconKeys.append(key);
        if (!isPropertyLoaded(key) && globalIcons->customIcons().contains(key)) {
            const QString val = globalIcons->customIcons().value(key);
            m_customIcons.insert(key, val);
            setProperty(key.toUtf8().constData(), val);
        }
    }
}

void SessionIcons::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    ConfigObject::onGlobalPropertiesChanged(changed);

    if (!m_global)
        return;

    auto* globalIcons = qobject_cast<SessionIcons*>(m_global);
    if (!globalIcons)
        return;

    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (globalIcons->customIcons().contains(it.key()) && !isPropertyLoaded(it.key())) {
            const QString iconVal = globalIcons->customIcons().value(it.key());
            m_customIcons.insert(it.key(), iconVal);
            if (!m_customIconKeys.contains(it.key()))
                m_customIconKeys.append(it.key());
            setProperty(it.key().toUtf8().constData(), iconVal);
            notifyPropertyChanged(it.key(), iconVal);
        }
    }
}

SessionCommands::SessionCommands(QObject* parent)
    : ConfigObject(parent) {}

void SessionCommands::loadFromJson(const QJsonValue& json) {
    ConfigObject::loadFromJson(json);

    if (!json.isObject())
        return;

    const auto obj = json.toObject();
    const auto* meta = metaObject();

    QSet<QString> known;
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        known.insert(QString::fromUtf8(meta->property(i).name()));
    }

    m_customCommands.clear();
    m_customCommandKeys.clear();

    const QString filePath = getRootFilePath(this);
    const QStringList rawOrder = parseRawKeyOrder(filePath, QStringLiteral("commands"));

    for (const auto& key : rawOrder) {
        if (obj.contains(key)) {
            m_customCommandKeys.append(key);
            if (!known.contains(key)) {
                QStringList cmdList;
                const auto val = obj.value(key);
                if (val.isArray()) {
                    const auto arr = val.toArray();
                    for (const auto& v : arr)
                        cmdList.append(v.toString());
                } else if (val.isString()) {
                    cmdList.append(val.toString());
                }
                m_customCommands.insert(key, cmdList);
                setProperty(key.toUtf8().constData(), QVariant::fromValue(cmdList));
                markPropertyLoaded(key);
                notifyPropertyChanged(key, QVariant::fromValue(cmdList));
            }
        }
    }

    for (auto it = obj.begin(); it != obj.end(); ++it) {
        const QString key = it.key();
        if (!m_customCommandKeys.contains(key)) {
            m_customCommandKeys.append(key);
            if (!known.contains(key)) {
                QStringList cmdList;
                const auto val = it.value();
                if (val.isArray()) {
                    const auto arr = val.toArray();
                    for (const auto& v : arr)
                        cmdList.append(v.toString());
                } else if (val.isString()) {
                    cmdList.append(val.toString());
                }
                m_customCommands.insert(key, cmdList);
                setProperty(key.toUtf8().constData(), QVariant::fromValue(cmdList));
                markPropertyLoaded(key);
                notifyPropertyChanged(key, QVariant::fromValue(cmdList));
            }
        }
    }
}

QJsonValue SessionCommands::toJson() const {
    const auto baseVal = ConfigObject::toJson();
    QJsonObject obj = baseVal.isObject() ? baseVal.toObject() : QJsonObject();

    for (const auto& key : m_customCommandKeys) {
        if (isPropertyLoaded(key) && m_customCommands.contains(key)) {
            QJsonArray arr;
            for (const auto& s : m_customCommands.value(key))
                arr.append(s);
            obj.insert(key, arr);
        }
    }

    if (obj.isEmpty())
        return QJsonValue::Undefined;

    return obj;
}

void SessionCommands::clearLoadedKeys() {
    for (auto it = m_customCommands.keyBegin(); it != m_customCommands.keyEnd(); ++it) {
        setProperty(it->toUtf8().constData(), QVariant());
    }
    m_customCommands.clear();
    m_customCommandKeys.clear();
    ConfigObject::clearLoadedKeys();
}

QStringList SessionCommands::unknownKeys() const {
    auto keys = ConfigObject::unknownKeys();
    for (auto it = m_customCommands.keyBegin(); it != m_customCommands.keyEnd(); ++it) {
        keys.removeAll(*it);
    }
    return keys;
}

void SessionCommands::syncValuesFromGlobal() {
    ConfigObject::syncValuesFromGlobal();

    if (!m_global)
        return;

    auto* globalCmds = qobject_cast<SessionCommands*>(m_global);
    if (!globalCmds)
        return;

    for (const auto& key : globalCmds->customCommandKeys()) {
        if (!m_customCommandKeys.contains(key))
            m_customCommandKeys.append(key);
        if (!isPropertyLoaded(key) && globalCmds->customCommands().contains(key)) {
            const QStringList val = globalCmds->customCommands().value(key);
            m_customCommands.insert(key, val);
            setProperty(key.toUtf8().constData(), QVariant::fromValue(val));
        }
    }
}

void SessionCommands::resyncFromGlobal() {
    ConfigObject::resyncFromGlobal();

    if (!m_global)
        return;

    auto* globalCmds = qobject_cast<SessionCommands*>(m_global);
    if (!globalCmds)
        return;

    for (const auto& key : globalCmds->customCommandKeys()) {
        if (!m_customCommandKeys.contains(key))
            m_customCommandKeys.append(key);
        if (!isPropertyLoaded(key) && globalCmds->customCommands().contains(key)) {
            const QStringList val = globalCmds->customCommands().value(key);
            m_customCommands.insert(key, val);
            setProperty(key.toUtf8().constData(), QVariant::fromValue(val));
        }
    }
}

void SessionCommands::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    ConfigObject::onGlobalPropertiesChanged(changed);

    if (!m_global)
        return;

    auto* globalCmds = qobject_cast<SessionCommands*>(m_global);
    if (!globalCmds)
        return;

    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (globalCmds->customCommands().contains(it.key()) && !isPropertyLoaded(it.key())) {
            const QStringList cmdVal = globalCmds->customCommands().value(it.key());
            m_customCommands.insert(it.key(), cmdVal);
            if (!m_customCommandKeys.contains(it.key()))
                m_customCommandKeys.append(it.key());
            setProperty(it.key().toUtf8().constData(), QVariant::fromValue(cmdVal));
            notifyPropertyChanged(it.key(), QVariant::fromValue(cmdVal));
        }
    }
}

SessionConfig::SessionConfig(QObject* parent)
    : ConfigObject(parent)
    , m_icons(new SessionIcons(this))
    , m_commands(new SessionCommands(this)) {
    auto notifyBoth = [this] {
        emit buttonsChanged();
        emit customButtonsChanged();
    };
    connect(m_icons, &ConfigNode::propertiesChanged, this, notifyBoth);
    connect(m_commands, &ConfigNode::propertiesChanged, this, notifyBoth);
}

void SessionConfig::loadFromJson(const QJsonValue& json) {
    ConfigObject::loadFromJson(json);

    if (!json.isObject())
        return;

    const auto obj = json.toObject();
    if (obj.contains(QStringLiteral("icons")) && m_icons) {
        m_icons->loadFromJson(obj.value(QStringLiteral("icons")));
    }
    if (obj.contains(QStringLiteral("commands")) && m_commands) {
        m_commands->loadFromJson(obj.value(QStringLiteral("commands")));
    }
    emit buttonsChanged();
    emit customButtonsChanged();
}

QJsonValue SessionConfig::toJson() const {
    const auto baseVal = ConfigObject::toJson();
    QJsonObject obj = baseVal.isObject() ? baseVal.toObject() : QJsonObject();

    if (m_icons) {
        const auto iconsJson = m_icons->toJson();
        if (!iconsJson.isUndefined())
            obj.insert(QStringLiteral("icons"), iconsJson);
    }
    if (m_commands) {
        const auto cmdsJson = m_commands->toJson();
        if (!cmdsJson.isUndefined())
            obj.insert(QStringLiteral("commands"), cmdsJson);
    }

    if (obj.isEmpty())
        return QJsonValue::Undefined;

    return obj;
}

void SessionConfig::clearLoadedKeys() {
    ConfigObject::clearLoadedKeys();
    if (m_icons)
        m_icons->clearLoadedKeys();
    if (m_commands)
        m_commands->clearLoadedKeys();
    emit buttonsChanged();
    emit customButtonsChanged();
}

QList<ConfigNode*> SessionConfig::childNodes() const {
    QList<ConfigNode*> nodes = ConfigObject::childNodes();
    if (m_icons && !nodes.contains(m_icons))
        nodes.append(m_icons);
    if (m_commands && !nodes.contains(m_commands))
        nodes.append(m_commands);
    return nodes;
}

void SessionConfig::syncValuesFromGlobal() {
    ConfigObject::syncValuesFromGlobal();

    if (!m_global)
        return;

    auto* globalSession = qobject_cast<SessionConfig*>(m_global);
    if (!globalSession)
        return;

    if (m_icons && globalSession->icons())
        m_icons->syncFromGlobal(globalSession->icons());
    if (m_commands && globalSession->commands())
        m_commands->syncFromGlobal(globalSession->commands());

    emit buttonsChanged();
    emit customButtonsChanged();
}

void SessionConfig::resyncFromGlobal() {
    ConfigObject::resyncFromGlobal();

    if (!m_global)
        return;

    auto* globalSession = qobject_cast<SessionConfig*>(m_global);
    if (!globalSession)
        return;

    if (m_icons)
        m_icons->resyncFromGlobal();
    if (m_commands)
        m_commands->resyncFromGlobal();

    emit buttonsChanged();
    emit customButtonsChanged();
}

QVariantList SessionConfig::buttons() const {
    QVariantList result;
    if (!m_icons || !m_commands)
        return result;

    static const QStringList defaultKeys = {
        QStringLiteral("logout"),
        QStringLiteral("shutdown"),
        QStringLiteral("hibernate"),
        QStringLiteral("reboot")
    };

    QStringList orderedKeys;
    QSet<QString> seen;

    if (m_icons) {
        for (const auto& key : m_icons->customIconKeys()) {
            if (!seen.contains(key)) {
                seen.insert(key);
                orderedKeys.append(key);
            }
        }
    }
    if (m_commands) {
        for (const auto& key : m_commands->customCommandKeys()) {
            if (!seen.contains(key)) {
                seen.insert(key);
                orderedKeys.append(key);
            }
        }
    }

    for (const auto& key : defaultKeys) {
        if (!seen.contains(key)) {
            seen.insert(key);
            orderedKeys.append(key);
        }
    }

    for (const auto& key : orderedKeys) {
        QVariantMap btn;
        btn.insert(QStringLiteral("key"), key);

        QString icon = key;
        QVariant iconProp = m_icons->property(key.toUtf8().constData());
        if (iconProp.isValid() && iconProp.userType() == QMetaType::QString) {
            icon = iconProp.toString();
        } else if (m_icons->customIcons().contains(key)) {
            icon = m_icons->customIcons().value(key);
        }
        btn.insert(QStringLiteral("icon"), icon);

        QStringList command;
        QVariant cmdProp = m_commands->property(key.toUtf8().constData());
        if (cmdProp.isValid() && cmdProp.userType() == QMetaType::QStringList) {
            command = cmdProp.toStringList();
        } else if (m_commands->customCommands().contains(key)) {
            command = m_commands->customCommands().value(key);
        } else {
            command = QStringList{ key };
        }
        btn.insert(QStringLiteral("command"), QVariant::fromValue(command));

        result.append(btn);
    }

    return result;
}

QVariantList SessionConfig::customButtons() const {
    QVariantList result;
    if (!m_icons && !m_commands)
        return result;

    static const QSet<QString> defaultKeys = {
        QStringLiteral("logout"),
        QStringLiteral("shutdown"),
        QStringLiteral("hibernate"),
        QStringLiteral("reboot")
    };

    QStringList orderedKeys;
    QSet<QString> seen;

    if (m_icons) {
        for (const auto& key : m_icons->customIconKeys()) {
            if (!defaultKeys.contains(key) && !seen.contains(key)) {
                seen.insert(key);
                orderedKeys.append(key);
            }
        }
    }
    if (m_commands) {
        for (const auto& key : m_commands->customCommandKeys()) {
            if (!defaultKeys.contains(key) && !seen.contains(key)) {
                seen.insert(key);
                orderedKeys.append(key);
            }
        }
    }

    for (const auto& key : orderedKeys) {
        QVariantMap btn;
        btn.insert(QStringLiteral("key"), key);

        QString icon = key;
        if (m_icons && m_icons->customIcons().contains(key)) {
            icon = m_icons->customIcons().value(key);
        } else if (m_icons) {
            QVariant iconProp = m_icons->property(key.toUtf8().constData());
            if (iconProp.isValid() && iconProp.userType() == QMetaType::QString)
                icon = iconProp.toString();
        }
        btn.insert(QStringLiteral("icon"), icon);

        QStringList command;
        if (m_commands && m_commands->customCommands().contains(key)) {
            command = m_commands->customCommands().value(key);
        } else if (m_commands) {
            QVariant cmdProp = m_commands->property(key.toUtf8().constData());
            if (cmdProp.isValid() && cmdProp.userType() == QMetaType::QStringList)
                command = cmdProp.toStringList();
            else
                command = QStringList{ key };
        }
        btn.insert(QStringLiteral("command"), QVariant::fromValue(command));

        result.append(btn);
    }

    return result;
}

}
