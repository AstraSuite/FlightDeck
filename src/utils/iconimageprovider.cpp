#include "iconimageprovider.hpp"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QMutexLocker>
#include <QPainter>
#include <QSvgRenderer>
#include <QUrl>

namespace {

QImage loadImage(const QString& path, const QSize& targetSize) {
    if (path.isEmpty()) return QImage();

    if (path.endsWith(QLatin1String(".svg"), Qt::CaseInsensitive)) {
        QSvgRenderer renderer(path);
        if (!renderer.isValid()) return QImage();

        QImage image(targetSize, QImage::Format_ARGB32_Premultiplied);
        image.fill(Qt::transparent);
        QPainter painter(&image);
        renderer.render(&painter);
        return image;
    }

    QImage img(path);
    if (!img.isNull() && (img.width() != targetSize.width() || img.height() != targetSize.height())) {
        return img.scaled(targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return img;
}

}

IconImageProvider::IconImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {
    indexIcons();
}

void IconImageProvider::indexIcons() {
    QMutexLocker locker(&m_mutex);
    if (m_indexed) return;
    m_indexed = true;

    const QStringList iconDirs = {
        QDir::homePath() + QStringLiteral("/.local/share/icons/hicolor"),
        QDir::homePath() + QStringLiteral("/.local/share/icons"),
        QStringLiteral("/usr/share/icons/hicolor"),
        QStringLiteral("/usr/share/icons/Papirus-Dark"),
        QStringLiteral("/usr/share/icons/Papirus"),
        QStringLiteral("/usr/share/icons/breeze-dark"),
        QStringLiteral("/usr/share/icons/breeze"),
        QStringLiteral("/usr/share/icons/Adwaita"),
        QStringLiteral("/usr/share/pixmaps")
    };

    for (const QString& baseDir : iconDirs) {
        QDir dir(baseDir);
        if (!dir.exists()) continue;

        QDirIterator it(baseDir, {QStringLiteral("*.svg"), QStringLiteral("*.png")}, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QString baseName = it.fileInfo().completeBaseName().toLower();
            if (!m_iconMap.contains(baseName)) {
                m_iconMap.insert(baseName, it.filePath());
            }
        }
    }
}

QImage IconImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    QString name = id;
    if (name.contains(QLatin1Char('?'))) name = name.section(QLatin1Char('?'), 0, 0);
    if (name.startsWith(QLatin1String("image://icon/"))) name = name.mid(13);
    if (name.startsWith(QLatin1String("file://"))) name = QUrl(name).toLocalFile();
    if (name.isEmpty()) return QImage();

    const QSize targetSize(requestedSize.width() > 0 ? requestedSize.width() : 48,
                           requestedSize.height() > 0 ? requestedSize.height() : 48);

    if (name.startsWith(QLatin1Char('/'))) {
        if (QFile::exists(name)) {
            const QImage img = loadImage(name, targetSize);
            if (!img.isNull()) {
                if (size) *size = img.size();
                return img;
            }
        }
    }

    const QString resolved = resolvePath(name);
    if (!resolved.isEmpty()) {
        const QImage img = loadImage(resolved, targetSize);
        if (!img.isNull()) {
            if (size) *size = img.size();
            return img;
        }
    }

    return QImage();
}

QString IconImageProvider::resolvePath(const QString& name) {
    QMutexLocker locker(&m_mutex);
    const QString lower = name.toLower();
    if (m_iconMap.contains(lower)) {
        return m_iconMap.value(lower);
    }
    if (lower.contains(QLatin1Char('.'))) {
        const QString noExt = lower.section(QLatin1Char('.'), 0, 0);
        if (m_iconMap.contains(noExt)) {
            return m_iconMap.value(noExt);
        }
    }
    return QString();
}
