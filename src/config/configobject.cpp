#include "configobject.hpp"
#include "configlist.hpp"

#include <qjsonarray.h>
#include <qmetaobject.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

ConfigObject::ConfigObject(QObject* parent)
    : ConfigNode(parent) {}

void ConfigObject::loadFromJson(const QJsonValue& json) {
    const auto obj = json.toObject();
    const auto* meta = metaObject();

    qCDebug(lcConfig) << "Loading JSON into" << meta->className() << "with" << obj.keys().size()
                      << "keys:" << obj.keys();

    QSet<QString> known;

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        known.insert(key);

        if (!obj.contains(key))
            continue;

        if (isGlobalOnly(key))
            qCWarning(lcConfig, "Option '%s' is global-only and will be ignored in per-monitor config",
                qUtf8Printable(propertyPath(key)));

        const auto jsonVal = obj.value(key);

        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            qCDebug(lcConfig) << "  Recursing into" << key;
            node->loadFromJson(jsonVal);
            m_loadedKeys.insert(key);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (prop.metaType().id() == QMetaType::QStringList) {
            QStringList list;
            const auto jsonArr = jsonVal.toArray();
            for (const auto& v : jsonArr)
                list.append(v.toString());
            prop.write(this, QVariant::fromValue(list));
            m_loadedKeys.insert(key);
            qCDebug(lcConfig) << "  Loaded" << key << "=" << list;
            continue;
        }

        prop.write(this, jsonVal.toVariant());
        m_loadedKeys.insert(key);
        qCDebug(lcConfig) << "  Loaded" << key << "=" << jsonVal.toVariant();
    }

    m_extras = {};
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (!known.contains(it.key())) {
            m_extras.insert(it.key(), it.value());
            qCDebug(lcConfig) << "  Keeping unknown key" << it.key();
        }
    }
}

QJsonValue ConfigObject::toJson() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        const auto value = prop.read(this);

        if (auto* const node = value.value<ConfigNode*>()) {
            const auto childJson = node->toJson();
            if (!childJson.isUndefined())
                obj.insert(key, childJson);
            continue;
        }

        if (!m_loadedKeys.contains(key))
            continue;

        if (!prop.isWritable())
            continue;

        if (prop.metaType().id() == QMetaType::QStringList) {
            QJsonArray arr;
            const auto strList = value.toStringList();
            for (const auto& s : strList)
                arr.append(s);
            obj.insert(key, arr);
            continue;
        }

        if (prop.metaType().id() == QMetaType::QVariantList) {
            obj.insert(key, QJsonArray::fromVariantList(value.toList()));
            continue;
        }

        obj.insert(key, QJsonValue::fromVariant(value));
    }

    for (auto it = m_extras.begin(); it != m_extras.end(); ++it)
        obj.insert(it.key(), it.value());

    if (obj.isEmpty())
        return QJsonValue::Undefined;

    return obj;
}

void ConfigObject::clearLoadedKeys() {
    m_loadedKeys.clear();
    m_extras = {};

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>())
            node->clearLoadedKeys();
    }
}

QStringList ConfigObject::identityKeys() const {
    return {};
}

QStringList ConfigObject::unknownKeys() const {
    auto keys = m_extras.keys();

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        auto* const node = prop.read(this).value<ConfigNode*>();
        if (!node)
            continue;

        const auto childKeys = node->unknownKeys();
        for (const auto& childKey : childKeys)
            keys.append(joinPath(key, childKey));
    }

    return keys;
}

QList<ConfigNode*> ConfigObject::childNodes() const {
    QList<ConfigNode*> nodes;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>())
            nodes.append(node);
    }

    return nodes;
}

void ConfigObject::syncValuesFromGlobal() {
    const auto* meta = metaObject();
    qCDebug(lcConfig) << "  Loaded keys:" << m_loadedKeys;

    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            if (auto* const globalNode = prop.read(m_global).value<ConfigNode*>())
                node->syncFromGlobal(globalNode);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            auto val = prop.read(m_global);
            prop.write(this, val);
            m_loadedKeys.remove(key);
            qCDebug(lcConfig) << "  Synced" << key << "=" << val << "from global";
        } else {
            qCDebug(lcConfig) << "  Keeping loaded" << key << "=" << prop.read(this);
        }
    }
}

void ConfigObject::resyncFromGlobal() {
    if (!m_global)
        return;

    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (isGlobalOnly(key))
            continue;

        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            node->resyncFromGlobal();
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            prop.write(this, prop.read(m_global));
            m_loadedKeys.remove(key);
        }
    }
}

bool ConfigObject::isPropertyLoaded(const QString& name) const {
    if (!isOverlay())
        return false;

    if (m_loadedKeys.contains(name))
        return true;

    const int idx = metaObject()->indexOfProperty(name.toUtf8().constData());
    if (idx >= 0) {
        const auto prop = metaObject()->property(idx);
        if (auto* const node = prop.read(this).value<ConfigNode*>()) {
            if (auto* const listNode = qobject_cast<ConfigList*>(node)) {
                return listNode->isLoaded();
            }
        }
    }

    return false;
}

bool ConfigObject::isGlobalOnly(const QString& name) const {
    return isOverlay() && m_globalOnlyKeys.contains(name);
}

QStringList ConfigObject::globalOnlyKeys() const {
    return { m_globalOnlyKeys.begin(), m_globalOnlyKeys.end() };
}

void ConfigObject::resetOption(const QString& name) {
    const int idx = metaObject()->indexOfProperty(name.toUtf8().constData());
    if (idx < 0) {
        m_loadedKeys.remove(name);
        return;
    }

    const auto prop = metaObject()->property(idx);

    if (auto* const node = prop.read(this).value<ConfigNode*>()) {
        node->clearLoadedKeys();
        node->resyncFromGlobal();
        m_loadedKeys.remove(name);
        if (prop.hasNotifySignal())
            prop.notifySignal().invoke(this);
        return;
    }

    if (m_global && prop.isWritable())
        prop.write(this, prop.read(m_global));

    m_loadedKeys.remove(name);

    if (prop.hasNotifySignal())
        prop.notifySignal().invoke(this);
}

void ConfigObject::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (m_loadedKeys.contains(it.key()) || isGlobalOnly(it.key()))
            continue;

        int idx = metaObject()->indexOfProperty(it.key().toUtf8().constData());
        if (idx >= 0) {
            metaObject()->property(idx).write(this, it.value());
            m_loadedKeys.remove(it.key());
            qCDebug(lcConfig) << metaObject()->className() << "synced" << it.key() << "=" << it.value()
                              << "from global change";
        }
    }
}

QString ConfigObject::childPath(const ConfigNode* child) const {
    const auto* meta = metaObject();
    for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (isGlobalOnly(QString::fromUtf8(prop.name())))
            continue;

        if (prop.read(this).value<ConfigNode*>() == child)
            return QString::fromUtf8(prop.name());
    }

    return {};
}

void ConfigObject::markPropertyLoaded(const QString& name) {
    m_loadedKeys.insert(name);
}

void ConfigObject::markGlobalOnly(const QString& name) {
    m_globalOnlyKeys.insert(name);
}

}
