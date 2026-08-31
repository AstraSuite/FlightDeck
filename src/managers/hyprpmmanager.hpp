#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
#include <QProcess>
#include <QSet>

namespace FlightDeck::Managers {

struct PluginRepoInfo {
    QString name;
    QString repoUrl;
    QString author;
    bool enabled = false;
    bool installed = false;
};

class HyprpmManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(QString logOutput READ logOutput NOTIFY logOutputChanged)
    Q_PROPERTY(QVariantList allPlugins READ allPlugins NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList installedPlugins READ installedPlugins NOTIFY pluginsChanged)
    Q_PROPERTY(QVariantList availablePlugins READ availablePlugins NOTIFY pluginsChanged)
    Q_PROPERTY(int installedCount READ installedCount NOTIFY pluginsChanged)
    Q_PROPERTY(int availableCount READ availableCount NOTIFY pluginsChanged)

public:
    static HyprpmManager* instance();
    static HyprpmManager* create(QQmlEngine* engine, QJSEngine* scriptEngine);

    explicit HyprpmManager(QObject* parent = nullptr);
    ~HyprpmManager() override;

    bool isBusy() const;
    QString statusMessage() const;
    QString logOutput() const;
    QVariantList allPlugins() const;
    QVariantList installedPlugins() const;
    QVariantList availablePlugins() const;
    int installedCount() const;
    int availableCount() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void installPlugin(const QString& repoUrl, const QString& gitRev = QString());
    Q_INVOKABLE void enablePlugin(const QString& pluginName);
    Q_INVOKABLE void disablePlugin(const QString& pluginName);
    Q_INVOKABLE void removePlugin(const QString& pluginNameOrUrl);
    Q_INVOKABLE void updateAll(bool usePkexec = true);
    Q_INVOKABLE void reloadPlugins();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void cancelCurrentOperation();

    // Helper to parse `hyprpm list` text output
    static QList<PluginRepoInfo> parseHyprpmList(const QString& text);

signals:
    void busyChanged();
    void statusChanged();
    void logOutputChanged();
    void pluginsChanged();
    void logLineReceived(const QString& line);
    void operationFinished(bool success, const QString& message);

private slots:
    void onProcessReadyReadStandardOutput();
    void onProcessReadyReadStandardError();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    void runCommand(const QString& program, const QStringList& args, const QString& description, bool requiresElevation = false);
    void appendLog(const QString& line);

    bool m_isBusy = false;
    QString m_statusMessage;
    QString m_logOutput;
    QProcess* m_process = nullptr;
    QString m_currentOperation;

    QVariantList m_allPlugins;
    QVariantList m_installedPlugins;
    QVariantList m_availablePlugins;
};

} // namespace FlightDeck::Managers
