#include "autostartmanager.hpp"
#include "../caelestia/flightdeckwriter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QSet>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>

namespace FlightDeck::Managers {

AutostartManager* AutostartManager::instance() {
    static AutostartManager inst;
    return &inst;
}

AutostartManager* AutostartManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

AutostartManager::AutostartManager(QObject* parent)
    : QObject(parent) {
    scanApps();
    connect(Caelestia::FlightDeckWriter::instance(), &Caelestia::FlightDeckWriter::autostartChanged, this, &AutostartManager::activeCommandsChanged);
}

QVariantList AutostartManager::availableApps() const {
    return m_apps;
}

QVariantList AutostartManager::activeCommands() const {
    QVariantList list;
    const auto entries = Caelestia::FlightDeckWriter::instance()->autostartEntries();
    for (const auto& entryVal : entries) {
        const QVariantMap entry = entryVal.toMap();
        const QString rawCmd = entry.value(QStringLiteral("command")).toString();
        const bool onReload = entry.value(QStringLiteral("onReload")).toBool();
        const bool isReadOnly = entry.value(QStringLiteral("isReadOnly")).toBool();
        QVariantMap parsed = parseCommand(rawCmd, onReload, isReadOnly);
        list.append(parsed);
    }
    return list;
}

void AutostartManager::toggleApp(const QString& execCmd, bool enabled) {
    if (enabled) {
        Caelestia::FlightDeckWriter::instance()->addAutostart(execCmd, false);
    } else {
        const auto list = activeCommands();
        for (int i = 0; i < list.size(); ++i) {
            QVariantMap item = list[i].toMap();
            if (item.value(QStringLiteral("rawCommand")).toString() == execCmd ||
                item.value(QStringLiteral("command")).toString() == execCmd ||
                item.value(QStringLiteral("cleanCmd")).toString() == execCmd) {
                Caelestia::FlightDeckWriter::instance()->removeAutostart(i);
                break;
            }
        }
    }
}

void AutostartManager::addCustomCommand(const QString& cmd, bool onReload) {
    Caelestia::FlightDeckWriter::instance()->addAutostart(cmd, onReload);
}

void AutostartManager::updateCommand(int index, const QString& cmd, bool onReload) {
    Caelestia::FlightDeckWriter::instance()->updateAutostart(index, cmd, onReload);
}

void AutostartManager::removeCommand(int index) {
    Caelestia::FlightDeckWriter::instance()->removeAutostart(index);
}

QVariantMap AutostartManager::detectMinimizeFlags(const QString& cmdOrBinary) const {
    QVariantMap result;
    QString trimmed = cmdOrBinary.trimmed();
    if (trimmed.isEmpty()) {
        result[QStringLiteral("hasFlag")] = false;
        result[QStringLiteral("flag")] = QStringLiteral("--minimized");
        result[QStringLiteral("cleanCmd")] = QString();
        result[QStringLiteral("minimizedCmd")] = QString();
        return result;
    }

    // Strip leading sleep if any
    static const QRegularExpression sleepRe(QStringLiteral(R"(^sleep\s+\d+(?:\.\d+)?s?\s*&&\s*(.+)$)"));
    auto sleepMatch = sleepRe.match(trimmed);
    if (sleepMatch.hasMatch()) {
        trimmed = sleepMatch.captured(1).trimmed();
    }

    // Extract binary name
    QString binaryName;
    QStringList tokens = trimmed.split(QRegularExpression(QStringLiteral(R"(\s+)")), Qt::SkipEmptyParts);
    if (!tokens.isEmpty()) {
        QString firstToken = tokens.first();
        // remove surrounding quotes if present
        if ((firstToken.startsWith('"') && firstToken.endsWith('"')) ||
            (firstToken.startsWith('\'') && firstToken.endsWith('\''))) {
            firstToken = firstToken.mid(1, firstToken.length() - 2);
        }
        binaryName = QFileInfo(firstToken).fileName().toLower();
    }

    // Known flags ordered by matching priority
    static const struct FlagPattern {
        const char* regexPattern;
        const char* standardFlag;
    } knownPatterns[] = {
        { R"((?:^|\s+)-w\s+hide(?:\s+|$))", "-w hide" },
        { R"((?:^|\s+)--window=hide(?:\s+|$))", "-w hide" },
        { R"((?:^|\s+)--window\s+hide(?:\s+|$))", "-w hide" },
        { R"((?:^|\s+)-w\s+icon(?:\s+|$))", "-w hide" },
        { R"((?:^|\s+)--start-minimized(?:\s+|$))", "--start-minimized" },
        { R"((?:^|\s+)--minimize-to-tray(?:\s+|$))", "--minimize-to-tray" },
        { R"((?:^|\s+)--minimize-systray(?:\s+|$))", "--minimize-systray" },
        { R"((?:^|\s+)-startintray(?:\s+|$))", "-startintray" },
        { R"((?:^|\s+)--minimized(?:\s+|$))", "--minimized" },
        { R"((?:^|\s+)--hidden(?:\s+|$))", "--hidden" },
        { R"((?:^|\s+)--tray(?:\s+|$))", "--tray" },
        { R"((?:^|\s+)-silent(?:\s+|$))", "-silent" },
        { R"((?:^|\s+)--silent(?:\s+|$))", "-silent" },
        { R"((?:^|\s+)--background(?:\s+|$))", "--background" },
        { R"((?:^|\s+)--headless(?:\s+|$))", "--headless" },
        { R"((?:^|\s+)-w(?:\s+|$))", "-w" },
        { R"((?:^|\s+)-b(?:\s+|$))", "-b" },
        { R"((?:^|\s+)-m(?:\s+|$))", "-m" }
    };

    bool hasFlag = false;
    QString detectedExistingFlag;
    QString cleanCmd = trimmed;

    for (const auto& kp : knownPatterns) {
        QRegularExpression re(QString::fromUtf8(kp.regexPattern));
        if (re.match(trimmed).hasMatch()) {
            hasFlag = true;
            detectedExistingFlag = QString::fromUtf8(kp.standardFlag);
            cleanCmd.remove(re);
            cleanCmd = cleanCmd.simplified().trimmed();
            break;
        }
    }

    // Determine target flag for this binary
    QString targetFlag;

    // 1. Static table of known applications
    static const QMap<QString, QString> staticMap = {
        { QStringLiteral("solaar"), QStringLiteral("-w hide") },
        { QStringLiteral("element-desktop"), QStringLiteral("--hidden") },
        { QStringLiteral("element"), QStringLiteral("--hidden") },
        { QStringLiteral("streamcontroller"), QStringLiteral("-b") },
        { QStringLiteral("discord"), QStringLiteral("--start-minimized") },
        { QStringLiteral("vesktop"), QStringLiteral("--start-minimized") },
        { QStringLiteral("webcord"), QStringLiteral("--start-minimized") },
        { QStringLiteral("discord-canary"), QStringLiteral("--start-minimized") },
        { QStringLiteral("discord-ptb"), QStringLiteral("--start-minimized") },
        { QStringLiteral("legcord"), QStringLiteral("--start-minimized") },
        { QStringLiteral("armcord"), QStringLiteral("--start-minimized") },
        { QStringLiteral("equibop"), QStringLiteral("--start-minimized") },
        { QStringLiteral("betterdiscord"), QStringLiteral("--start-minimized") },
        { QStringLiteral("telegram-desktop"), QStringLiteral("-startintray") },
        { QStringLiteral("telegram"), QStringLiteral("-startintray") },
        { QStringLiteral("steam"), QStringLiteral("-silent") },
        { QStringLiteral("birdtray"), QStringLiteral("-m") },
        { QStringLiteral("keepassxc"), QStringLiteral("--minimized") },
        { QStringLiteral("obs"), QStringLiteral("--minimize-to-tray") },
        { QStringLiteral("obs-studio"), QStringLiteral("--minimize-to-tray") },
        { QStringLiteral("transmission-gtk"), QStringLiteral("--minimized") },
        { QStringLiteral("transmission-qt"), QStringLiteral("--minimized") },
        { QStringLiteral("corectrl"), QStringLiteral("--minimize-systray") },
        { QStringLiteral("cmst"), QStringLiteral("-w") },
        { QStringLiteral("nextcloud"), QStringLiteral("--background") },
        { QStringLiteral("thunderbird"), QStringLiteral("--headless") },
        { QStringLiteral("dropbox"), QStringLiteral("--tray") },
        { QStringLiteral("spotify"), QStringLiteral("--minimized") },
        { QStringLiteral("beeper"), QStringLiteral("--start-minimized") },
        { QStringLiteral("rquickshare-x"), QStringLiteral("--minimized") },
        { QStringLiteral("rquickshare"), QStringLiteral("--minimized") }
    };

    if (staticMap.contains(binaryName)) {
        targetFlag = staticMap.value(binaryName);
    } else if (m_minimizeFlagCache.contains(binaryName)) {
        targetFlag = m_minimizeFlagCache.value(binaryName);
    } else if (!binaryName.isEmpty()) {
        // Try probing binary --help with a short timeout
        const QString resolvedPath = QStandardPaths::findExecutable(binaryName);
        if (!resolvedPath.isEmpty()) {
            QProcess proc;
            proc.setProcessChannelMode(QProcess::MergedChannels);
            proc.start(resolvedPath, { QStringLiteral("--help") });
            if (proc.waitForFinished(150)) {
                const QString helpOut = QString::fromUtf8(proc.readAll());
                if (helpOut.contains(QRegularExpression(QStringLiteral(R"(hide\b)"), QRegularExpression::CaseInsensitiveOption)) &&
                    helpOut.contains(QStringLiteral("-w"))) {
                    targetFlag = QStringLiteral("-w hide");
                } else if (helpOut.contains(QStringLiteral("--start-minimized"))) {
                    targetFlag = QStringLiteral("--start-minimized");
                } else if (helpOut.contains(QStringLiteral("--minimize-to-tray"))) {
                    targetFlag = QStringLiteral("--minimize-to-tray");
                } else if (helpOut.contains(QStringLiteral("--minimize-systray"))) {
                    targetFlag = QStringLiteral("--minimize-systray");
                } else if (helpOut.contains(QStringLiteral("-startintray"))) {
                    targetFlag = QStringLiteral("-startintray");
                } else if (helpOut.contains(QStringLiteral("--minimized"))) {
                    targetFlag = QStringLiteral("--minimized");
                } else if (helpOut.contains(QStringLiteral("--hidden"))) {
                    targetFlag = QStringLiteral("--hidden");
                } else if (helpOut.contains(QStringLiteral("--tray"))) {
                    targetFlag = QStringLiteral("--tray");
                } else if (helpOut.contains(QStringLiteral("-silent")) || helpOut.contains(QStringLiteral("--silent"))) {
                    targetFlag = QStringLiteral("-silent");
                } else if (helpOut.contains(QStringLiteral("-b\b")) && helpOut.contains(QStringLiteral("background"), Qt::CaseInsensitive)) {
                    targetFlag = QStringLiteral("-b");
                } else if (helpOut.contains(QStringLiteral("--background"))) {
                    targetFlag = QStringLiteral("--background");
                }
            } else {
                if (proc.state() != QProcess::NotRunning) {
                    proc.kill();
                    proc.waitForFinished(50);
                }
            }
        }

        if (targetFlag.isEmpty()) {
            targetFlag = !detectedExistingFlag.isEmpty() ? detectedExistingFlag : QStringLiteral("--minimized");
        }
        m_minimizeFlagCache.insert(binaryName, targetFlag);
    } else {
        targetFlag = !detectedExistingFlag.isEmpty() ? detectedExistingFlag : QStringLiteral("--minimized");
    }

    const QString flagToUse = hasFlag ? detectedExistingFlag : targetFlag;
    result[QStringLiteral("hasFlag")] = hasFlag;
    result[QStringLiteral("flag")] = flagToUse;
    result[QStringLiteral("cleanCmd")] = cleanCmd;
    result[QStringLiteral("minimizedCmd")] = cleanCmd + QStringLiteral(" ") + flagToUse;

    return result;
}

QVariantMap AutostartManager::parseCommand(const QString& rawCmd, bool onReload, bool isReadOnly) const {
    QVariantMap result;
    QString trimmed = rawCmd.trimmed();
    int delay = 0;
    QString baseCmd = trimmed;

    static const QRegularExpression sleepRe(QStringLiteral(R"(^sleep\s+(\d+(?:\.\d+)?s?)\s*&&\s*(.+)$)"));
    auto match = sleepRe.match(trimmed);
    if (match.hasMatch()) {
        QString delayStr = match.captured(1);
        delayStr.remove(QLatin1Char('s'));
        delay = qRound(delayStr.toDouble());
        baseCmd = match.captured(2).trimmed();
    }

    QVariantMap minInfo = detectMinimizeFlags(baseCmd);

    result[QStringLiteral("rawCommand")] = rawCmd;
    result[QStringLiteral("command")] = baseCmd;
    result[QStringLiteral("delay")] = delay;
    result[QStringLiteral("onReload")] = onReload;
    result[QStringLiteral("isReadOnly")] = isReadOnly;
    result[QStringLiteral("hasMinimizeFlag")] = minInfo.value(QStringLiteral("hasFlag")).toBool();
    result[QStringLiteral("minimizeFlag")] = minInfo.value(QStringLiteral("flag")).toString();
    result[QStringLiteral("cleanCmd")] = minInfo.value(QStringLiteral("cleanCmd")).toString();
    result[QStringLiteral("minimizedCmd")] = minInfo.value(QStringLiteral("minimizedCmd")).toString();

    return result;
}

QString AutostartManager::buildFinalCommand(const QString& baseCmd, int delay, bool startMinimized, const QString& minimizeFlag) const {
    QString trimmed = baseCmd.trimmed();
    static const QRegularExpression sleepRe(QStringLiteral(R"(^sleep\s+\d+(?:\.\d+)?s?\s*&&\s*(.+)$)"));
    auto match = sleepRe.match(trimmed);
    if (match.hasMatch()) {
        trimmed = match.captured(1).trimmed();
    }

    QVariantMap minInfo = detectMinimizeFlags(trimmed);
    QString clean = minInfo.value(QStringLiteral("cleanCmd")).toString();
    QString flagToUse = !minimizeFlag.trimmed().isEmpty() ? minimizeFlag.trimmed() : minInfo.value(QStringLiteral("flag")).toString();
    if (flagToUse.isEmpty()) {
        flagToUse = QStringLiteral("--minimized");
    }

    QString finalCmd;
    if (startMinimized) {
        if (!clean.contains(flagToUse)) {
            finalCmd = clean + QStringLiteral(" ") + flagToUse;
        } else {
            finalCmd = clean;
        }
    } else {
        finalCmd = clean;
    }
    finalCmd = finalCmd.trimmed();

    if (delay > 0) {
        finalCmd = QStringLiteral("sleep %1 && %2").arg(delay).arg(finalCmd);
    }

    return finalCmd;
}

void AutostartManager::scanApps() {
    m_apps.clear();
    QSet<QString> seen;

    const QStringList appDirs = {
        QDir::homePath() + QStringLiteral("/.config/autostart"),
        QDir::homePath() + QStringLiteral("/.local/share/applications"),
        QStringLiteral("/usr/share/applications")
    };

    for (const QString& base : appDirs) {
        QDir dir(base);
        if (!dir.exists()) continue;

        const QStringList entries = dir.entryList({ QStringLiteral("*.desktop") }, QDir::Files);
        for (const QString& f : entries) {
            const QString fullPath = dir.absoluteFilePath(f);
            QSettings desktop(fullPath, QSettings::IniFormat);
            desktop.beginGroup(QStringLiteral("Desktop Entry"));

            if (desktop.value(QStringLiteral("NoDisplay"), false).toBool() || desktop.value(QStringLiteral("Hidden"), false).toBool()) {
                continue;
            }

            const QString name = desktop.value(QStringLiteral("Name")).toString();
            QString exec = desktop.value(QStringLiteral("Exec")).toString();
            // strip %u, %U, %f, %F
            exec.remove(QStringLiteral("%u"));
            exec.remove(QStringLiteral("%U"));
            exec.remove(QStringLiteral("%f"));
            exec.remove(QStringLiteral("%F"));
            exec = exec.trimmed();

            const QString icon = desktop.value(QStringLiteral("Icon")).toString();
            const QString comment = desktop.value(QStringLiteral("Comment")).toString();

            if (!name.isEmpty() && !exec.isEmpty() && !seen.contains(name)) {
                seen.insert(name);
                QVariantMap app;
                app[QStringLiteral("name")] = name;
                app[QStringLiteral("exec")] = exec;
                app[QStringLiteral("icon")] = icon.isEmpty() ? QStringLiteral("application-x-executable") : icon;
                app[QStringLiteral("comment")] = comment;
                m_apps.append(app);
            }
        }
    }

    emit appsChanged();
}

} // namespace FlightDeck::Managers
