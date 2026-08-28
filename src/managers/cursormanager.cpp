#include "cursormanager.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../hyprland/hyprlandsocket.hpp"

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QSvgRenderer>
#include <QPainter>
#include <QDataStream>

namespace Helm::Managers {

static CursorManager* s_instance = nullptr;

CursorManager* CursorManager::instance() {
    if (!s_instance) {
        s_instance = new CursorManager();
    }
    return s_instance;
}

CursorManager* CursorManager::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

CursorManager::CursorManager(QObject* parent)
    : QObject(parent)
{
    m_currentTheme = Caelestia::CaelestiaVars::instance()->get(QStringLiteral("cursorTheme"), QStringLiteral("Bibata-Modern-Classic")).toString();
    m_currentSize = Caelestia::CaelestiaVars::instance()->get(QStringLiteral("cursorSize"), 24).toInt();
    if (m_currentSize <= 0) m_currentSize = 24;

    scanThemes();
}

QString CursorManager::currentTheme() const {
    return m_currentTheme;
}

void CursorManager::setCurrentTheme(const QString& theme) {
    if (m_currentTheme == theme) return;
    m_currentTheme = theme;
    applySystemWide(m_currentTheme, m_currentSize);
    emit themeChanged();
}

int CursorManager::currentSize() const {
    return m_currentSize;
}

void CursorManager::setCurrentSize(int size) {
    if (m_currentSize == size) return;
    m_currentSize = size;
    applySystemWide(m_currentTheme, m_currentSize);
    emit sizeChanged();
}

QVariantList CursorManager::availableThemes() const {
    return m_themes;
}

QList<int> CursorManager::availableSizes() const {
    return {16, 20, 24, 28, 32, 36, 40, 48, 56, 64};
}

void CursorManager::scanThemes() {
    m_themes.clear();

    const QStringList searchDirs = {
        QDir::homePath() + QStringLiteral("/.local/share/icons"),
        QDir::homePath() + QStringLiteral("/.icons"),
        QStringLiteral("/usr/share/icons"),
        QStringLiteral("/usr/local/share/icons")
    };

    QSet<QString> seen;

    for (const QString& basePath : searchDirs) {
        QDir dir(basePath);
        if (!dir.exists()) continue;

        const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QFileInfo& entry : entries) {
            const QString themeName = entry.fileName();
            if (seen.contains(themeName) || themeName == QStringLiteral("hicolor") || themeName == QStringLiteral("default")) {
                continue;
            }

            const QString cursorsDir = entry.filePath() + QStringLiteral("/cursors");
            const QString hyprDir = entry.filePath() + QStringLiteral("/hyprcursors");
            const QString manifestFile = entry.filePath() + QStringLiteral("/manifest.hl");
            const QString indexTheme = entry.filePath() + QStringLiteral("/index.theme");

            bool isHyprcursor = QDir(hyprDir).exists() || QFile::exists(manifestFile);
            bool isXcursor = QDir(cursorsDir).exists() || QFile::exists(indexTheme);

            if (isHyprcursor || isXcursor) {
                seen.insert(themeName);

                QVariantMap item;
                item[QStringLiteral("name")] = themeName;
                item[QStringLiteral("path")] = entry.filePath();
                item[QStringLiteral("isHyprcursor")] = isHyprcursor;
                item[QStringLiteral("isXcursor")] = isXcursor;
                m_themes.append(item);
            }
        }
    }

    std::sort(m_themes.begin(), m_themes.end(), [](const QVariant& a, const QVariant& b) {
        return a.toMap().value(QStringLiteral("name")).toString().compare(
            b.toMap().value(QStringLiteral("name")).toString(), Qt::CaseInsensitive) < 0;
    });

    emit themesChanged();
}

void CursorManager::apply(const QString& theme, int size) {
    applySystemWide(theme, size);
}

void CursorManager::applySystemWide(const QString& theme, int size) {
    if (theme.isEmpty() || size <= 0) return;

    m_currentTheme = theme;
    m_currentSize = size;

    // 1. Caelestia variables
    Caelestia::CaelestiaVars::instance()->set(QStringLiteral("cursorTheme"), theme);
    Caelestia::CaelestiaVars::instance()->set(QStringLiteral("cursorSize"), size);
    Caelestia::CaelestiaVars::instance()->save();

    // 2. Hyprland compositor live cursor
    Hyprland::HyprlandSocket::instance()->setCursor(theme, size);
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("env"), QStringLiteral("HYPRCURSOR_THEME,%1").arg(theme));
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("env"), QStringLiteral("HYPRCURSOR_SIZE,%1").arg(size));
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("env"), QStringLiteral("XCURSOR_THEME,%1").arg(theme));
    Hyprland::HyprlandSocket::instance()->keyword(QStringLiteral("env"), QStringLiteral("XCURSOR_SIZE,%1").arg(size));

    // 3. GNOME / Cinnamon / GTK GSettings
    applyGSettings(theme, size);

    // 4. GTK 3 & GTK 4 settings.ini
    applyGtkConfig(theme, size);

    // 5. ~/.icons/default/index.theme
    applyDefaultIconTheme(theme);

    // 6. ~/.Xresources & xrdb
    applyXresources(theme, size);

    // 7. Bibata-Caelestia builder trigger if relevant
    if (theme == QStringLiteral("Bibata-Caelestia")) {
        applyBibataBuilder(size);
    }
}

void CursorManager::applyGSettings(const QString& theme, int size) {
    const QString sizeStr = QString::number(size);
    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("cursor-theme"), theme});
    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("cursor-size"), sizeStr});
    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), QStringLiteral("org.cinnamon.desktop.interface"), QStringLiteral("cursor-theme"), theme});
    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), QStringLiteral("org.cinnamon.desktop.interface"), QStringLiteral("cursor-size"), sizeStr});
}

void CursorManager::applyGtkConfig(const QString& theme, int size) {
    const QStringList gtkDirs = {
        QDir::homePath() + QStringLiteral("/.config/gtk-3.0"),
        QDir::homePath() + QStringLiteral("/.config/gtk-4.0")
    };

    for (const QString& d : gtkDirs) {
        QDir().mkpath(d);
        const QString filePath = d + QStringLiteral("/settings.ini");
        QString content;
        if (QFile::exists(filePath)) {
            QFile file(filePath);
            if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                content = QString::fromUtf8(file.readAll());
                file.close();
            }
        }

        if (!content.contains(QStringLiteral("[Settings]"))) {
            content = QStringLiteral("[Settings]\n") + content;
        }

        // Replace or add cursor-theme-name
        if (content.contains(QRegularExpression(QStringLiteral("gtk-cursor-theme-name\\s*=")))) {
            content.replace(QRegularExpression(QStringLiteral("gtk-cursor-theme-name\\s*=[^\n]*")), QStringLiteral("gtk-cursor-theme-name=%1").arg(theme));
        } else {
            content.replace(QStringLiteral("[Settings]"), QStringLiteral("[Settings]\ngtk-cursor-theme-name=%1").arg(theme));
        }

        // Replace or add cursor-theme-size
        if (content.contains(QRegularExpression(QStringLiteral("gtk-cursor-theme-size\\s*=")))) {
            content.replace(QRegularExpression(QStringLiteral("gtk-cursor-theme-size\\s*=[^\n]*")), QStringLiteral("gtk-cursor-theme-size=%1").arg(size));
        } else {
            content.replace(QStringLiteral("[Settings]"), QStringLiteral("[Settings]\ngtk-cursor-theme-size=%1").arg(size));
        }

        QFile outFile(filePath);
        if (outFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream ts(&outFile);
            ts << content;
            outFile.close();
        }
    }
}

void CursorManager::applyDefaultIconTheme(const QString& theme) {
    const QString defaultDir = QDir::homePath() + QStringLiteral("/.icons/default");
    QDir().mkpath(defaultDir);
    QFile file(defaultDir + QStringLiteral("/index.theme"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream ts(&file);
        ts << "[Icon Theme]\nInherits=" << theme << "\n";
        file.close();
    }
}

void CursorManager::applyXresources(const QString& theme, int size) {
    const QString xresourcesPath = QDir::homePath() + QStringLiteral("/.Xresources");
    QString content;
    if (QFile::exists(xresourcesPath)) {
        QFile file(xresourcesPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            content = QString::fromUtf8(file.readAll());
            file.close();
        }
    }

    if (content.contains(QRegularExpression(QStringLiteral("Xcursor\\.theme:\\s*")))) {
        content.replace(QRegularExpression(QStringLiteral("Xcursor\\.theme:\\s*[^\n]*")), QStringLiteral("Xcursor.theme: %1").arg(theme));
    } else {
        content += QStringLiteral("\nXcursor.theme: %1\n").arg(theme);
    }

    if (content.contains(QRegularExpression(QStringLiteral("Xcursor\\.size:\\s*")))) {
        content.replace(QRegularExpression(QStringLiteral("Xcursor\\.size:\\s*[^\n]*")), QStringLiteral("Xcursor.size: %1").arg(size));
    } else {
        content += QStringLiteral("Xcursor.size: %1\n").arg(size);
    }

    QFile outFile(xresourcesPath);
    if (outFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream ts(&outFile);
        ts << content;
        outFile.close();
    }

    QProcess::startDetached(QStringLiteral("xrdb"), {QStringLiteral("-merge"), xresourcesPath});
}

void CursorManager::applyBibataBuilder(int size) {
    const QString builderPath = QStringLiteral("/usr/local/bin/bibata-caelestia-builder");
    if (QFile::exists(builderPath)) {
        QProcess::startDetached(QStringLiteral("sudo"), {builderPath, QStringLiteral("--size"), QString::number(size)});
    }
}

static QImage parseXCursorImage(const QString& filePath, int targetSize) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return QImage();

    QDataStream stream(&file);
    stream.setByteOrder(QDataStream::LittleEndian);

    quint32 magic = 0;
    stream >> magic;
    if (magic != 0x72756358) return QImage(); // 'Xcur'

    quint32 headerSize = 0, version = 0, ntoc = 0;
    stream >> headerSize >> version >> ntoc;

    struct TocEntry {
        quint32 type;
        quint32 subtype;
        quint32 position;
    };
    QVector<TocEntry> tocs;
    for (quint32 i = 0; i < ntoc; ++i) {
        TocEntry entry;
        stream >> entry.type >> entry.subtype >> entry.position;
        if (entry.type == 0xfffd0002) { // XCUR_IMAGE_TYPE
            tocs.append(entry);
        }
    }

    if (tocs.isEmpty()) return QImage();

    // Find closest subtype to targetSize
    int bestDiff = 99999;
    TocEntry bestToc = tocs.first();
    for (const TocEntry& t : tocs) {
        int diff = std::abs(static_cast<int>(t.subtype) - targetSize);
        if (diff < bestDiff) {
            bestDiff = diff;
            bestToc = t;
        }
    }

    file.seek(bestToc.position);
    quint32 cSize, cType, cSubtype, cVersion, width, height, xhot, yhot, delay;
    stream >> cSize >> cType >> cSubtype >> cVersion >> width >> height >> xhot >> yhot >> delay;

    if (width == 0 || height == 0 || width > 512 || height > 512) return QImage();

    QImage img(width, height, QImage::Format_ARGB32);
    qint64 byteCount = static_cast<qint64>(width) * height * 4;
    if (file.read(reinterpret_cast<char*>(img.bits()), byteCount) != byteCount) {
        return QImage();
    }

    return img;
}

QImage CursorManager::loadCursorPreview(const QString& themeName, int targetSize) {
    const QStringList searchDirs = {
        QDir::homePath() + QStringLiteral("/.local/share/icons/") + themeName,
        QDir::homePath() + QStringLiteral("/.icons/") + themeName,
        QStringLiteral("/usr/share/icons/") + themeName,
        QStringLiteral("/usr/local/share/icons/") + themeName
    };

    // 1. Try SVG templates (e.g. Bibata templates)
    const QStringList svgCandidates = {
        QDir::homePath() + QStringLiteral("/.config/caelestia/templates/bibata/left_ptr.svg"),
        QDir::homePath() + QStringLiteral("/Projects/Bibata_Cursor/templates/left_ptr.svg"),
        QDir::homePath() + QStringLiteral("/.local/share/icons/") + themeName + QStringLiteral("/left_ptr.svg")
    };

    if (themeName.contains(QStringLiteral("Bibata"), Qt::CaseInsensitive)) {
        for (const QString& svgPath : svgCandidates) {
            if (QFile::exists(svgPath)) {
                QSvgRenderer renderer(svgPath);
                if (renderer.isValid()) {
                    QImage img(targetSize, targetSize, QImage::Format_ARGB32_Premultiplied);
                    img.fill(Qt::transparent);
                    QPainter p(&img);
                    renderer.render(&p);
                    return img;
                }
            }
        }
    }

    // 2. Try XCursor left_ptr / default
    for (const QString& themeDir : searchDirs) {
        if (!QDir(themeDir).exists()) continue;

        const QStringList cursorNames = {
            QStringLiteral("left_ptr"), QStringLiteral("default"), QStringLiteral("arrow"), QStringLiteral("pointer")
        };

        for (const QString& cName : cursorNames) {
            const QString xcursorFile = themeDir + QStringLiteral("/cursors/") + cName;
            if (QFile::exists(xcursorFile)) {
                QImage img = parseXCursorImage(xcursorFile, targetSize);
                if (!img.isNull()) {
                    return img.scaled(targetSize, targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                }
            }
        }
    }

    // 3. Fallback: Render clean pointer shape
    QImage fallback(targetSize, targetSize, QImage::Format_ARGB32_Premultiplied);
    fallback.fill(Qt::transparent);
    QPainter p(&fallback);
    p.setRenderHint(QPainter::Antialiasing);

    QPolygonF poly;
    poly << QPointF(targetSize * 0.2, targetSize * 0.1)
         << QPointF(targetSize * 0.2, targetSize * 0.8)
         << QPointF(targetSize * 0.42, targetSize * 0.6)
         << QPointF(targetSize * 0.68, targetSize * 0.85)
         << QPointF(targetSize * 0.78, targetSize * 0.75)
         << QPointF(targetSize * 0.52, targetSize * 0.5)
         << QPointF(targetSize * 0.75, targetSize * 0.5);

    p.setBrush(Qt::black);
    p.setPen(QPen(Qt::white, targetSize * 0.05, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    p.drawPolygon(poly);

    return fallback;
}

} // namespace Helm::Managers
