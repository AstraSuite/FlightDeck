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

public:
    static HyprlandSchema* instance();
    static HyprlandSchema* create(QQmlEngine* = nullptr, QJSEngine* = nullptr);

    explicit HyprlandSchema(QObject* parent = nullptr);
    ~HyprlandSchema() override = default;

    int optionCount() const;
    QVariantList groups() const;

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

    QString serializeToLuaConfig(const QVariantMap& options) const;

signals:
    void schemaLoaded();

private:
    void loadSchema();
    void buildAliases();

    QVariantMap m_rawCatalog;
    QVariantList m_groups;
    QHash<QString, QString> m_aliasToHyprKey;
    QHash<QString, QString> m_hyprKeyToAlias;
};

} // namespace FlightDeck::Hyprland
