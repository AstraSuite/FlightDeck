#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
#include <QQmlEngine>
#include <QJSEngine>

namespace FlightDeck::Caelestia {

class FlightDeckWriter : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isDirty READ isDirty NOTIFY dirtyChanged)
    Q_PROPERTY(int dirtyCount READ dirtyCount NOTIFY dirtyChanged)
    Q_PROPERTY(QVariantList monitors READ monitors WRITE setMonitors NOTIFY monitorsChanged)
    Q_PROPERTY(QVariantList windowRules READ windowRules WRITE setWindowRules NOTIFY windowRulesChanged)
    Q_PROPERTY(QVariantList layerRules READ layerRules WRITE setLayerRules NOTIFY layerRulesChanged)
    Q_PROPERTY(QVariantList customBinds READ customBinds WRITE setCustomBinds NOTIFY customBindsChanged)
    Q_PROPERTY(QStringList autostartCommands READ autostartCommands WRITE setAutostartCommands NOTIFY autostartChanged)
    Q_PROPERTY(QVariantList autostartEntries READ autostartEntries WRITE setAutostartEntries NOTIFY autostartChanged)
    Q_PROPERTY(QVariantMap pluginConfigs READ pluginConfigs WRITE setPluginConfigs NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantMap hyprOptions READ hyprOptions WRITE setHyprOptions NOTIFY hyprOptionsChanged)

public:
    static FlightDeckWriter* instance();
    static FlightDeckWriter* create(QQmlEngine* qmlEngine = nullptr, QJSEngine* jsEngine = nullptr);

    explicit FlightDeckWriter(QObject* parent = nullptr);
    ~FlightDeckWriter() override = default;

    bool isDirty() const;
    int dirtyCount() const;

    QVariantList monitors() const;
    void setMonitors(const QVariantList& monitors);

    QVariantList windowRules() const;
    void setWindowRules(const QVariantList& rules);

    QVariantList layerRules() const;
    void setLayerRules(const QVariantList& rules);

    QVariantList customBinds() const;
    void setCustomBinds(const QVariantList& binds);

    QStringList autostartCommands() const;
    void setAutostartCommands(const QStringList& cmds);

    QVariantList autostartEntries() const;
    void setAutostartEntries(const QVariantList& entries);

    QVariantMap pluginConfigs() const;
    void setPluginConfigs(const QVariantMap& plugins);

    QVariantMap hyprOptions() const;
    void setHyprOptions(const QVariantMap& options);

    // QML-invokable mutations
    Q_INVOKABLE void setHyprOption(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariant getHyprOption(const QString& key, const QVariant& fallback = QVariant()) const;
    Q_INVOKABLE bool hasHyprOption(const QString& key) const;
    Q_INVOKABLE void removeHyprOption(const QString& key);

    Q_INVOKABLE void addWindowRule(const QVariantMap& rule);
    Q_INVOKABLE void removeWindowRule(int index);
    Q_INVOKABLE void updateWindowRule(int index, const QVariantMap& rule);

    Q_INVOKABLE void addLayerRule(const QVariantMap& rule);
    Q_INVOKABLE void removeLayerRule(int index);
    Q_INVOKABLE void updateLayerRule(int index, const QVariantMap& rule);

    Q_INVOKABLE void addAutostart(const QString& cmd, bool onReload = false);
    Q_INVOKABLE void removeAutostart(int index);
    Q_INVOKABLE void updateAutostart(int index, const QString& cmd, bool onReload = false);

    Q_INVOKABLE void addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst = true);
    Q_INVOKABLE void removeCustomBind(int index);
    Q_INVOKABLE void updateCustomBind(int index, const QVariantMap& bindMap);

    Q_INVOKABLE void setMonitorConfig(const QString& output, const QString& mode, const QString& position, qreal scale = 1.0, int transform = 0, bool disabled = false);

    Q_INVOKABLE bool save();
    Q_INVOKABLE void reload();
    Q_INVOKABLE void discard();

    Q_INVOKABLE QVariantList activeHyprlandClients() const;
    Q_INVOKABLE QVariantList activeHyprlandWindowRules() const;
    Q_INVOKABLE QVariantList activeHyprlandLayers() const;

    Q_INVOKABLE void applyWindowRuleOverIPC(const QVariantMap& rule);
    Q_INVOKABLE void applyLayerRuleOverIPC(const QVariantMap& rule);

    static QString flightDeckFilePath();
    static QString astraHelmFilePath();
    QString formatLua() const;

signals:
    void dirtyChanged();
    void monitorsChanged();
    void windowRulesChanged();
    void layerRulesChanged();
    void customBindsChanged();
    void autostartChanged();
    void pluginsChanged();
    void hyprOptionsChanged();
    void saveSucceeded();
    void saveFailed(const QString& error);

private:
    void loadFromFile();

    bool m_isDirty = false;
    QVariantList m_monitors;
    QVariantList m_windowRules;
    QVariantList m_layerRules;
    QVariantList m_customBinds;
    QStringList m_autostartCommands;
    QVariantList m_autostartEntries;
    QVariantMap m_pluginConfigs;
    QVariantMap m_hyprOptions;
};

using AstraHelmWriter = FlightDeckWriter;

} // namespace FlightDeck::Caelestia
