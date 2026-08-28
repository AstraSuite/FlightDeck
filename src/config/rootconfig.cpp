#include "rootconfig.hpp"
#include "sessionconfig.hpp"

#include <qdatetime.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qmetaobject.h>
#include <qregularexpression.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString watchRoot() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
}

QString reorderJsonBlockKeys(const QString& text, const QString& parentKey, const QString& sectionKey, const QStringList& orderedKeys) {
    if (orderedKeys.isEmpty())
        return text;

    int parentPos = text.indexOf(QStringLiteral("\"") + parentKey + QStringLiteral("\""));
    if (parentPos == -1)
        parentPos = 0;

    int sectionPos = text.indexOf(QStringLiteral("\"") + sectionKey + QStringLiteral("\""), parentPos);
    if (sectionPos == -1)
        return text;

    int bracePos = text.indexOf(QLatin1Char('{'), sectionPos);
    if (bracePos == -1)
        return text;

    int depth = 1;
    int endPos = bracePos + 1;
    bool inString = false;
    bool escape = false;

    while (endPos < text.length() && depth > 0) {
        QChar ch = text.at(endPos);
        if (escape) {
            escape = false;
        } else if (ch == QLatin1Char('\\')) {
            escape = true;
        } else if (ch == QLatin1Char('"')) {
            inString = !inString;
        } else if (!inString) {
            if (ch == QLatin1Char('{'))
                depth++;
            else if (ch == QLatin1Char('}'))
                depth--;
        }
        endPos++;
    }

    QString block = text.mid(bracePos + 1, endPos - bracePos - 2);

    struct KeyEntry {
        QString key;
        QString text;
    };
    QList<KeyEntry> entries;

    int cur = 0;
    while (cur < block.length()) {
        int keyStart = block.indexOf(QLatin1Char('"'), cur);
        if (keyStart == -1)
            break;
        int keyEnd = block.indexOf(QLatin1Char('"'), keyStart + 1);
        if (keyEnd == -1)
            break;
        QString keyName = block.mid(keyStart + 1, keyEnd - keyStart - 1);

        int colonPos = block.indexOf(QLatin1Char(':'), keyEnd + 1);
        if (colonPos == -1)
            break;

        int valStart = colonPos + 1;
        while (valStart < block.length() && (block[valStart] == QLatin1Char(' ') || block[valStart] == QLatin1Char('\n') || block[valStart] == QLatin1Char('\r') || block[valStart] == QLatin1Char('\t')))
            valStart++;

        int entryEnd = valStart;
        if (valStart < block.length() && (block[valStart] == QLatin1Char('{') || block[valStart] == QLatin1Char('['))) {
            QChar openChar = block[valStart];
            QChar closeChar = (openChar == QLatin1Char('{')) ? QLatin1Char('}') : QLatin1Char(']');
            int valDepth = 1;
            entryEnd = valStart + 1;
            bool sInString = false;
            bool sEscape = false;
            while (entryEnd < block.length() && valDepth > 0) {
                QChar c = block[entryEnd];
                if (sEscape) {
                    sEscape = false;
                } else if (c == QLatin1Char('\\')) {
                    sEscape = true;
                } else if (c == QLatin1Char('"')) {
                    sInString = !sInString;
                } else if (!sInString) {
                    if (c == openChar)
                        valDepth++;
                    else if (c == closeChar)
                        valDepth--;
                }
                entryEnd++;
            }
        } else {
            bool sInString = false;
            bool sEscape = false;
            while (entryEnd < block.length()) {
                QChar c = block[entryEnd];
                if (sEscape) {
                    sEscape = false;
                } else if (c == QLatin1Char('\\')) {
                    sEscape = true;
                } else if (c == QLatin1Char('"')) {
                    sInString = !sInString;
                } else if (!sInString && (c == QLatin1Char(',') || c == QLatin1Char('\n') || c == QLatin1Char('\r'))) {
                    break;
                }
                entryEnd++;
            }
        }

        while (entryEnd < block.length() && (block[entryEnd] == QLatin1Char(',') || block[entryEnd] == QLatin1Char('\r'))) {
            if (block[entryEnd] == QLatin1Char(',')) {
                entryEnd++;
                break;
            }
            entryEnd++;
        }

        entries.append({ keyName, block.mid(keyStart, entryEnd - keyStart) });
        cur = entryEnd;
    }

    if (entries.isEmpty())
        return text;

    QList<KeyEntry> reorderedEntries;
    QSet<QString> processed;

    for (const auto& key : orderedKeys) {
        for (const auto& entry : entries) {
            if (entry.key == key && !processed.contains(key)) {
                processed.insert(key);
                reorderedEntries.append(entry);
                break;
            }
        }
    }

    for (const auto& entry : entries) {
        if (!processed.contains(entry.key)) {
            processed.insert(entry.key);
            reorderedEntries.append(entry);
        }
    }

    QString newBlockContent = QStringLiteral("\n");
    for (int i = 0; i < reorderedEntries.size(); ++i) {
        QString entryText = reorderedEntries[i].text.trimmed();
        if (entryText.endsWith(QLatin1Char(',')))
            entryText.chop(1);

        QStringList lines = entryText.split(QLatin1Char('\n'));
        newBlockContent += QStringLiteral("            ") + lines[0].trimmed();
        for (int j = 1; j < lines.size(); ++j) {
            newBlockContent += QStringLiteral("\n") + lines[j];
        }

        if (i < reorderedEntries.size() - 1)
            newBlockContent += QStringLiteral(",");
        newBlockContent += QStringLiteral("\n");
    }

    QString resultText = text;
    resultText.replace(bracePos + 1, endPos - bracePos - 2, newBlockContent + QStringLiteral("        "));
    return resultText;
}

}

RootConfig::RootConfig(QObject* parent)
    : ConfigObject(parent) {}

bool RootConfig::recentlySaved() const {
    return m_recentlySaved;
}

void RootConfig::setupFileBackend(const QString& path, const QString& screen, bool autoSave) {
    m_filePath = path;
    m_screen = screen;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);
    m_retryTimer = new QTimer(this);

    m_retryTimer->setSingleShot(true);
    m_retryTimer->setInterval(50);
    connect(m_retryTimer, &QTimer::timeout, this, &RootConfig::reload);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            auto err = QStringLiteral("Failed to write %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            emit saveFailed(err, m_screen);
            return;
        }

        const auto json = toJson().toObject();
        QString jsonText = QString::fromUtf8(QJsonDocument(json).toJson(QJsonDocument::Indented));

        const auto* meta = metaObject();
        for (int i = basePropertyOffset(); i < meta->propertyCount(); ++i) {
            const auto prop = meta->property(i);
            if (QString::fromUtf8(prop.name()) == QStringLiteral("session")) {
                if (auto* session = qobject_cast<SessionConfig*>(prop.read(this).value<QObject*>())) {
                    if (session->icons()) {
                        jsonText = reorderJsonBlockKeys(jsonText, QStringLiteral("session"), QStringLiteral("icons"), session->icons()->customIconKeys());
                    }
                    if (session->commands()) {
                        jsonText = reorderJsonBlockKeys(jsonText, QStringLiteral("session"), QStringLiteral("commands"), session->commands()->customCommandKeys());
                    }
                }
            }
        }

        file.write(jsonText.toUtf8());
        file.close();

        updateWatch();
        m_lastSignature = fileSignature();

        emit saved(m_screen);
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    m_reloadDebounce = new QTimer(this);
    m_reloadDebounce->setSingleShot(true);
    m_reloadDebounce->setInterval(50);
    connect(m_reloadDebounce, &QTimer::timeout, this, &RootConfig::reload);

    if (autoSave) {
        connectAutoSave(this);
    }

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &RootConfig::onWatcherEvent);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &RootConfig::onWatcherEvent);

    qCDebug(lcConfig) << "Setting up file backend for" << metaObject()->className() << "at" << path;

    updateWatch();

    auto result = reloadFromFile();
    QTimer::singleShot(0, this, [this, result] {
        emitLoadSignals(result, false);
    });
}

void RootConfig::markLoadFailed() {
    m_loadFailed = true;

    if (m_saveTimer)
        m_saveTimer->stop();
}

void RootConfig::connectAutoSave(ConfigNode* node) {
    connect(node, &ConfigNode::propertiesChanged, this, [this] {
        if (!m_loading)
            saveToFile();
    });

    const auto children = node->childNodes();
    for (auto* const child : children)
        connectAutoSave(child);
}

void RootConfig::updateWatch() {
    auto targetDir = QFileInfo(m_filePath).absolutePath();

    auto dir = targetDir;
    while (!QFile::exists(dir) && dir != watchRoot() && !dir.isEmpty()) {
        auto parent = QFileInfo(dir).absolutePath();
        if (parent == dir)
            break;
        dir = parent;
    }

    if (dir != m_watchedDir) {
        if (!m_watchedDir.isEmpty())
            m_watcher->removePath(m_watchedDir);

        m_watchedDir = dir;

        if (QFile::exists(dir))
            m_watcher->addPath(dir);
    }

    if (QFile::exists(m_filePath)) {
        if (!m_watcher->files().contains(m_filePath))
            m_watcher->addPath(m_filePath);
    }
}

void RootConfig::onWatcherEvent() {

    updateWatch();

    if (m_recentlySaved)
        return;

    if (fileSignature() == m_lastSignature)
        return;

    m_reloadDebounce->start();
}

QString RootConfig::fileSignature() const {
    QFileInfo info(m_filePath);
    if (!info.exists())
        return QString();

    return QStringLiteral("%1:%2").arg(info.size()).arg(info.lastModified().toMSecsSinceEpoch());
}

void RootConfig::saveToFile() {
    if (!m_saveTimer)
        return;

    if (m_loadFailed) {
        qCWarning(lcConfig) << "Not saving" << m_filePath << "- last load failed";

        if (!m_saveBlockedNotified) {
            m_saveBlockedNotified = true;
            emit saveFailed(
                QStringLiteral("Not overwriting %1 until the last load error is fixed").arg(m_filePath), m_screen);
        }

        return;
    }

    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

std::optional<QString> RootConfig::reloadFromFile() {
    m_lastSignature = fileSignature();
    m_loadFailed = false;
    m_saveBlockedNotified = false;

    QFile file(m_filePath);

    if (!file.exists()) {
        qCDebug(lcConfig) << "File does not exist:" << m_filePath;
        return std::nullopt;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        markLoadFailed();
        auto err = QStringLiteral("Failed to open %1: %2").arg(m_filePath, file.errorString());
        qCDebug(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        markLoadFailed();

        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qUtf8Printable(m_filePath),
                qUtf8Printable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
            return std::nullopt;
        }

        qCWarning(lcConfig, "Failed to parse %s: %s", qUtf8Printable(m_filePath), qUtf8Printable(error.errorString()));
        m_parseRetries = 0;
        return QStringLiteral("JSON parse error: %1").arg(error.errorString());
    }

    m_parseRetries = 0;

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    m_loading = true;

    clearLoadedKeys();

    loadFromJson(doc.object());

    m_loading = false;

    m_lastUnknownKeys = unknownKeys();

    return QString();
}

void RootConfig::save() {
    saveToFile();
}

void RootConfig::emitLoadSignals(const std::optional<QString>& result, bool emitLoaded) {
    if (!result.has_value())
        return;

    for (const auto& key : std::as_const(m_lastUnknownKeys))
        emit unknownOption(key, m_screen);
    m_lastUnknownKeys.clear();

    if (result->isEmpty()) {
        if (emitLoaded)
            emit loaded(m_screen);
    } else {
        emit loadFailed(*result, m_screen);
    }
}

void RootConfig::reload() {
    emitLoadSignals(reloadFromFile());
}

}
