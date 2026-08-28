#include "autostartmanager.hpp"
#include "../caelestia/astrahelmwriter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QSet>

namespace Helm::Managers {

AutostartManager* AutostartManager::instance() {
    static AutostartManager inst;
    return &inst;
}

AutostartManager* AutostartManager::create(QQmlEngine*, QJSEngine*) {
    return instance();
}

AutostartManager::AutostartManager(QObject* parent)
    : QObject(parent) {
    scanApps();
    connect(Caelestia::AstraHelmWriter::instance(), &Caelestia::AstraHelmWriter::autostartChanged, this, &AutostartManager::activeCommandsChanged);
}

QVariantList AutostartManager::availableApps() const {
    return m_apps;
}

QStringList AutostartManager::activeCommands() const {
    return Caelestia::AstraHelmWriter::instance()->autostartCommands();
}

void AutostartManager::toggleApp(const QString& execCmd, bool enabled) {
    if (enabled) {
        Caelestia::AstraHelmWriter::instance()->addAutostart(execCmd);
    } else {
        QStringList list = activeCommands();
        int idx = list.indexOf(execCmd);
        if (idx >= 0) {
            Caelestia::AstraHelmWriter::instance()->removeAutostart(idx);
        }
    }
}

void AutostartManager::addCustomCommand(const QString& cmd) {
    Caelestia::AstraHelmWriter::instance()->addAutostart(cmd);
}

void AutostartManager::removeCommand(int index) {
    Caelestia::AstraHelmWriter::instance()->removeAutostart(index);
}

void AutostartManager::scanApps() {
    m_apps.clear();
    QSet<QString> seen;

    const QStringList appDirs = {
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

} // namespace Helm::Managers
