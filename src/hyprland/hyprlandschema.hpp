#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QVariantList>
#include <QHash>
#include <QQmlEngine>

namespace FlightDeck::Hyprland {

class HyprlandSchema : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int optionCount READ optionCount NOTIFY schemaLoaded)
    Q_PROPERTY(QVariantList groups READ groups NOTIFY schemaLoaded)
    Q_PROPERTY(QVariantList keybindSections READ keybindSections NOTIFY schemaLoaded)
    Q_PROPERTY(QVariantList caelestiaSections READ caelestiaSections NOTIFY schemaLoaded)
    Q_PROPERTY(QVariantList supportedPlugins READ supportedPlugins NOTIFY schemaLoaded)
    Q_PROPERTY(QVariantList installedPlugins READ installedPlugins NOTIFY installedPluginsChanged)

public:
    static HyprlandSchema* instance();
    static HyprlandSchema* create(QQmlEngine* = nullptr, QJSEngine* = nullptr);

    explicit HyprlandSchema(QObject* parent = nullptr);
    ~HyprlandSchema() override = default;

    int optionCount() const;
    QVariantList groups() const;
    QVariantList keybindSections() const;
    QVariantList caelestiaSections() const;
    QVariantList supportedPlugins() const;
    QVariantList installedPlugins() const;

    Q_INVOKABLE bool hasOption(const QString& key) const;
    Q_INVOKABLE QVariantMap getOption(const QString& key) const;
    Q_INVOKABLE QVariant getDefault(const QString& key, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE QString getType(const QString& key) const;
    Q_INVOKABLE QString getDescription(const QString& key) const;
    Q_INVOKABLE QString getLabel(const QString& key) const;
    Q_INVOKABLE double getMin(const QString& key, double fallback = 0.0) const;
    Q_INVOKABLE double getMax(const QString& key, double fallback = 100.0) const;
    Q_INVOKABLE double getStep(const QString& key, double fallback = 1.0) const;
    Q_INVOKABLE QVariantList getChoices(const QString& key) const;
    Q_INVOKABLE QStringList allKeys() const;

    Q_INVOKABLE QString toHyprKey(const QString& key) const;
    Q_INVOKABLE QString toShortKey(const QString& key) const;

    Q_INVOKABLE QVariantMap pluginSchema(const QString& pluginId) const;
    Q_INVOKABLE bool isPluginInstalled(const QString& pluginIdOrName) const;
    Q_INVOKABLE void refreshInstalledPlugins();

    QString serializeToLuaConfig(const QVariantMap& options) const;

signals:
    void schemaLoaded();
    void installedPluginsChanged();

private:
    void loadSchema();
    void buildAliases();

    QVariantMap m_rawCatalog;
    QVariantList m_groups;
    QVariantList m_keybindSections;
    QVariantList m_caelestiaSections;
    QVariantList m_supportedPlugins;
    QVariantList m_installedPlugins;
    QVariantMap m_pluginSchemas;
    QHash<QString, QString> m_aliasToHyprKey;
    QHash<QString, QString> m_hyprKeyToAlias;
};

} // namespace FlightDeck::Hyprland
