#pragma once

#include "configobject.hpp"

#include <optional>
#include <qfilesystemwatcher.h>
#include <qtimer.h>

namespace caelestia::config {

class RootConfig : public ConfigObject {
    Q_OBJECT

public:
    explicit RootConfig(QObject* parent = nullptr);

    void setupFileBackend(const QString& path, const QString& screen = {}, bool autoSave = false);
    [[nodiscard]] QString filePath() const { return m_filePath; }
    void saveToFile();

    [[nodiscard]] std::optional<QString> reloadFromFile();

    [[nodiscard]] bool recentlySaved() const;

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

signals:
    void loaded(const QString& screen);
    void loadFailed(const QString& error, const QString& screen);
    void saved(const QString& screen);
    void saveFailed(const QString& error, const QString& screen);
    void unknownOption(const QString& key, const QString& screen);

private:
    void emitLoadSignals(const std::optional<QString>& result, bool emitLoaded = true);
    void updateWatch();
    void onWatcherEvent();

    [[nodiscard]] QString fileSignature() const;

    void connectAutoSave(ConfigNode* node);

    void markLoadFailed();

    QString m_filePath;
    QString m_screen;
    QString m_watchedDir;
    QString m_lastSignature;
    bool m_recentlySaved = false;
    bool m_loading = false;
    bool m_loadFailed = false;
    bool m_saveBlockedNotified = false;

    QFileSystemWatcher* m_watcher = nullptr;
    QTimer* m_saveTimer = nullptr;
    QTimer* m_cooldownTimer = nullptr;
    QTimer* m_retryTimer = nullptr;
    QTimer* m_reloadDebounce = nullptr;
    int m_parseRetries = 0;
    QStringList m_lastUnknownKeys;
};

}
