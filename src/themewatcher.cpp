#include "themewatcher.hpp"
#include "config/tokens.hpp"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <QSettings>
#include <QDebug>

ThemeWatcher* ThemeWatcher::instance() {
    static ThemeWatcher inst;
    return &inst;
}

ThemeWatcher* ThemeWatcher::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

ThemeWatcher::ThemeWatcher(QObject* parent)
    : QObject(parent) {
    QSettings settings(QStringLiteral("AstraSuite"), QStringLiteral("FlightDeck"));
    m_syncScheme = settings.value(QStringLiteral("theme/syncScheme"), true).toBool();
    m_syncTokens = settings.value(QStringLiteral("theme/syncTokens"), true).toBool();

    const QString filePath = getSchemeFilePath();
    const QFileInfo fi(filePath);
    if (!fi.dir().exists()) {
        fi.dir().mkpath(QStringLiteral("."));
    }

    if (QFile::exists(filePath)) {
        m_watcher.addPath(filePath);
    } else {
        m_watcher.addPath(fi.dir().path());
    }

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString& path) {
        if (!m_watcher.files().contains(path) && QFile::exists(path)) {
            m_watcher.addPath(path);
        }
        if (m_syncScheme) {
            reload();
        }
    });
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this](const QString&) {
        const QString path = getSchemeFilePath();
        if (QFile::exists(path) && !m_watcher.files().contains(path)) {
            m_watcher.addPath(path);
        }
        if (m_syncScheme) {
            reload();
        }
    });

    reload();
}

void ThemeWatcher::setSyncScheme(bool sync) {
    if (m_syncScheme != sync) {
        m_syncScheme = sync;
        QSettings settings(QStringLiteral("AstraSuite"), QStringLiteral("FlightDeck"));
        settings.setValue(QStringLiteral("theme/syncScheme"), sync);
        emit syncSchemeChanged();
        reload();
    }
}

void ThemeWatcher::setSyncTokens(bool sync) {
    if (m_syncTokens != sync) {
        m_syncTokens = sync;
        QSettings settings(QStringLiteral("AstraSuite"), QStringLiteral("FlightDeck"));
        settings.setValue(QStringLiteral("theme/syncTokens"), sync);
        emit syncTokensChanged();
        applyTokensSync();
    }
}

void ThemeWatcher::applyTokensSync() {
    caelestia::config::TokenConfig::instance()->setSync(m_syncTokens);
}

QString ThemeWatcher::getSchemeFilePath() const {
    const QString stateHome = qEnvironmentVariable("XDG_STATE_HOME", QDir::homePath() + QStringLiteral("/.local/state"));
    return stateHome + QStringLiteral("/caelestia/scheme.json");
}

void ThemeWatcher::applyFallbackColours() {
    m_name = QStringLiteral("flightdeck");
    m_mode = QStringLiteral("dark");
    m_flavour = QStringLiteral("default");
    m_variant = QStringLiteral("content");

    m_colours = QVariantMap{
        { QStringLiteral("background"), QStringLiteral("111418") },
        { QStringLiteral("surface"), QStringLiteral("111418") },
        { QStringLiteral("surfaceDim"), QStringLiteral("0e1115") },
        { QStringLiteral("surfaceBright"), QStringLiteral("282e36") },
        { QStringLiteral("surfaceContainerLowest"), QStringLiteral("080a0c") },
        { QStringLiteral("surfaceContainerLow"), QStringLiteral("14181f") },
        { QStringLiteral("surfaceContainer"), QStringLiteral("1a2029") },
        { QStringLiteral("surfaceContainerHigh"), QStringLiteral("202732") },
        { QStringLiteral("surfaceContainerHighest"), QStringLiteral("272f3d") },
        { QStringLiteral("onSurface"), QStringLiteral("e1e2e8") },
        { QStringLiteral("onBackground"), QStringLiteral("e1e2e8") },
        { QStringLiteral("surfaceVariant"), QStringLiteral("272f3d") },
        { QStringLiteral("onSurfaceVariant"), QStringLiteral("a0a8b4") },
        { QStringLiteral("outline"), QStringLiteral("636c7a") },
        { QStringLiteral("outlineVariant"), QStringLiteral("373f4b") },
        { QStringLiteral("primary"), QStringLiteral("64b5f6") },
        { QStringLiteral("onPrimary"), QStringLiteral("003258") },
        { QStringLiteral("primaryContainer"), QStringLiteral("0b4a7a") },
        { QStringLiteral("onPrimaryContainer"), QStringLiteral("d1e4ff") },
        { QStringLiteral("secondary"), QStringLiteral("9bc8f5") },
        { QStringLiteral("onSecondary"), QStringLiteral("003355") },
        { QStringLiteral("secondaryContainer"), QStringLiteral("1b4970") },
        { QStringLiteral("onSecondaryContainer"), QStringLiteral("cde5ff") },
        { QStringLiteral("tertiary"), QStringLiteral("b3c5ff") },
        { QStringLiteral("onTertiary"), QStringLiteral("192e60") },
        { QStringLiteral("tertiaryContainer"), QStringLiteral("314478") },
        { QStringLiteral("onTertiaryContainer"), QStringLiteral("dbe1ff") },
        { QStringLiteral("error"), QStringLiteral("ffb4ab") },
        { QStringLiteral("onError"), QStringLiteral("690005") },
        { QStringLiteral("errorContainer"), QStringLiteral("93000a") },
        { QStringLiteral("onErrorContainer"), QStringLiteral("ffdad6") }
    };
    emit themeChanged();
}

void ThemeWatcher::reload() {
    if (!m_syncScheme) {
        applyFallbackColours();
        return;
    }

    const QString path = getSchemeFilePath();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        applyFallbackColours();
        return;
    }

    const QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseErr;
    const QJsonDocument doc = QJsonDocument::fromJson(data, &parseErr);
    if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "ThemeWatcher: Failed to parse scheme JSON:" << parseErr.errorString();
        applyFallbackColours();
        return;
    }

    const QJsonObject root = doc.object();
    m_name = root.value(QStringLiteral("name")).toString(QStringLiteral("caelestia"));
    m_flavour = root.value(QStringLiteral("flavour")).toString(QStringLiteral("default"));
    m_mode = root.value(QStringLiteral("mode")).toString(QStringLiteral("dark"));
    m_variant = root.value(QStringLiteral("variant")).toString(QStringLiteral("content"));

    if (root.contains(QStringLiteral("colours")) && root.value(QStringLiteral("colours")).isObject()) {
        m_colours = root.value(QStringLiteral("colours")).toObject().toVariantMap();
    }

    emit themeChanged();
}

void ThemeWatcher::setMode(const QString& mode) {
    if (m_syncScheme && !QStandardPaths::findExecutable(QStringLiteral("caelestia")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("caelestia"), { QStringLiteral("scheme"), QStringLiteral("set"), QStringLiteral("--notify"), QStringLiteral("-m"), mode });
    } else {
        m_mode = mode;
        emit themeChanged();
    }
}
