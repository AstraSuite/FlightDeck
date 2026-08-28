#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>

namespace Helm::Caelestia {

class AstraHelmWriter : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isDirty READ isDirty NOTIFY dirtyChanged)
    Q_PROPERTY(int dirtyCount READ dirtyCount NOTIFY dirtyChanged)
    Q_PROPERTY(QVariantList monitors READ monitors WRITE setMonitors NOTIFY monitorsChanged)
    Q_PROPERTY(QVariantList windowRules READ windowRules WRITE setWindowRules NOTIFY windowRulesChanged)
    Q_PROPERTY(QVariantList layerRules READ layerRules WRITE setLayerRules NOTIFY layerRulesChanged)
    Q_PROPERTY(QVariantList customBinds READ customBinds WRITE setCustomBinds NOTIFY customBindsChanged)
    Q_PROPERTY(QStringList autostartCommands READ autostartCommands WRITE setAutostartCommands NOTIFY autostartChanged)
    Q_PROPERTY(QVariantMap pluginConfigs READ pluginConfigs WRITE setPluginConfigs NOTIFY pluginsChanged)

public:
    static AstraHelmWriter* instance();
    static AstraHelmWriter* create(QQmlEngine*, QJSEngine*);

    explicit AstraHelmWriter(QObject* parent = nullptr);

    static QString astraHelmFilePath();

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

    QVariantMap pluginConfigs() const;
    void setPluginConfigs(const QVariantMap& plugins);

    // Manipulation helper methods
    Q_INVOKABLE void addWindowRule(const QVariantMap& rule);
    Q_INVOKABLE void removeWindowRule(int index);
    Q_INVOKABLE void updateWindowRule(int index, const QVariantMap& rule);

    Q_INVOKABLE void addLayerRule(const QVariantMap& rule);
    Q_INVOKABLE void removeLayerRule(int index);

    Q_INVOKABLE void addAutostart(const QString& cmd);
    Q_INVOKABLE void removeAutostart(int index);
    Q_INVOKABLE void updateAutostart(int index, const QString& cmd);

    Q_INVOKABLE void addCustomBind(const QString& key, const QString& dispatcher, const QString& args, bool isUnbindFirst = true);
    Q_INVOKABLE void removeCustomBind(int index);
    Q_INVOKABLE void updateCustomBind(int index, const QVariantMap& bindMap);

    Q_INVOKABLE void setMonitorConfig(const QString& output, const QString& mode, const QString& position, qreal scale, int transform = 0, bool disabled = false);

    // Query active Hyprland compositor state
    Q_INVOKABLE QVariantList activeHyprlandWindowRules() const;
    Q_INVOKABLE QVariantList activeHyprlandClients() const;
    Q_INVOKABLE QVariantList activeHyprlandLayers() const;

    Q_INVOKABLE bool save();
    Q_INVOKABLE void reload();
    Q_INVOKABLE void discard();

signals:
    void dirtyChanged();
    void monitorsChanged();
    void windowRulesChanged();
    void layerRulesChanged();
    void customBindsChanged();
    void autostartChanged();
    void pluginsChanged();
    void saveSucceeded();
    void saveFailed(const QString& error);

private:
    void loadFromFile();
    QString formatLua() const;

    bool m_isDirty = false;
    QVariantList m_monitors;
    QVariantList m_windowRules;
    QVariantList m_layerRules;
    QVariantList m_customBinds;
    QStringList m_autostartCommands;
    QVariantMap m_pluginConfigs;
};

} // namespace Helm::Caelestia
