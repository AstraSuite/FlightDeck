#include "profilemanager.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../caelestia/astrahelmwriter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDateTime>

namespace Helm::Managers {

ProfileManager* ProfileManager::instance() {
    static ProfileManager inst;
    return &inst;
}

ProfileManager* ProfileManager::create(QQmlEngine*, QJSEngine*) {
    return instance();
}

ProfileManager::ProfileManager(QObject* parent)
    : QObject(parent) {
    refresh();
}

QString ProfileManager::profilesDir() const {
    const QString base = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    return base + QStringLiteral("/astra-helm/profiles");
}

QStringList ProfileManager::profiles() const {
    return m_profiles;
}

bool ProfileManager::createProfile(const QString& name) {
    if (name.trimmed().isEmpty()) {
        emit operationFinished(false, QStringLiteral("Profile name cannot be empty"));
        return false;
    }

    const QString dirPath = profilesDir() + QStringLiteral("/") + name.trimmed();
    QDir dir(dirPath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }

    // Copy hypr-vars.lua & astra-helm.lua
    const QString varsPath = Caelestia::CaelestiaVars::varsFilePath();
    if (QFile::exists(varsPath)) {
        QFile::remove(dirPath + QStringLiteral("/hypr-vars.lua"));
        QFile::copy(varsPath, dirPath + QStringLiteral("/hypr-vars.lua"));
    }

    const QString helmPath = Caelestia::AstraHelmWriter::astraHelmFilePath();
    if (QFile::exists(helmPath)) {
        QFile::remove(dirPath + QStringLiteral("/astra-helm.lua"));
        QFile::copy(helmPath, dirPath + QStringLiteral("/astra-helm.lua"));
    }

    refresh();
    emit operationFinished(true, QStringLiteral("Profile '%1' created successfully").arg(name));
    return true;
}

bool ProfileManager::restoreProfile(const QString& name) {
    const QString dirPath = profilesDir() + QStringLiteral("/") + name.trimmed();
    QDir dir(dirPath);
    if (!dir.exists()) {
        emit operationFinished(false, QStringLiteral("Profile '%1' not found").arg(name));
        return false;
    }

    const QString savedVars = dirPath + QStringLiteral("/hypr-vars.lua");
    const QString targetVars = Caelestia::CaelestiaVars::varsFilePath();
    if (QFile::exists(savedVars)) {
        QFile::remove(targetVars);
        QFile::copy(savedVars, targetVars);
        Caelestia::CaelestiaVars::instance()->reload();
    }

    const QString savedHelm = dirPath + QStringLiteral("/astra-helm.lua");
    const QString targetHelm = Caelestia::AstraHelmWriter::astraHelmFilePath();
    if (QFile::exists(savedHelm)) {
        QFile::remove(targetHelm);
        QFile::copy(savedHelm, targetHelm);
        Caelestia::AstraHelmWriter::instance()->reload();
    }

    emit operationFinished(true, QStringLiteral("Profile '%1' restored successfully").arg(name));
    return true;
}

bool ProfileManager::deleteProfile(const QString& name) {
    const QString dirPath = profilesDir() + QStringLiteral("/") + name.trimmed();
    QDir dir(dirPath);
    if (dir.exists()) {
        dir.removeRecursively();
        refresh();
        emit operationFinished(true, QStringLiteral("Profile '%1' deleted").arg(name));
        return true;
    }
    return false;
}

void ProfileManager::refresh() {
    m_profiles.clear();
    QDir dir(profilesDir());
    if (dir.exists()) {
        m_profiles = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    }
    emit profilesChanged();
}

} // namespace Helm::Managers
