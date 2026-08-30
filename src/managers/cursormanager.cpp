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

namespace FlightDeck::Managers {

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
            const QString cursorTheme = entry.filePath() + QStringLiteral("/cursor.theme");

            bool isHyprcursor = QDir(hyprDir).exists() || QFile::exists(manifestFile);
            bool isXcursor = QDir(cursorsDir).exists() || QFile::exists(cursorTheme);

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

    // 2. Hyprland compositor live cursor (cache-bust cycle across all instances)
    Hyprland::HyprlandSocket::instance()->setCursorAll(theme, size);
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
}

void CursorManager::applyGSettings(const QString& theme, int size) {
    const QString sizeStr = QString::number(size);
    const QString gnomeSchema = QStringLiteral("org.gnome.desktop.interface");
    const QString cinnamonSchema = QStringLiteral("org.cinnamon.desktop.interface");

    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), gnomeSchema, QStringLiteral("cursor-theme"), theme});
    QProcess::startDetached(QStringLiteral("gsettings"), {QStringLiteral("set"), gnomeSchema, QStringLiteral("cursor-size"), sizeStr});
    QProcess::startDetached(QStringLiteral("dconf"), {QStringLiteral("write"), QStringLiteral("/org/gnome/desktop/interface/cursor-theme"), QStringLiteral("'%1'").arg(theme)});
    QProcess::startDetached(QStringLiteral("dconf"), {QStringLiteral("write"), QStringLiteral("/org/gnome/desktop/interface/cursor-size"), sizeStr});

    // Cinnamon (dconf-based) - only apply if the schema/settings actually exist.
    QProcess proc;
    proc.start(QStringLiteral("dconf"), {QStringLiteral("list"), QStringLiteral("/org/cinnamon/desktop/interface/")});
    if (proc.waitForFinished(1000) && proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0) {
        const QString out = QString::fromUtf8(proc.readAllStandardOutput());
        if (out.contains(QStringLiteral("cursor-theme")) || out.contains(QStringLiteral("cursor-size"))) {
            QProcess::startDetached(QStringLiteral("dconf"), {QStringLiteral("write"), QStringLiteral("/org/cinnamon/desktop/interface/cursor-theme"), QStringLiteral("'%1'").arg(theme)});
            QProcess::startDetached(QStringLiteral("dconf"), {QStringLiteral("write"), QStringLiteral("/org/cinnamon/desktop/interface/cursor-size"), sizeStr});
        }
    }
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
    const QStringList defaultDirs = {
        QDir::homePath() + QStringLiteral("/.local/share/icons/default"),
        QDir::homePath() + QStringLiteral("/.icons/default")
    };
    const QString content = QStringLiteral("[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits=%1\n").arg(theme);
    for (const QString& d : defaultDirs) {
        QDir().mkpath(d);
        QFile file(d + QStringLiteral("/index.theme"));
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream ts(&file);
            ts << content;
            file.close();
        }
    }
}

void CursorManager::applyXresources(const QString& theme, int size) {
    const QString xresourcesPath = QDir::homePath() + QStringLiteral("/.Xresources");
    QStringList lines;
    if (QFile::exists(xresourcesPath)) {
        QFile file(xresourcesPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QString content = QString::fromUtf8(file.readAll());
            file.close();
            lines = content.split(QLatin1Char('\n'));
        }
    }

    // Strip any existing Xcursor.theme / Xcursor.size entries (including case/space
    // variants) so we never emit duplicate overrides that trip xrdb.
    QStringList filtered;
    static const QRegularExpression cursorLineRe(QStringLiteral(R"(^\s*Xcursor\.(theme|size)\s*:)"));
    for (const QString& line : lines) {
        if (cursorLineRe.match(line).hasMatch()) continue;
        filtered.append(line);
    }

    // Append a single canonical pair.
    filtered.removeAll(QString());
    QString out = filtered.join(QLatin1Char('\n'));
    if (!out.isEmpty() && !out.endsWith(QLatin1Char('\n'))) out += QLatin1Char('\n');
    out += QStringLiteral("Xcursor.theme: %1\n").arg(theme);
    out += QStringLiteral("Xcursor.size: %1\n").arg(size);

    QFile outFile(xresourcesPath);
    if (outFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream ts(&outFile);
        ts << out;
        outFile.close();
    }

    QProcess::startDetached(QStringLiteral("xrdb"), {QStringLiteral("-merge"), xresourcesPath});
}

static QImage parseXCursorImage(const QString& filePath, int targetSize) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return QImage();
    const QByteArray data = file.readAll();
    file.close();

    if (data.size() < 16) return QImage();

    const uchar* raw = reinterpret_cast<const uchar*>(data.constData());
    auto readU32 = [raw, dataSize = data.size()](qsizetype offset) -> quint32 {
        if (offset < 0 || offset + 4 > dataSize) return 0;
        return static_cast<quint32>(raw[offset]) |
               (static_cast<quint32>(raw[offset + 1]) << 8) |
               (static_cast<quint32>(raw[offset + 2]) << 16) |
               (static_cast<quint32>(raw[offset + 3]) << 24);
    };

    quint32 magic = readU32(0);
    if (magic != 0x72756358) return QImage(); // 'Xcur'

    quint32 headerSize = readU32(4);
    quint32 version = readU32(8);
    quint32 ntoc = readU32(12);

    struct TocEntry {
        quint32 type;
        quint32 subtype;
        quint32 position;
    };
    QVector<TocEntry> tocs;
    for (quint32 i = 0; i < ntoc; ++i) {
        qsizetype tocOffset = 16 + i * 12;
        quint32 type = readU32(tocOffset);
        quint32 subtype = readU32(tocOffset + 4);
        quint32 position = readU32(tocOffset + 8);
        if (type == 0xfffd0002) { // XCUR_IMAGE_TYPE
            tocs.append({type, subtype, position});
        }
    }

    if (tocs.isEmpty()) return QImage();

    int bestDiff = 999999;
    TocEntry bestToc = tocs.first();
    for (const TocEntry& t : tocs) {
        int diff = std::abs(static_cast<int>(t.subtype) - targetSize);
        if (diff < bestDiff) {
            bestDiff = diff;
            bestToc = t;
        }
    }

    qsizetype imgPos = bestToc.position;
    quint32 cSize = readU32(imgPos);
    quint32 cType = readU32(imgPos + 4);
    quint32 cSubtype = readU32(imgPos + 8);
    quint32 cVersion = readU32(imgPos + 12);
    quint32 width = readU32(imgPos + 16);
    quint32 height = readU32(imgPos + 20);
    quint32 xhot = readU32(imgPos + 24);
    quint32 yhot = readU32(imgPos + 28);
    quint32 delay = readU32(imgPos + 32);

    if (width == 0 || height == 0 || width > 512 || height > 512) return QImage();
    qsizetype pixelOffset = imgPos + 36;
    qsizetype byteCount = static_cast<qsizetype>(width) * height * 4;
    if (pixelOffset + byteCount > data.size()) return QImage();

    QImage img(raw + pixelOffset, width, height, width * 4, QImage::Format_ARGB32_Premultiplied);
    return img.copy();
}

static QImage loadFromHlcFile(const QString& hlcPath, int targetSize) {
    if (!QFile::exists(hlcPath)) return QImage();

    // 1. Try extracting SVG from .hlc (zip archive)
    QProcess proc;
    proc.start(QStringLiteral("unzip"), {QStringLiteral("-p"), hlcPath, QStringLiteral("*.svg")});
    if (proc.waitForFinished(500) && proc.exitCode() == 0) {
        QByteArray svgData = proc.readAllStandardOutput();
        if (!svgData.isEmpty()) {
            QSvgRenderer renderer(svgData);
            if (renderer.isValid()) {
                QImage img(targetSize, targetSize, QImage::Format_ARGB32_Premultiplied);
                img.fill(Qt::transparent);
                QPainter p(&img);
                renderer.render(&p);
                return img;
            }
        }
    }

    // 2. Try extracting PNG from .hlc
    QProcess procPng;
    procPng.start(QStringLiteral("unzip"), {QStringLiteral("-p"), hlcPath, QStringLiteral("*.png")});
    if (procPng.waitForFinished(500) && procPng.exitCode() == 0) {
        QByteArray pngData = procPng.readAllStandardOutput();
        if (!pngData.isEmpty()) {
            QImage img;
            if (img.loadFromData(pngData)) {
                return img.scaled(targetSize, targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            }
        }
    }

    return QImage();
}

QImage CursorManager::loadCursorPreview(const QString& themeName, int targetSize) {
    const QStringList searchDirs = {
        QDir::homePath() + QStringLiteral("/.local/share/icons/") + themeName,
        QDir::homePath() + QStringLiteral("/.icons/") + themeName,
        QStringLiteral("/usr/share/icons/") + themeName,
        QStringLiteral("/usr/local/share/icons/") + themeName
    };

    const QStringList cursorNames = {
        QStringLiteral("left_ptr"), QStringLiteral("default"), QStringLiteral("arrow"),
        QStringLiteral("pointer"), QStringLiteral("top_left_arrow"), QStringLiteral("right_ptr")
    };

    // 1. Try Hyprcursor formats (.hlc zip or unpacked directory)
    for (const QString& themeDir : searchDirs) {
        if (!QDir(themeDir).exists()) continue;

        for (const QString& cName : cursorNames) {
            // A. Check .hlc zip archive
            const QString hlcFile = themeDir + QStringLiteral("/hyprcursors/") + cName + QStringLiteral(".hlc");
            if (QFile::exists(hlcFile)) {
                QImage img = loadFromHlcFile(hlcFile, targetSize);
                if (!img.isNull()) return img;
            }

            // B. Check unpacked hyprcursor directory
            const QString hyprCursorDir = themeDir + QStringLiteral("/hyprcursors/") + cName;
            if (QDir(hyprCursorDir).exists()) {
                QDir dir(hyprCursorDir);
                const QStringList svgs = dir.entryList({QStringLiteral("*.svg")}, QDir::Files);
                for (const QString& s : svgs) {
                    QSvgRenderer renderer(dir.filePath(s));
                    if (renderer.isValid()) {
                        QImage img(targetSize, targetSize, QImage::Format_ARGB32_Premultiplied);
                        img.fill(Qt::transparent);
                        QPainter p(&img);
                        renderer.render(&p);
                        return img;
                    }
                }

                const QStringList pngs = dir.entryList({QStringLiteral("*.png")}, QDir::Files);
                for (const QString& p : pngs) {
                    QImage img;
                    if (img.load(dir.filePath(p))) {
                        return img.scaled(targetSize, targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                    }
                }
            }
        }
    }

    // 2. Try XCursor left_ptr / default / arrow / pointer / top_left_arrow
    for (const QString& themeDir : searchDirs) {
        if (!QDir(themeDir).exists()) continue;

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

    // 3. Try theme-specific SVGs
    for (const QString& themeDir : searchDirs) {
        if (!QDir(themeDir).exists()) continue;
        const QString svgFile = themeDir + QStringLiteral("/left_ptr.svg");
        if (QFile::exists(svgFile)) {
            QSvgRenderer renderer(svgFile);
            if (renderer.isValid()) {
                QImage img(targetSize, targetSize, QImage::Format_ARGB32_Premultiplied);
                img.fill(Qt::transparent);
                QPainter p(&img);
                renderer.render(&p);
                return img;
            }
        }
    }

    // 4. Fallback: Render clean pointer shape
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

} // namespace FlightDeck::Managers
