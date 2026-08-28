#include "configlist.hpp"

#include <qjsonobject.h>
#include <qmetaobject.h>
#include <qqmlengine.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

ConfigList::ConfigList(QObject* parent, const QVariantList& defaults)
    : ConfigNode(parent)
    , m_defaults(QJsonArray::fromVariantList(defaults)) {}

int ConfigList::count() const {
    return static_cast<int>(m_items.size());
}

QVariantList ConfigList::values() const {
    QVariantList vals;
    vals.reserve(m_items.size());
    for (auto* const item : m_items)
        vals.append(QVariant::fromValue(item));
    return vals;
}

ConfigObject* ConfigList::itemAt(int index) const {
    if (index < 0 || index >= m_items.size())
        return nullptr;

    return m_items.at(index);
}

const QList<ConfigObject*>& ConfigList::items() const {
    return m_items;
}

void ConfigList::remove(int index) {
    if (index < 0 || index >= m_items.size()) {
        qCWarning(lcConfig) << metaObject()->className() << "cannot remove index" << index << "of" << count();
        return;
    }

    destroyItem(m_items.takeAt(index));

    setLoaded(true);
    emit countChanged();
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::move(int from, int to) {
    if (from < 0 || from >= m_items.size() || to < 0 || to >= m_items.size()) {
        qCWarning(lcConfig) << metaObject()->className() << "cannot move" << from << "to" << to << "of" << count();
        return;
    }

    if (from == to)
        return;

    m_items.move(from, to);

    setLoaded(true);
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::clear() {
    if (m_items.isEmpty())
        return;

    destroyItems();

    setLoaded(true);
    emit countChanged();
    emit valuesChanged();
    notifyChanged();
}

void ConfigList::loadFromJson(const QJsonValue& json) {
    if (!json.isArray()) {
        qCWarning(lcConfig, "Option '%s' must be a list, ignoring", qUtf8Printable(propertyPath()));
        m_rejectedJson = json;
        return;
    }

    m_rejectedJson = QJsonValue::Undefined;
    populate(json.toArray());
    setLoaded(true);
}

QJsonValue ConfigList::toJson() const {

    if (m_loaded)
        return elementsToJson();

    return m_rejectedJson;
}

void ConfigList::clearLoadedKeys() {

    setLoaded(false);
    m_rejectedJson = QJsonValue::Undefined;
}

QStringList ConfigList::unknownKeys() const {
    QStringList keys;

    for (int i = 0; i < m_items.size(); ++i) {
        const auto childKeys = m_items.at(i)->unknownKeys();
        for (const auto& childKey : childKeys)
            keys.append(joinPath(u"[%1]"_s.arg(i), childKey));
    }

    return keys;
}

void ConfigList::resyncFromGlobal() {
    syncValuesFromGlobal();
}

ConfigObject* ConfigList::insertItem(const QVariantMap& props, int index) {
    const auto pos = index < 0 || index > m_items.size() ? m_items.size() : index;

    appendItem(QJsonObject::fromVariantMap(props));
    m_items.move(m_items.size() - 1, pos);

    auto* const item = m_items.at(pos);
    const auto unknown = item->unknownKeys();
    for (const auto& key : unknown)
        qCWarning(lcConfig) << "Unknown option" << key << "for" << item->metaObject()->className();

    setLoaded(true);
    emit countChanged();
    emit valuesChanged();
    notifyChanged();

    return item;
}

QJsonArray ConfigList::elementsToJson() const {
    QJsonArray arr;

    for (auto* const item : m_items)
        arr.append(item->toJson().toObject());

    return arr;
}

void ConfigList::resetToDefaults() {

    loadFromJsonQuietly(m_defaults);
    setLoaded(false);
}

void ConfigList::syncValuesFromGlobal() {
    if (m_loaded)
        return;

    if (auto* const global = qobject_cast<ConfigList*>(m_global))
        populate(global->elementsToJson());
}

void ConfigList::onGlobalPropertiesChanged(const QMap<QString, QVariant>&) {
    syncValuesFromGlobal();
}

QString ConfigList::childPath(const ConfigNode* child) const {

    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i) == child)
            return u"[%1]"_s.arg(i);

    return {};
}

void ConfigList::populate(const QJsonArray& arr) {

    const auto current = elementsToJson();
    if (current == arr)
        return;

    const auto old = m_items;
    QList<bool> reused(old.size(), false);

    m_items.clear();
    m_items.reserve(arr.size());

    for (int i = 0; i < arr.size(); ++i) {
        auto match = i < old.size() && !reused.at(i) && current.at(i) == arr.at(i) ? i : -1;

        for (int j = 0; match < 0 && j < old.size(); ++j)
            if (!reused.at(j) && current.at(j) == arr.at(i))
                match = j;

        auto update = false;
        for (int j = 0; match < 0 && j < old.size(); ++j) {
            if (!reused.at(j) && sameElement(old.at(j), current.at(j), arr.at(i))) {
                match = j;
                update = true;
            }
        }

        if (match < 0) {
            appendItem(arr.at(i));
            continue;
        }

        reused[match] = true;

        if (update)
            old.at(match)->loadFromJsonQuietly(arr.at(i));

        m_items.append(old.at(match));
    }

    for (int i = 0; i < old.size(); ++i)
        if (!reused.at(i))
            destroyItem(old.at(i));

    if (m_items.size() != old.size())
        emit countChanged();

    emit valuesChanged();

    notifyChanged();
}

bool ConfigList::sameElement(const ConfigObject* item, const QJsonValue& current, const QJsonValue& json) {
    const auto keys = item->identityKeys();
    if (keys.isEmpty())
        return false;

    const auto currentObj = current.toObject();
    const auto newObj = json.toObject();

    if (currentObj.keys() != newObj.keys())
        return false;

    for (const auto& key : keys)
        if (!newObj.contains(key) || currentObj.value(key) != newObj.value(key))
            return false;

    return true;
}

void ConfigList::appendItem(const QJsonValue& json) {
    auto* const item = createItem();
    QQmlEngine::setObjectOwnership(item, QQmlEngine::CppOwnership);

    if (m_items.isEmpty())
        rejectGlobalOnlyElement(item);

    item->loadFromJsonQuietly(json);

    connectItem(item);

    m_items.append(item);
}

void ConfigList::rejectGlobalOnlyElement(const ConfigObject* item) const {

    const auto keys = item->globalOnlyKeys();
    if (keys.isEmpty())
        return;

    qCCritical(lcConfig,
        "%s declares global-only options (%s) which do not work inside a list, use CONFIG_GLOBAL_LIST on %s instead",
        item->metaObject()->className(), qUtf8Printable(keys.join(u", "_s)), metaObject()->className());
}

void ConfigList::connectItem(ConfigNode* node) {

    connect(node, &ConfigNode::propertiesChanged, this, &ConfigList::onItemChanged);

    const auto children = node->childNodes();
    for (auto* const child : children)
        connectItem(child);
}

void ConfigList::disconnectItem(ConfigNode* node) {
    node->disconnect(this);

    const auto children = node->childNodes();
    for (auto* const child : children)
        disconnectItem(child);
}

void ConfigList::destroyItems() {
    for (auto* const item : std::as_const(m_items))
        destroyItem(item);

    m_items.clear();
}

void ConfigList::destroyItem(ConfigObject* item) {

    disconnectItem(item);
    item->deleteLater();
}

void ConfigList::onItemChanged() {
    setLoaded(true);
    notifyChanged();
}

bool ConfigList::isLoaded() const {
    return m_loaded;
}

void ConfigList::setLoaded(bool loaded) {
    if (m_loaded == loaded)
        return;
    m_loaded = loaded;
    emit loadedChanged();
}

void ConfigList::notifyChanged() {
    notifyPropertyChanged(u"values"_s, count());
}

}
