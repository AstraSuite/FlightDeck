#include "diagnosticsmanager.hpp"
#include "keybindvalidator.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../hyprland/hyprlandstate.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../caelestia/flightdeckwriter.hpp"
#include "../caelestia/luavalidator.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QElapsedTimer>
#include <QRegularExpression>

namespace FlightDeck::Managers {

DiagnosticsManager* DiagnosticsManager::instance() {
    static DiagnosticsManager inst;
    return &inst;
}

DiagnosticsManager* DiagnosticsManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

DiagnosticsManager::DiagnosticsManager(QObject* parent)
    : QObject(parent) {
    runAllChecks();
}

QVariantList DiagnosticsManager::results() const {
    return m_results;
}

bool DiagnosticsManager::isRunning() const {
    return m_isRunning;
}

int DiagnosticsManager::passCount() const {
    return m_passCount;
}

int DiagnosticsManager::warningCount() const {
    return m_warningCount;
}

int DiagnosticsManager::errorCount() const {
    return m_errorCount;
}

void DiagnosticsManager::runAllChecks() {
    m_isRunning = true;
    emit isRunningChanged();

    QVariantList list;
    m_passCount = 0;
    m_warningCount = 0;
    m_errorCount = 0;

    checkCompositor(list);
    checkGraphicsAndEnvironment(list);
    checkDotfilesAndSyntax(list);
    checkServicesAndDaemons(list);
    checkKeybinds(list);

    for (const auto& item : list) {
        QString status = item.toMap().value(QStringLiteral("status")).toString();
        if (status == QStringLiteral("pass")) {
            m_passCount++;
        } else if (status == QStringLiteral("warning")) {
            m_warningCount++;
        } else if (status == QStringLiteral("error")) {
            m_errorCount++;
        }
    }

    m_results = list;
    m_isRunning = false;
    emit isRunningChanged();
    emit resultsChanged();
}

void DiagnosticsManager::checkCompositor(QVariantList& list) {
    bool online = Hyprland::HyprlandSocket::isOnline();
    if (online) {
        QElapsedTimer timer;
        timer.start();
        QString versionResp = Hyprland::HyprlandSocket::instance()->send(QStringLiteral("version"));
        qint64 latencyUs = timer.nsecsElapsed() / 1000;

        QString tag = Hyprland::HyprlandState::instance()->version();
        QVariantMap item;
        item[QStringLiteral("id")] = QStringLiteral("hyprland_socket");
        item[QStringLiteral("category")] = QStringLiteral("Compositor");
        item[QStringLiteral("title")] = QStringLiteral("Hyprland IPC Socket");
        item[QStringLiteral("status")] = QStringLiteral("pass");
        item[QStringLiteral("message")] = QStringLiteral("Connected to Hyprland (%1) via UNIX socket (%2 µs)").arg(tag).arg(latencyUs);
        item[QStringLiteral("detail")] = QStringLiteral("Socket Path: %1").arg(Hyprland::HyprlandSocket::commandSocketPath());
        item[QStringLiteral("suggestedFix")] = QString();
        list.append(item);
    } else {
        QVariantMap item;
        item[QStringLiteral("id")] = QStringLiteral("hyprland_socket");
        item[QStringLiteral("category")] = QStringLiteral("Compositor");
        item[QStringLiteral("title")] = QStringLiteral("Hyprland IPC Socket");
        item[QStringLiteral("status")] = QStringLiteral("error");
        item[QStringLiteral("message")] = QStringLiteral("Hyprland IPC socket is offline or unreachable.");
        item[QStringLiteral("detail")] = QStringLiteral("HYPRLAND_INSTANCE_SIGNATURE is missing or socket file does not exist.");
        item[QStringLiteral("suggestedFix")] = QStringLiteral("Ensure Hyprland is actively running in this user session.");
        list.append(item);
    }
}

void DiagnosticsManager::checkGraphicsAndEnvironment(QVariantList& list) {
    bool isNvidia = false;
    bool isAmd = false;
    bool isIntel = false;

    // Probe DRM device vendor
    QDir driDir(QStringLiteral("/sys/class/drm"));
    const auto entries = driDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& fi : entries) {
        QFile vendorFile(fi.absoluteFilePath() + QStringLiteral("/device/vendor"));
        if (vendorFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString v = QString::fromUtf8(vendorFile.readAll()).trimmed().toLower();
            if (v == QStringLiteral("0x10de")) isNvidia = true;
            else if (v == QStringLiteral("0x1002")) isAmd = true;
            else if (v == QStringLiteral("0x8086")) isIntel = true;
        }
    }

    QString gpuVendor = isNvidia ? QStringLiteral("NVIDIA") : (isAmd ? QStringLiteral("AMD") : (isIntel ? QStringLiteral("Intel") : QStringLiteral("Generic / Unknown")));

    list.append(QVariantMap{
        { QStringLiteral("id"), QStringLiteral("gpu_vendor") },
        { QStringLiteral("category"), QStringLiteral("Graphics") },
        { QStringLiteral("title"), QStringLiteral("Primary GPU Hardware") },
        { QStringLiteral("status"), QStringLiteral("pass") },
        { QStringLiteral("message"), QStringLiteral("Detected GPU architecture: %1").arg(gpuVendor) },
        { QStringLiteral("detail"), QString() },
        { QStringLiteral("suggestedFix"), QString() }
    });

    if (isNvidia) {
        QString gbm = qEnvironmentVariable("GBM_BACKEND");
        QString libva = qEnvironmentVariable("LIBVA_DRIVER_NAME");
        QString glx = qEnvironmentVariable("__GLX_VENDOR_LIBRARY_NAME");

        if (gbm != QStringLiteral("nvidia-drm") && !gbm.isEmpty()) {
            list.append(QVariantMap{
                { QStringLiteral("id"), QStringLiteral("nvidia_gbm") },
                { QStringLiteral("category"), QStringLiteral("Graphics") },
                { QStringLiteral("title"), QStringLiteral("GBM Backend Variable") },
                { QStringLiteral("status"), QStringLiteral("warning") },
                { QStringLiteral("message"), QStringLiteral("GBM_BACKEND is '%1' (expected 'nvidia-drm')").arg(gbm) },
                { QStringLiteral("detail"), QStringLiteral("May cause stutter or hardware cursor artifacts on proprietary NVIDIA drivers.") },
                { QStringLiteral("suggestedFix"), QStringLiteral("Set 'export GBM_BACKEND=nvidia-drm' in ~/.config/hypr/hyprland.conf or /etc/environment") }
            });
        }

        if (libva != QStringLiteral("nvidia") && !libva.isEmpty()) {
            list.append(QVariantMap{
                { QStringLiteral("id"), QStringLiteral("nvidia_libva") },
                { QStringLiteral("category"), QStringLiteral("Graphics") },
                { QStringLiteral("title"), QStringLiteral("Hardware Video Acceleration") },
                { QStringLiteral("status"), QStringLiteral("warning") },
                { QStringLiteral("message"), QStringLiteral("LIBVA_DRIVER_NAME is '%1' (recommended 'nvidia')").arg(libva) },
                { QStringLiteral("detail"), QStringLiteral("Required for NVDEC/VA-API hardware acceleration in browsers.") },
                { QStringLiteral("suggestedFix"), QStringLiteral("Set 'export LIBVA_DRIVER_NAME=nvidia' in your session environment") }
            });
        }
    }
}

void DiagnosticsManager::checkDotfilesAndSyntax(QVariantList& list) {
    const QString varsPath = Caelestia::CaelestiaVars::varsFilePath();
    if (!QFile::exists(varsPath)) {
        list.append(QVariantMap{
            { QStringLiteral("id"), QStringLiteral("vars_missing") },
            { QStringLiteral("category"), QStringLiteral("Configuration") },
            { QStringLiteral("title"), QStringLiteral("Caelestia Variables File") },
            { QStringLiteral("status"), QStringLiteral("warning") },
            { QStringLiteral("message"), QStringLiteral("File not found: %1").arg(varsPath) },
            { QStringLiteral("detail"), QStringLiteral("FlightDeck will generate default settings when saving.") },
            { QStringLiteral("suggestedFix"), QStringLiteral("Save any setting in FlightDeck to scaffold hypr-vars.lua automatically.") }
        });
    } else {
        QString errStr;
        bool ok = Caelestia::LuaValidator::validateFile(varsPath, &errStr);
        if (ok) {
            QVariantMap item;
            item[QStringLiteral("id")] = QStringLiteral("vars_syntax");
            item[QStringLiteral("category")] = QStringLiteral("Configuration");
            item[QStringLiteral("title")] = QStringLiteral("hypr-vars.lua Syntax");
            item[QStringLiteral("status")] = QStringLiteral("pass");
            item[QStringLiteral("message")] = QStringLiteral("Lua syntax is clean and valid.");
            item[QStringLiteral("detail")] = varsPath;
            item[QStringLiteral("suggestedFix")] = QString();
            list.append(item);
        } else {
            QVariantMap item;
            item[QStringLiteral("id")] = QStringLiteral("vars_syntax");
            item[QStringLiteral("category")] = QStringLiteral("Configuration");
            item[QStringLiteral("title")] = QStringLiteral("hypr-vars.lua Syntax Error");
            item[QStringLiteral("status")] = QStringLiteral("error");
            item[QStringLiteral("message")] = QStringLiteral("Lua syntax error: %1").arg(errStr);
            item[QStringLiteral("detail")] = varsPath;
            item[QStringLiteral("suggestedFix")] = QStringLiteral("Review the file syntax or restore a snapshot from the Profiles page.");
            list.append(item);
        }
    }

    const QString deckPath = Caelestia::FlightDeckWriter::flightDeckFilePath();
    if (QFile::exists(deckPath)) {
        QString errStr;
        bool ok = Caelestia::LuaValidator::validateFile(deckPath, &errStr);
        if (!ok) {
            QVariantMap item;
            item[QStringLiteral("id")] = QStringLiteral("flightdeck_syntax");
            item[QStringLiteral("category")] = QStringLiteral("Configuration");
            item[QStringLiteral("title")] = QStringLiteral("astra-flightdeck.lua Syntax Error");
            item[QStringLiteral("status")] = QStringLiteral("error");
            item[QStringLiteral("message")] = QStringLiteral("Lua syntax error: %1").arg(errStr);
            item[QStringLiteral("detail")] = deckPath;
            item[QStringLiteral("suggestedFix")] = QStringLiteral("Inspect custom rules or restore backup.");
            list.append(item);
        }
    }

    const QString schemePath = QDir::homePath() + QStringLiteral("/.local/state/caelestia/scheme.json");
    if (QFile::exists(schemePath)) {
        QFile sf(schemePath);
        if (sf.open(QIODevice::ReadOnly)) {
            QJsonParseError err;
            QJsonDocument::fromJson(sf.readAll(), &err);
            if (err.error == QJsonParseError::NoError) {
                list.append(QVariantMap{
                    { QStringLiteral("id"), QStringLiteral("scheme_json") },
                    { QStringLiteral("category"), QStringLiteral("Configuration") },
                    { QStringLiteral("title"), QStringLiteral("Caelestia Color Scheme") },
                    { QStringLiteral("status"), QStringLiteral("pass") },
                    { QStringLiteral("message"), QStringLiteral("Active scheme.json is valid and synchronized.") },
                    { QStringLiteral("detail"), schemePath },
                    { QStringLiteral("suggestedFix"), QString() }
                });
            } else {
                list.append(QVariantMap{
                    { QStringLiteral("id"), QStringLiteral("scheme_json") },
                    { QStringLiteral("category"), QStringLiteral("Configuration") },
                    { QStringLiteral("title"), QStringLiteral("Invalid scheme.json") },
                    { QStringLiteral("status"), QStringLiteral("warning") },
                    { QStringLiteral("message"), QStringLiteral("JSON parsing error: %1").arg(err.errorString()) },
                    { QStringLiteral("detail"), schemePath },
                    { QStringLiteral("suggestedFix"), QStringLiteral("Regenerate scheme via 'caelestia-cli scheme set' or wallpaper selector.") }
                });
            }
        }
    }
}

void DiagnosticsManager::checkServicesAndDaemons(QVariantList& list) {
    QProcess ps;
    ps.start(QStringLiteral("ps"), QStringList() << QStringLiteral("-u") << QString::fromLocal8Bit(qgetenv("USER")) << QStringLiteral("-o") << QStringLiteral("comm="));
    if (ps.waitForFinished(1000)) {
        QString out = QString::fromUtf8(ps.readAllStandardOutput());
        QStringList procs = out.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

        // Check notification daemons
        QStringList notifDaemons = { QStringLiteral("dunst"), QStringLiteral("mako"), QStringLiteral("swaync"), QStringLiteral("fnott"), QStringLiteral("sway-notification-center") };
        QStringList activeNotifs;
        for (const auto& d : notifDaemons) {
            if (procs.contains(d)) activeNotifs.append(d);
        }

        if (activeNotifs.size() > 1) {
            list.append(QVariantMap{
                { QStringLiteral("id"), QStringLiteral("multiple_notif_daemons") },
                { QStringLiteral("category"), QStringLiteral("Services") },
                { QStringLiteral("title"), QStringLiteral("Multiple Notification Daemons") },
                { QStringLiteral("status"), QStringLiteral("warning") },
                { QStringLiteral("message"), QStringLiteral("Found multiple notification services running: %1").arg(activeNotifs.join(QStringLiteral(", "))) },
                { QStringLiteral("detail"), QStringLiteral("Concurrent notification servers can cause race conditions or duplicate notifications.") },
                { QStringLiteral("suggestedFix"), QStringLiteral("Disable redundant notification daemons in ~/.config/hypr/hyprland.conf or systemd.") }
            });
        }

        // Check wallpaper daemons
        QStringList wallDaemons = { QStringLiteral("hyprpaper"), QStringLiteral("swww-daemon"), QStringLiteral("mpvpaper"), QStringLiteral("swaybg") };
        QStringList activeWalls;
        for (const auto& w : wallDaemons) {
            if (procs.contains(w)) activeWalls.append(w);
        }

        if (activeWalls.size() > 1) {
            list.append(QVariantMap{
                { QStringLiteral("id"), QStringLiteral("multiple_wall_daemons") },
                { QStringLiteral("category"), QStringLiteral("Services") },
                { QStringLiteral("title"), QStringLiteral("Multiple Wallpaper Daemons") },
                { QStringLiteral("status"), QStringLiteral("warning") },
                { QStringLiteral("message"), QStringLiteral("Found multiple wallpaper engines running: %1").arg(activeWalls.join(QStringLiteral(", "))) },
                { QStringLiteral("detail"), QStringLiteral("Running multiple wallpaper renderers wastes GPU memory.") },
                { QStringLiteral("suggestedFix"), QStringLiteral("Keep only one wallpaper engine active in autostart.") }
            });
        }
    }
}

void DiagnosticsManager::checkKeybinds(QVariantList& list) {
    auto kv = KeybindValidator::instance();
    kv->refresh();

    int trueConflicts = kv->trueConflictCount();
    int overrides = kv->overrideCount();

    if (trueConflicts == 0) {
        QString msg = overrides > 0 
            ? QStringLiteral("All bindings valid (%1 custom overrides active).").arg(overrides)
            : QStringLiteral("No duplicate or colliding key shortcuts detected.");
        list.append(QVariantMap{
            { QStringLiteral("id"), QStringLiteral("keybind_conflicts") },
            { QStringLiteral("category"), QStringLiteral("Keybinds") },
            { QStringLiteral("title"), QStringLiteral("Keybinding Matrix") },
            { QStringLiteral("status"), QStringLiteral("pass") },
            { QStringLiteral("message"), msg },
            { QStringLiteral("detail"), QStringLiteral("Custom bindings cleanly unbind default shortcuts before registering.") },
            { QStringLiteral("suggestedFix"), QString() }
        });
    } else {
        list.append(QVariantMap{
            { QStringLiteral("id"), QStringLiteral("keybind_conflicts") },
            { QStringLiteral("category"), QStringLiteral("Keybinds") },
            { QStringLiteral("title"), QStringLiteral("Keybinding Collisions") },
            { QStringLiteral("status"), QStringLiteral("warning") },
            { QStringLiteral("message"), QStringLiteral("Found %1 unresolvable key combination collision(s)").arg(trueConflicts) },
            { QStringLiteral("detail"), QStringLiteral("Multiple custom actions or system variables are competing on the same chord without an unbind.") },
            { QStringLiteral("suggestedFix"), QStringLiteral("Open the Keybinds page or run 'flightdeck bind --conflicts' to resolve duplicate shortcuts.") }
        });
    }
}

} // namespace FlightDeck::Managers
