#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVariantList>
#include <QQmlEngine>

namespace FlightDeck::Caelestia {

class CaelestiaVars : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isDirty READ isDirty NOTIFY dirtyChanged)
    Q_PROPERTY(int dirtyCount READ dirtyCount NOTIFY dirtyChanged)
    Q_PROPERTY(QStringList pendingKeys READ pendingKeys NOTIFY pendingChanged)
    Q_PROPERTY(QVariantMap currentVars READ currentVars NOTIFY varsChanged)
    Q_PROPERTY(QVariantMap pendingVars READ pendingVars NOTIFY pendingChanged)

public:
    static CaelestiaVars* instance();
    static CaelestiaVars* create(QQmlEngine*, QJSEngine*);

    explicit CaelestiaVars(QObject* parent = nullptr);

    static QString varsFilePath();
    static QString defaultVarsFilePath();

    bool isDirty() const;
    int dirtyCount() const;
    QStringList pendingKeys() const;

    QVariantMap currentVars() const;
    QVariantMap pendingVars() const;

    Q_INVOKABLE QVariant get(const QString& key, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE QVariant getDefault(const QString& key, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE bool isOverridden(const QString& key) const;
    Q_INVOKABLE void set(const QString& key, const QVariant& value);
    Q_INVOKABLE void setVar(const QString& key, const QVariant& value);
    Q_INVOKABLE void resetKey(const QString& key);
    Q_INVOKABLE void resetToDefault(const QString& key);
    Q_INVOKABLE void remove(const QString& key);
    Q_INVOKABLE void discardAll();
    Q_INVOKABLE bool save();
    Q_INVOKABLE void reload();
    Q_INVOKABLE void syncFromHyprland();

    // Keybinds convenience methods
    Q_INVOKABLE QStringList getBinds(const QString& key) const;
    Q_INVOKABLE void setBinds(const QString& key, const QStringList& binds);

signals:
    void varsChanged();
    void pendingChanged();
    void dirtyChanged();
    void saveSucceeded();
    void saveFailed(const QString& error);

private:
    void loadDefaults();
    void loadFromFile();
    void applyKeywordToHyprland(const QString& key, const QVariant& value);
    QString formatLua() const;

    QVariantMap m_defaults;
    QVariantMap m_savedVars;
    QVariantMap m_pendingVars;
};

} // namespace FlightDeck::Caelestia
