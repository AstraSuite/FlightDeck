#include "hyprpmmanager.hpp"
#include "../hyprland/hyprlandschema.hpp"
#include <QRegularExpression>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QFileInfo>
#include <QFile>
#include <QTextStream>
#include <QProcessEnvironment>
#include <unistd.h>
#include <sys/types.h>
#include <algorithm>

namespace FlightDeck::Managers {

HyprpmManager* HyprpmManager::instance() {
    static HyprpmManager inst;
    return &inst;
}

HyprpmManager* HyprpmManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

HyprpmManager::HyprpmManager(QObject* parent)
    : QObject(parent)
    , m_process(new QProcess(this)) {

    connect(m_process, &QProcess::readyReadStandardOutput, this, &HyprpmManager::onProcessReadyReadStandardOutput);
    connect(m_process, &QProcess::readyReadStandardError, this, &HyprpmManager::onProcessReadyReadStandardError);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &HyprpmManager::onProcessFinished);

    refresh();
}

HyprpmManager::~HyprpmManager() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(500);
    }
}

bool HyprpmManager::isBusy() const {
    return m_isBusy;
}

QString HyprpmManager::statusMessage() const {
    return m_statusMessage;
}

QString HyprpmManager::logOutput() const {
    return m_logOutput;
}

QVariantList HyprpmManager::allPlugins() const {
    return m_allPlugins;
}

QVariantList HyprpmManager::installedPlugins() const {
    return m_installedPlugins;
}

QVariantList HyprpmManager::availablePlugins() const {
    return m_availablePlugins;
}

int HyprpmManager::installedCount() const {
    return m_installedPlugins.size();
}

int HyprpmManager::availableCount() const {
    return m_availablePlugins.size();
}

bool HyprpmManager::hasCorruptedPermissions() const {
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/hyprpm");
    QFileInfo dirInfo(dataDir);
    if (!dirInfo.exists()) return false;

    if (dirInfo.ownerId() == 0 || !dirInfo.isWritable()) return true;

    QFileInfo stateInfo(dataDir + QStringLiteral("/state.toml"));
    if (stateInfo.exists() && (stateInfo.ownerId() == 0 || !stateInfo.isWritable())) {
        return true;
    }

    return false;
}

static QString stripAnsiCodes(const QString& str) {
    static const QRegularExpression ansiRegex(QStringLiteral(R"(\x1B\[[0-9;]*[a-zA-Z])"));
    return QString(str).remove(ansiRegex);
}

QList<PluginRepoInfo> HyprpmManager::parseHyprpmList(const QString& text) {
    QList<PluginRepoInfo> list;
    const QString cleanText = stripAnsiCodes(text);
    const QStringList lines = cleanText.split(QLatin1Char('\n'));

    PluginRepoInfo currentRepo;
    bool inRepo = false;

    // Matches: "Repository HyprGlass (by hyprnux):" or "Repository dynamic-cursors (by virtcode):" or "Repository https://github.com/...:"
    static const QRegularExpression repoRegex(QStringLiteral(R"(Repository\s+([^\s(:]+)(?:\s+\(by\s+([^)]+)\))?)"));
    static const QRegularExpression pluginRegex(QStringLiteral(R"(Plugin\s+([^\s]+))"));
    static const QRegularExpression enabledRegex(QStringLiteral(R"(enabled:\s*(true|false))"), QRegularExpression::CaseInsensitiveOption);

    for (const QString& line : lines) {
        QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;

        QRegularExpressionMatch matchRepo = repoRegex.match(trimmed);
        if (matchRepo.hasMatch()) {
            if (inRepo && !currentRepo.name.isEmpty()) {
                list.append(currentRepo);
            }
            currentRepo = PluginRepoInfo();
            inRepo = true;
            QString repoNameOrUrl = matchRepo.captured(1);
            currentRepo.repoUrl = repoNameOrUrl;
            currentRepo.author = matchRepo.captured(2);
            if (repoNameOrUrl.contains(QLatin1Char('/'))) {
                QStringList parts = repoNameOrUrl.split(QLatin1Char('/'));
                currentRepo.name = parts.last().remove(QStringLiteral(".git"));
            } else {
                currentRepo.name = repoNameOrUrl;
            }
            currentRepo.installed = true;
            continue;
        }

        QRegularExpressionMatch matchPlugin = pluginRegex.match(trimmed);
        if (matchPlugin.hasMatch() && inRepo) {
            currentRepo.name = matchPlugin.captured(1);
            continue;
        }

        QRegularExpressionMatch matchEnabled = enabledRegex.match(trimmed);
        if (matchEnabled.hasMatch() && inRepo) {
            currentRepo.enabled = (matchEnabled.captured(1).compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0);
            continue;
        }
    }

    if (inRepo && !currentRepo.name.isEmpty()) {
        list.append(currentRepo);
    }

    return list;
}

void HyprpmManager::refresh() {
    // 1. Run `hyprpm list`
    QProcess proc;
    proc.start(QStringLiteral("hyprpm"), {QStringLiteral("list")});
    proc.waitForFinished(3000);
    const QString listOutput = QString::fromUtf8(proc.readAllStandardOutput());

    const QList<PluginRepoInfo> installedList = parseHyprpmList(listOutput);
    QSet<QString> processedInstalled;

    m_allPlugins.clear();
    m_installedPlugins.clear();
    m_availablePlugins.clear();

    auto schema = Hyprland::HyprlandSchema::instance();
    const QVariantList catalog = schema->supportedPlugins();

    for (const auto& catVal : catalog) {
        QVariantMap p = catVal.toMap();
        const QString pId = p.value(QStringLiteral("id")).toString();
        const QString pName = p.value(QStringLiteral("name")).toString();
        const QString pRepo = p.value(QStringLiteral("repository")).toString();

        bool isInstalled = false;
        bool isEnabled = false;

        for (const auto& inst : installedList) {
            if (inst.name.compare(pId, Qt::CaseInsensitive) == 0 ||
                inst.name.compare(pName, Qt::CaseInsensitive) == 0 ||
                (!pRepo.isEmpty() && inst.repoUrl.contains(pName, Qt::CaseInsensitive)) ||
                (pId == QStringLiteral("hypr-dynamic-cursors") && inst.name.compare(QStringLiteral("dynamic-cursors"), Qt::CaseInsensitive) == 0)) {
                isInstalled = true;
                isEnabled = inst.enabled;
                processedInstalled.insert(inst.name.toLower());
                break;
            }
        }

        p[QStringLiteral("isInstalled")] = isInstalled;
        p[QStringLiteral("isEnabled")] = isEnabled;
        p[QStringLiteral("statusText")] = isInstalled ? (isEnabled ? QStringLiteral("Enabled") : QStringLiteral("Disabled")) : QStringLiteral("Available");

        m_allPlugins.append(p);
        if (isInstalled) {
            m_installedPlugins.append(p);
        } else {
            m_availablePlugins.append(p);
        }
    }

    // Include custom installed plugins that aren't in FlightDeck curated catalog
    for (const auto& inst : installedList) {
        if (!processedInstalled.contains(inst.name.toLower())) {
            QVariantMap customPlugin{
                { QStringLiteral("id"), inst.name },
                { QStringLiteral("name"), inst.name },
                { QStringLiteral("label"), inst.name },
                { QStringLiteral("author"), inst.author.isEmpty() ? QStringLiteral("Custom") : inst.author },
                { QStringLiteral("description"), QStringLiteral("Custom plugin installed via hyprpm repository: ") + inst.repoUrl },
                { QStringLiteral("repository"), inst.repoUrl },
                { QStringLiteral("icon"), QStringLiteral("extension") },
                { QStringLiteral("isInstalled"), true },
                { QStringLiteral("isEnabled"), inst.enabled },
                { QStringLiteral("isCustom"), true },
                { QStringLiteral("statusText"), inst.enabled ? QStringLiteral("Enabled") : QStringLiteral("Disabled") }
            };

            m_allPlugins.append(customPlugin);
            m_installedPlugins.append(customPlugin);
        }
    }

    emit pluginsChanged();
}

void HyprpmManager::appendLog(const QString& line) {
    m_logOutput.append(line + QLatin1Char('\n'));
    emit logLineReceived(line);
    emit logOutputChanged();
}

void HyprpmManager::clearLogs() {
    m_logOutput.clear();
    emit logOutputChanged();
}

void HyprpmManager::runCommand(const QString& program, const QStringList& args, const QString& description, bool requiresElevation) {
    if (m_isBusy) {
        appendLog(QStringLiteral("⚠️ Error: Another operation is currently in progress."));
        return;
    }

    m_isBusy = true;
    m_statusMessage = description;
    m_currentOperation = description;
    emit busyChanged();
    emit statusChanged();

    bool elevate = requiresElevation && program != QStringLiteral("hyprpm");
    appendLog(QStringLiteral("=== Running: %1 %2 ===").arg(elevate ? QStringLiteral("pkexec ") + program : program, args.join(QLatin1Char(' '))));

    if (elevate) {
        QStringList pkexecArgs;
        pkexecArgs.append(program);
        pkexecArgs.append(args);
        m_process->start(QStringLiteral("pkexec"), pkexecArgs);
    } else {
        m_process->start(program, args);
    }
}

void HyprpmManager::installPlugin(const QString& repoUrl, const QString& gitRev) {
    if (repoUrl.trimmed().isEmpty()) return;

    QStringList args;
    args << QStringLiteral("add") << repoUrl.trimmed();
    if (!gitRev.trimmed().isEmpty()) {
        args << gitRev.trimmed();
    }

    runCommand(QStringLiteral("hyprpm"), args, QStringLiteral("Installing plugin repository: %1").arg(repoUrl), false);
}

void HyprpmManager::enablePlugin(const QString& pluginName) {
    if (pluginName.trimmed().isEmpty()) return;
    runCommand(QStringLiteral("hyprpm"), {QStringLiteral("enable"), pluginName.trimmed(), QStringLiteral("-n")}, QStringLiteral("Enabling plugin: %1").arg(pluginName), false);
}

void HyprpmManager::disablePlugin(const QString& pluginName) {
    if (pluginName.trimmed().isEmpty()) return;
    runCommand(QStringLiteral("hyprpm"), {QStringLiteral("disable"), pluginName.trimmed(), QStringLiteral("-n")}, QStringLiteral("Disabling plugin: %1").arg(pluginName), false);
}

void HyprpmManager::removePlugin(const QString& pluginNameOrUrl) {
    if (pluginNameOrUrl.trimmed().isEmpty()) return;
    runCommand(QStringLiteral("hyprpm"), {QStringLiteral("remove"), pluginNameOrUrl.trimmed()}, QStringLiteral("Removing plugin repository: %1").arg(pluginNameOrUrl), false);
}

void HyprpmManager::updateAll(bool usePkexec) {
    Q_UNUSED(usePkexec);
    // hyprpm must never be run directly with pkexec. Instead, run unprivileged with SUDO_ASKPASS
    // in the environment so hyprpm's internal sudo headers acquisition works without corrupting state permissions.
    runCommand(QStringLiteral("hyprpm"), {QStringLiteral("update"), QStringLiteral("-n")}, QStringLiteral("Updating and compiling all plugins..."), false);
}

void HyprpmManager::updateInTerminal() {
    QString terminal = qEnvironmentVariable("TERMINAL");
    const QStringList candidates = {
        QStringLiteral("foot"),
        QStringLiteral("kitty"),
        QStringLiteral("alacritty"),
        QStringLiteral("ghostty"),
        QStringLiteral("wezterm"),
        QStringLiteral("gnome-terminal"),
        QStringLiteral("konsole"),
        QStringLiteral("xfce4-terminal"),
        QStringLiteral("xterm")
    };

    QString chosenTerm;
    if (!terminal.isEmpty() && !QStandardPaths::findExecutable(terminal).isEmpty()) {
        chosenTerm = terminal;
    } else {
        for (const auto& c : candidates) {
            QString exe = QStandardPaths::findExecutable(c);
            if (!exe.isEmpty()) {
                chosenTerm = exe;
                break;
            }
        }
    }

    if (chosenTerm.isEmpty()) {
        appendLog(QStringLiteral("⚠️ Error: No supported terminal emulator found to launch hyprpm update."));
        return;
    }

    appendLog(QStringLiteral("=== Launching hyprpm update in terminal (%1) ===").arg(chosenTerm));
    const QString script = QStringLiteral("hyprpm update; echo; read -n 1 -s -r -p 'Press any key to close...'");
    QProcess::startDetached(chosenTerm, { QStringLiteral("-e"), QStringLiteral("sh"), QStringLiteral("-c"), script });
}

void HyprpmManager::repairPermissions() {
    if (m_isBusy) return;

    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/hyprpm");
    uid_t uid = getuid();
    gid_t gid = getgid();

    appendLog(QStringLiteral("=== Attempting to repair permissions on %1 ===").arg(dataDir));

    QProcess proc;
    QStringList args;
    args << QStringLiteral("chown") << QStringLiteral("-R")
         << QStringLiteral("%1:%2").arg(uid).arg(gid)
         << dataDir;

    proc.start(QStringLiteral("pkexec"), args);
    proc.waitForFinished(15000);

    if (proc.exitCode() == 0) {
        appendLog(QStringLiteral("✔ Permissions successfully repaired."));
    } else {
        const QString err = QString::fromUtf8(proc.readAllStandardError());
        appendLog(QStringLiteral("✖ Failed to repair permissions: %1").arg(err));
    }

    emit permissionsChanged();
    refresh();
}

void HyprpmManager::reloadPlugins() {
    runCommand(QStringLiteral("hyprpm"), {QStringLiteral("reload"), QStringLiteral("-n")}, QStringLiteral("Reloading active Hyprland plugins..."), false);
}

void HyprpmManager::cancelCurrentOperation() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        appendLog(QStringLiteral("⏹ Terminating current operation..."));
        m_process->kill();
    }
}

void HyprpmManager::onProcessReadyReadStandardOutput() {
    const QString text = QString::fromUtf8(m_process->readAllStandardOutput());
    for (const QString& line : text.split(QLatin1Char('\n'))) {
        if (!line.trimmed().isEmpty()) {
            appendLog(line);
        }
    }
}

void HyprpmManager::onProcessReadyReadStandardError() {
    const QString text = QString::fromUtf8(m_process->readAllStandardError());
    for (const QString& line : text.split(QLatin1Char('\n'))) {
        if (!line.trimmed().isEmpty()) {
            appendLog(line);
        }
    }
}

void HyprpmManager::onProcessFinished(int exitCode, QProcess::ExitStatus) {
    m_isBusy = false;
    emit busyChanged();

    bool success = (exitCode == 0);
    QString msg = success ? QStringLiteral("Operation completed successfully.") : QStringLiteral("Operation failed with exit code %1.").arg(exitCode);
    appendLog(QStringLiteral("=== %1 ===").arg(msg));

    m_statusMessage = msg;
    emit statusChanged();

    refresh();
    emit permissionsChanged();
    emit operationFinished(success, msg);
}

} // namespace FlightDeck::Managers
