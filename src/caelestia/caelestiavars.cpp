#include "caelestiavars.hpp"
#include "luavalidator.hpp"
#include "flightdeckwriter.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../hyprland/hyprlandschema.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

namespace FlightDeck::Caelestia {

CaelestiaVars* CaelestiaVars::instance() {
    static CaelestiaVars inst;
    return &inst;
}

CaelestiaVars* CaelestiaVars::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

QString CaelestiaVars::varsFilePath() {
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    const QString p1 = base + QStringLiteral("/caelestia/hypr-vars.lua");
    if (QFile::exists(p1)) return p1;
    const QString p2 = base + QStringLiteral("/hypr/hypr-vars.lua");
    if (QFile::exists(p2)) return p2;
    return p1;
}

QString CaelestiaVars::defaultVarsFilePath() {
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    const QString p1 = base + QStringLiteral("/hypr/variables.lua");
    if (QFile::exists(p1)) return p1;
    const QString p2 = base + QStringLiteral("/hypr/hyprland/variables.lua");
    if (QFile::exists(p2)) return p2;
    return p1;
}

QString CaelestiaVars::schemeFilePath() {
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    const QString p1 = base + QStringLiteral("/hypr/scheme/current.lua");
    if (QFile::exists(p1)) return p1;
    const QString p2 = base + QStringLiteral("/caelestia/scheme/current.lua");
    if (QFile::exists(p2)) return p2;
    return p1;
}

CaelestiaVars::CaelestiaVars(QObject* parent)
    : QObject(parent) {
    loadDefaults();
    loadFromFile();
}

QVariantList CaelestiaVars::schemeColors() const {
    return getSchemeColors();
}

QVariantList CaelestiaVars::getSchemeColors() const {
    QVariantList list;
    const QString path = schemeFilePath();
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return list;
    }

    const QString content = QString::fromUtf8(file.readAll());
    file.close();

    static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*\"([0-9a-fA-F]{6})\"\s*,?)"), QRegularExpression::MultilineOption);
    auto matchIt = lineRe.globalMatch(content);
    while (matchIt.hasNext()) {
        auto m = matchIt.next();
        const QString name = m.captured(1);
        const QString hex = m.captured(2);

        QVariantMap item;
        item[QStringLiteral("name")] = name;
        item[QStringLiteral("hex")] = hex;
        item[QStringLiteral("color")] = QStringLiteral("#") + hex;
        list.append(item);
    }
    return list;
}

QString CaelestiaVars::getSchemeHex(const QString& token) const {
    const QVariantList colors = getSchemeColors();
    for (const QVariant& c : colors) {
        const QVariantMap m = c.toMap();
        if (m.value(QStringLiteral("name")).toString() == token) {
            return m.value(QStringLiteral("hex")).toString();
        }
    }
    return QStringLiteral("9bd0cc"); // Fallback primary
}

QVariantMap CaelestiaVars::parseColor(const QString& colorStr) const {
    QVariantMap res;
    QString clean = colorStr.trimmed();

    // Pattern 1: scheme.<token> .. "<alphaHex>" (e.g. "rgba(" .. scheme.shadow .. "60)" or rgba(" .. scheme.shadow .. "60)")
    static const QRegularExpression schemeRe(QStringLiteral(R"(scheme\.([a-zA-Z0-9_]+)\s*\.\.\s*\"([0-9a-fA-F]{2})\")"));
    auto sm = schemeRe.match(clean);
    if (sm.hasMatch()) {
        QString token = sm.captured(1);
        QString alphaHex = sm.captured(2);
        bool ok = false;
        int alphaVal = alphaHex.toInt(&ok, 16);
        int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;
        QString hex = getSchemeHex(token);

        res[QStringLiteral("isScheme")] = true;
        res[QStringLiteral("token")] = token;
        res[QStringLiteral("hex")] = hex;
        res[QStringLiteral("alphaPercent")] = alphaPercent;
        res[QStringLiteral("alphaHex")] = alphaHex;
        res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
        res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(\" .. scheme.%1 .. \"%2)\"").arg(token, alphaHex);
        return res;
    }

    // Pattern 2: rgba(RRGGBBAA) or rgba("RRGGBBAA") or "rgba(RRGGBBAA)"
    static const QRegularExpression rgbaRe(QStringLiteral(R"(rgba\(\"?([0-9a-fA-F]{6})([0-9a-fA-F]{2})\"?\))"));
    auto rm = rgbaRe.match(clean);
    if (rm.hasMatch()) {
        QString hex = rm.captured(1);
        QString alphaHex = rm.captured(2);
        bool ok = false;
        int alphaVal = alphaHex.toInt(&ok, 16);
        int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;

        res[QStringLiteral("isScheme")] = false;
        res[QStringLiteral("token")] = QString();
        res[QStringLiteral("hex")] = hex;
        res[QStringLiteral("alphaPercent")] = alphaPercent;
        res[QStringLiteral("alphaHex")] = alphaHex;
        res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
        res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1%2)\"").arg(hex, alphaHex);
        return res;
    }

    // Pattern 3: #RRGGBBAA or #RRGGBB
    if (clean.startsWith(QLatin1Char('#')) || (clean.startsWith(QLatin1Char('"')) && clean.contains(QLatin1Char('#')))) {
        QString raw = clean;
        raw.remove(QLatin1Char('"'));
        raw.remove(QLatin1Char('\''));
        raw.remove(QLatin1Char('#'));
        if (raw.length() >= 8) {
            QString hex = raw.left(6);
            QString alphaHex = raw.mid(6, 2);
            bool ok = false;
            int alphaVal = alphaHex.toInt(&ok, 16);
            int alphaPercent = ok ? qBound(0, qRound(alphaVal / 2.55), 100) : 100;

            res[QStringLiteral("isScheme")] = false;
            res[QStringLiteral("token")] = QString();
            res[QStringLiteral("hex")] = hex;
            res[QStringLiteral("alphaPercent")] = alphaPercent;
            res[QStringLiteral("alphaHex")] = alphaHex;
            res[QStringLiteral("previewColor")] = QStringLiteral("#") + alphaHex + hex;
            res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1%2)\"").arg(hex, alphaHex);
            return res;
        } else if (raw.length() >= 6) {
            QString hex = raw.left(6);
            res[QStringLiteral("isScheme")] = false;
            res[QStringLiteral("token")] = QString();
            res[QStringLiteral("hex")] = hex;
            res[QStringLiteral("alphaPercent")] = 100;
            res[QStringLiteral("alphaHex")] = QStringLiteral("ff");
            res[QStringLiteral("previewColor")] = QStringLiteral("#ff") + hex;
            res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(%1ff)\"").arg(hex);
            return res;
        }
    }

    // Fallback default
    res[QStringLiteral("isScheme")] = true;
    res[QStringLiteral("token")] = QStringLiteral("shadow");
    res[QStringLiteral("hex")] = getSchemeHex(QStringLiteral("shadow"));
    res[QStringLiteral("alphaPercent")] = 38;
    res[QStringLiteral("alphaHex")] = QStringLiteral("60");
    res[QStringLiteral("previewColor")] = QStringLiteral("#60") + res[QStringLiteral("hex")].toString();
    res[QStringLiteral("formatted")] = QStringLiteral("\"rgba(\" .. scheme.shadow .. \"60)\"");
    return res;
}

QString CaelestiaVars::formatColor(bool isScheme, const QString& tokenOrHex, int alphaPercent) const {
    int clampedAlpha = qBound(0, alphaPercent, 100);
    int alphaVal = qBound(0, qRound(clampedAlpha * 2.55), 255);
    QString alphaHex = QStringLiteral("%1").arg(alphaVal, 2, 16, QLatin1Char('0')).toLower();

    if (isScheme) {
        return QStringLiteral("\"rgba(\" .. scheme.%1 .. \"%2)\"").arg(tokenOrHex, alphaHex);
    }

    QString cleanHex = tokenOrHex.trimmed();
    if (cleanHex.startsWith(QLatin1Char('#'))) {
        cleanHex.remove(0, 1);
    }
    if (cleanHex.length() > 6) {
        cleanHex = cleanHex.left(6);
    }
    return QStringLiteral("\"rgba(%1%2)\"").arg(cleanHex, alphaHex);
}

QVariantList CaelestiaVars::sections() const {
    return m_sections;
}

QVariantMap CaelestiaVars::getVariableSchema(const QString& key) const {
    return m_schemaOptions.value(key).toMap();
}

void CaelestiaVars::loadDefaults() {
    m_defaults.clear();
    m_sections.clear();
    m_schemaOptions.clear();

    QStringList candidatePaths = {
        QStringLiteral(":/schema/caelestia_variables.json"),
        QStringLiteral("/home/dim/Projects/AstraSuite/FlightDeck/data/schema/caelestia_variables.json")
    };

    QByteArray schemaData;
    for (const auto& path : candidatePaths) {
        QFile file(path);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            schemaData = file.readAll();
            break;
        }
    }

    if (!schemaData.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(schemaData);
        if (doc.isObject()) {
            QJsonObject root = doc.object();
            if (root.contains(QStringLiteral("sections"))) {
                QJsonArray sections = root.value(QStringLiteral("sections")).toArray();
                for (const auto& sVal : sections) {
                    QJsonObject sObj = sVal.toObject();
                    m_sections.append(sObj.toVariantMap());
                    if (sObj.contains(QStringLiteral("options"))) {
                        QJsonArray opts = sObj.value(QStringLiteral("options")).toArray();
                        for (const auto& optVal : opts) {
                            QJsonObject optObj = optVal.toObject();
                            QString key = optObj.value(QStringLiteral("key")).toString();
                            if (!key.isEmpty()) {
                                m_schemaOptions[key] = optObj.toVariantMap();
                                m_defaults[key] = optObj.value(QStringLiteral("default")).toVariant();
                            }
                        }
                    }
                }
            }
        }
    }

    emit schemaLoaded();

    const QString defPath = defaultVarsFilePath();
    QFile defFile(defPath);
    if (defFile.exists() && defFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QString content = QString::fromUtf8(defFile.readAll());
        defFile.close();

        static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?\s*(--.*)?$)"), QRegularExpression::MultilineOption);
        auto matchIt = lineRe.globalMatch(content);
        while (matchIt.hasNext()) {
            auto m = matchIt.next();
            const QString key = m.captured(1);
            QString valStr = m.captured(2).trimmed();
            if (valStr.endsWith(QLatin1Char(','))) {
                valStr.chop(1);
                valStr = valStr.trimmed();
            }

            if (valStr.contains(QLatin1String("scheme.")) || valStr.contains(QLatin1String("..")) || valStr.startsWith(QLatin1String("rgba("))) {
                m_defaults[key] = valStr;
            } else if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
                m_defaults[key] = valStr.mid(1, valStr.length() - 2);
            } else if (valStr == QStringLiteral("true")) {
                m_defaults[key] = true;
            } else if (valStr == QStringLiteral("false")) {
                m_defaults[key] = false;
            } else if (valStr.startsWith(QLatin1Char('{')) && valStr.endsWith(QLatin1Char('}'))) {
                QString inner = valStr.mid(1, valStr.length() - 2).trimmed();
                QStringList items;
                static const QRegularExpression strItemRe(QStringLiteral(R"(\"([^\"]*)\")"));
                auto itemIt = strItemRe.globalMatch(inner);
                while (itemIt.hasNext()) {
                    items.append(itemIt.next().captured(1));
                }
                m_defaults[key] = items;
            } else {
                bool ok = false;
                double d = valStr.toDouble(&ok);
                if (ok) {
                    if (valStr.contains(QLatin1Char('.'))) {
                        m_defaults[key] = d;
                    } else {
                        m_defaults[key] = valStr.toLongLong();
                    }
                } else {
                    m_defaults[key] = valStr;
                }
            }
        }
    }

    auto mirrorAliases = [](QVariantMap& map) {
        if (map.contains(QStringLiteral("shadowColour")) && !map.contains(QStringLiteral("shadowColor"))) {
            map[QStringLiteral("shadowColor")] = map[QStringLiteral("shadowColour")];
        } else if (map.contains(QStringLiteral("shadowColor")) && !map.contains(QStringLiteral("shadowColour"))) {
            map[QStringLiteral("shadowColour")] = map[QStringLiteral("shadowColor")];
        }

        if (map.contains(QStringLiteral("inactiveShadowColour")) && !map.contains(QStringLiteral("inactiveShadowColor"))) {
            map[QStringLiteral("inactiveShadowColor")] = map[QStringLiteral("inactiveShadowColour")];
        } else if (map.contains(QStringLiteral("inactiveShadowColor")) && !map.contains(QStringLiteral("inactiveShadowColour"))) {
            map[QStringLiteral("inactiveShadowColour")] = map[QStringLiteral("inactiveShadowColor")];
        }

        if (map.contains(QStringLiteral("activeWindowBorderColour")) && !map.contains(QStringLiteral("activeWindowBorderColor"))) {
            map[QStringLiteral("activeWindowBorderColor")] = map[QStringLiteral("activeWindowBorderColour")];
        } else if (map.contains(QStringLiteral("activeWindowBorderColor")) && !map.contains(QStringLiteral("activeWindowBorderColour"))) {
            map[QStringLiteral("activeWindowBorderColour")] = map[QStringLiteral("activeWindowBorderColor")];
        }

        if (map.contains(QStringLiteral("inactiveWindowBorderColour")) && !map.contains(QStringLiteral("inactiveWindowBorderColor"))) {
            map[QStringLiteral("inactiveWindowBorderColor")] = map[QStringLiteral("inactiveWindowBorderColour")];
        } else if (map.contains(QStringLiteral("inactiveWindowBorderColor")) && !map.contains(QStringLiteral("inactiveWindowBorderColour"))) {
            map[QStringLiteral("inactiveWindowBorderColour")] = map[QStringLiteral("inactiveWindowBorderColor")];
        }
    };
    mirrorAliases(m_defaults);
}

void CaelestiaVars::loadFromFile() {
    m_savedVars.clear();
    m_pendingVars.clear();

    const QString path = varsFilePath();
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit varsChanged();
        emit pendingChanged();
        emit dirtyChanged();
        return;
    }

    const QString content = QString::fromUtf8(file.readAll());
    file.close();

    static const QRegularExpression lineRe(QStringLiteral(R"(^\s*([a-zA-Z0-9_]+)\s*=\s*(.+?)\s*,?\s*(--.*)?$)"), QRegularExpression::MultilineOption);
    auto matchIt = lineRe.globalMatch(content);
    while (matchIt.hasNext()) {
        auto m = matchIt.next();
        const QString key = m.captured(1);
        QString valStr = m.captured(2).trimmed();
        if (valStr.endsWith(QLatin1Char(','))) {
            valStr.chop(1);
            valStr = valStr.trimmed();
        }

        if (valStr.contains(QLatin1String("scheme.")) || valStr.contains(QLatin1String("..")) || valStr.startsWith(QLatin1String("rgba("))) {
            m_savedVars[key] = valStr;
        } else if (valStr.startsWith(QLatin1Char('"')) && valStr.endsWith(QLatin1Char('"'))) {
            m_savedVars[key] = valStr.mid(1, valStr.length() - 2);
        } else if (valStr == QStringLiteral("true")) {
            m_savedVars[key] = true;
        } else if (valStr == QStringLiteral("false")) {
            m_savedVars[key] = false;
        } else if (valStr.startsWith(QLatin1Char('{')) && valStr.endsWith(QLatin1Char('}'))) {
            QString inner = valStr.mid(1, valStr.length() - 2).trimmed();
            QStringList items;
            static const QRegularExpression strItemRe(QStringLiteral(R"(\"([^\"]*)\")"));
            auto itemIt = strItemRe.globalMatch(inner);
            while (itemIt.hasNext()) {
                items.append(itemIt.next().captured(1));
            }
            m_savedVars[key] = items;
        } else {
            bool ok = false;
            double d = valStr.toDouble(&ok);
            if (ok) {
                if (valStr.contains(QLatin1Char('.'))) {
                    m_savedVars[key] = d;
                } else {
                    m_savedVars[key] = valStr.toLongLong();
                }
            } else {
                m_savedVars[key] = valStr;
            }
        }
    }

    auto mirrorAliases = [](QVariantMap& map) {
        if (map.contains(QStringLiteral("shadowColour")) && !map.contains(QStringLiteral("shadowColor"))) {
            map[QStringLiteral("shadowColor")] = map[QStringLiteral("shadowColour")];
        } else if (map.contains(QStringLiteral("shadowColor")) && !map.contains(QStringLiteral("shadowColour"))) {
            map[QStringLiteral("shadowColour")] = map[QStringLiteral("shadowColor")];
        }

        if (map.contains(QStringLiteral("inactiveShadowColour")) && !map.contains(QStringLiteral("inactiveShadowColor"))) {
            map[QStringLiteral("inactiveShadowColor")] = map[QStringLiteral("inactiveShadowColour")];
        } else if (map.contains(QStringLiteral("inactiveShadowColor")) && !map.contains(QStringLiteral("inactiveShadowColour"))) {
            map[QStringLiteral("inactiveShadowColour")] = map[QStringLiteral("inactiveShadowColor")];
        }

        if (map.contains(QStringLiteral("activeWindowBorderColour")) && !map.contains(QStringLiteral("activeWindowBorderColor"))) {
            map[QStringLiteral("activeWindowBorderColor")] = map[QStringLiteral("activeWindowBorderColour")];
        } else if (map.contains(QStringLiteral("activeWindowBorderColor")) && !map.contains(QStringLiteral("activeWindowBorderColour"))) {
            map[QStringLiteral("activeWindowBorderColour")] = map[QStringLiteral("activeWindowBorderColor")];
        }

        if (map.contains(QStringLiteral("inactiveWindowBorderColour")) && !map.contains(QStringLiteral("inactiveWindowBorderColor"))) {
            map[QStringLiteral("inactiveWindowBorderColor")] = map[QStringLiteral("inactiveWindowBorderColour")];
        } else if (map.contains(QStringLiteral("inactiveWindowBorderColor")) && !map.contains(QStringLiteral("inactiveWindowBorderColour"))) {
            map[QStringLiteral("inactiveWindowBorderColour")] = map[QStringLiteral("inactiveWindowBorderColor")];
        }
    };
    mirrorAliases(m_savedVars);

    m_pendingVars.clear();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::syncFromHyprland() {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket) return;

    auto queryOpt = [&](const QString& optName) -> QJsonObject {
        QJsonDocument doc = socket->queryJson(QStringLiteral("j/getoption %1").arg(optName));
        return doc.object();
    };

    QJsonObject obj = queryOpt(QStringLiteral("general:border_size"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowBorderSize")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:rounding"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowRounding")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("general:gaps_in"));
    if (obj.contains(QStringLiteral("custom"))) {
        m_savedVars[QStringLiteral("windowGapsIn")] = obj[QStringLiteral("custom")].toString().toInt();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowGapsIn")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("general:gaps_out"));
    if (obj.contains(QStringLiteral("custom"))) {
        m_savedVars[QStringLiteral("windowGapsOut")] = obj[QStringLiteral("custom")].toString().toInt();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("windowGapsOut")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:active_opacity"));
    if (obj.contains(QStringLiteral("float"))) {
        m_savedVars[QStringLiteral("windowOpacity")] = obj[QStringLiteral("float")].toDouble();
    }

    obj = queryOpt(QStringLiteral("decoration:blur:enabled"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurEnabled")] = (obj[QStringLiteral("int")].toInt() != 0);
    }

    obj = queryOpt(QStringLiteral("decoration:blur:size"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurSize")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:blur:passes"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("blurPasses")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("decoration:shadow:enabled"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("shadowEnabled")] = (obj[QStringLiteral("int")].toInt() != 0);
    }

    obj = queryOpt(QStringLiteral("decoration:shadow:range"));
    if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("shadowRange")] = obj[QStringLiteral("int")].toInt();
    }

    obj = queryOpt(QStringLiteral("input:touchpad:disable_while_typing"));
    if (obj.contains(QStringLiteral("bool"))) {
        m_savedVars[QStringLiteral("touchpadDisableTyping")] = obj[QStringLiteral("bool")].toBool();
    } else if (obj.contains(QStringLiteral("int"))) {
        m_savedVars[QStringLiteral("touchpadDisableTyping")] = (obj[QStringLiteral("int")].toInt() != 0);
    }
}

void CaelestiaVars::applyKeywordToHyprland(const QString& key, const QVariant& value) {
    auto socket = Hyprland::HyprlandSocket::instance();
    if (!socket || !socket->isOnline()) return;

    // 1. Check Caelestia schema descriptors
    if (m_schemaOptions.contains(key)) {
        const QVariantMap opt = m_schemaOptions.value(key).toMap();
        const QString hyprKeyword = opt.value(QStringLiteral("hyprKeyword")).toString();
        const QString format = opt.value(QStringLiteral("format")).toString();

        if (format == QStringLiteral("cursor_theme") || format == QStringLiteral("cursor_size")) {
            QString theme = m_savedVars.value(QStringLiteral("cursorTheme"), m_defaults.value(QStringLiteral("cursorTheme"))).toString();
            int size = m_savedVars.value(QStringLiteral("cursorSize"), m_defaults.value(QStringLiteral("cursorSize"))).toInt();
            if (key == QStringLiteral("cursorTheme")) theme = value.toString();
            if (key == QStringLiteral("cursorSize")) size = value.toInt();
            socket->setCursor(theme, size);
            if (!hyprKeyword.isEmpty()) {
                socket->send(QStringLiteral("keyword %1 %2").arg(hyprKeyword, QString::number(size)));
            }
            return;
        }

        if (format == QStringLiteral("single_window_gaps_out")) {
            socket->send(QStringLiteral("keyword workspace w[tv1]s[false], gapsout:%1").arg(value.toInt()));
            socket->send(QStringLiteral("keyword workspace f[1]s[false], gapsout:%1").arg(value.toInt()));
            return;
        }

        if (format == QStringLiteral("window_opacity_rule")) {
            socket->send(QStringLiteral("keyword windowrule opacity %1 override, match:fullscreen false").arg(QString::number(value.toDouble(), 'f', 2)));
            return;
        }

        if (format == QStringLiteral("color_argb_hex") && !hyprKeyword.isEmpty()) {
            QVariantMap parsed = parseColor(value.toString());
            QString hex = parsed.value(QStringLiteral("hex")).toString();
            QString alpha = parsed.value(QStringLiteral("alphaHex")).toString();
            socket->send(QStringLiteral("keyword %1 0x%2%3").arg(hyprKeyword, alpha, hex));
            return;
        }

        if (!hyprKeyword.isEmpty()) {
            QString valStr;
            if (value.typeId() == QMetaType::Bool) {
                valStr = value.toBool() ? QStringLiteral("1") : QStringLiteral("0");
            } else if (value.typeId() == QMetaType::Double || value.typeId() == QMetaType::Float) {
                valStr = QString::number(value.toDouble(), 'g', 4);
            } else {
                valStr = value.toString();
            }
            socket->send(QStringLiteral("keyword %1 %2").arg(hyprKeyword, valStr));
            return;
        }
    }

    // 2. Check Hyprland schema options (native & plugins)
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    QString canonicalKey = schema->toHyprKey(key);

    if (schema->hasOption(canonicalKey)) {
        FlightDeckWriter::instance()->setHyprOption(canonicalKey, value);

        QString valStr;
        if (value.typeId() == QMetaType::Bool) {
            valStr = value.toBool() ? QStringLiteral("1") : QStringLiteral("0");
        } else {
            valStr = value.toString();
        }
        socket->send(QStringLiteral("keyword %1 %2").arg(canonicalKey, valStr));
    } else {
        socket->keyword(key, value);
    }
}

bool CaelestiaVars::isDirty() const {
    return !m_pendingVars.isEmpty();
}

int CaelestiaVars::dirtyCount() const {
    return m_pendingVars.size();
}

QStringList CaelestiaVars::pendingKeys() const {
    return m_pendingVars.keys();
}

QVariantMap CaelestiaVars::currentVars() const {
    QVariantMap map = m_savedVars;
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    const QVariantMap hyprOpts = FlightDeckWriter::instance()->hyprOptions();
    for (auto it = hyprOpts.constBegin(); it != hyprOpts.constEnd(); ++it) {
        map[it.key()] = it.value();
        QString shortKey = schema->toShortKey(it.key());
        if (!shortKey.isEmpty()) {
            map[shortKey] = it.value();
        }
    }
    return map;
}

QVariantMap CaelestiaVars::pendingVars() const {
    return m_pendingVars;
}

QVariant CaelestiaVars::get(const QString& key, const QVariant& fallback) const {
    if (m_pendingVars.contains(key)) {
        return m_pendingVars.value(key);
    }
    if (m_savedVars.contains(key)) {
        return m_savedVars.value(key);
    }
    if (FlightDeckWriter::instance()->hasHyprOption(key)) {
        return FlightDeckWriter::instance()->getHyprOption(key);
    }
    if (m_defaults.contains(key)) {
        return m_defaults.value(key);
    }
    if (FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(key)) {
        return FlightDeck::Hyprland::HyprlandSchema::instance()->getDefault(key, fallback);
    }
    return fallback;
}

QVariant CaelestiaVars::getDefault(const QString& key, const QVariant& fallback) const {
    if (m_defaults.contains(key)) {
        return m_defaults.value(key);
    }
    if (FlightDeck::Hyprland::HyprlandSchema::instance()->hasOption(key)) {
        return FlightDeck::Hyprland::HyprlandSchema::instance()->getDefault(key, fallback);
    }
    return fallback;
}

bool CaelestiaVars::isOverridden(const QString& key) const {
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    QString canonicalKey = schema->toHyprKey(key);
    QString shortKey = schema->toShortKey(canonicalKey);
    return m_savedVars.contains(key) || m_savedVars.contains(canonicalKey) || m_savedVars.contains(shortKey)
        || m_pendingVars.contains(key) || m_pendingVars.contains(canonicalKey) || m_pendingVars.contains(shortKey)
        || FlightDeckWriter::instance()->hasHyprOption(canonicalKey) || FlightDeckWriter::instance()->hasHyprOption(key);
}

void CaelestiaVars::set(const QString& key, const QVariant& value) {
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    QString canonicalKey = schema->toHyprKey(key);
    QString shortKey = schema->toShortKey(canonicalKey);

    m_savedVars[key] = value;
    if (!canonicalKey.isEmpty()) m_savedVars[canonicalKey] = value;
    if (!shortKey.isEmpty()) m_savedVars[shortKey] = value;

    m_pendingVars.remove(key);
    if (!canonicalKey.isEmpty()) m_pendingVars.remove(canonicalKey);
    if (!shortKey.isEmpty()) m_pendingVars.remove(shortKey);

    auto syncAlias = [&](const QString& k1, const QString& k2) {
        if (key == k1) {
            m_savedVars[k2] = value;
            m_pendingVars.remove(k2);
        } else if (key == k2) {
            m_savedVars[k1] = value;
            m_pendingVars.remove(k1);
        }
    };
    syncAlias(QStringLiteral("shadowColour"), QStringLiteral("shadowColor"));
    syncAlias(QStringLiteral("inactiveShadowColour"), QStringLiteral("inactiveShadowColor"));
    syncAlias(QStringLiteral("activeWindowBorderColour"), QStringLiteral("activeWindowBorderColor"));
    syncAlias(QStringLiteral("inactiveWindowBorderColour"), QStringLiteral("inactiveWindowBorderColor"));

    if (schema->hasOption(canonicalKey)) {
        FlightDeckWriter::instance()->setHyprOption(canonicalKey, value);
    }

    applyKeywordToHyprland(key, value);
    save();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::setVar(const QString& key, const QVariant& value) {
    set(key, value);
}

void CaelestiaVars::resetKey(const QString& key) {
    if (m_pendingVars.contains(key)) {
        m_pendingVars.remove(key);
        emit pendingChanged();
        emit dirtyChanged();
    }
}

void CaelestiaVars::remove(const QString& key) {
    m_savedVars.remove(key);
    m_pendingVars.remove(key);
    save();
    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::resetToDefault(const QString& key) {
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    QString canonicalKey = schema->toHyprKey(key);
    QString shortKey = schema->toShortKey(canonicalKey);

    m_savedVars.remove(key);
    if (!canonicalKey.isEmpty()) m_savedVars.remove(canonicalKey);
    if (!shortKey.isEmpty()) m_savedVars.remove(shortKey);

    m_pendingVars.remove(key);
    if (!canonicalKey.isEmpty()) m_pendingVars.remove(canonicalKey);
    if (!shortKey.isEmpty()) m_pendingVars.remove(shortKey);

    auto removeAlias = [&](const QString& k1, const QString& k2) {
        if (key == k1) {
            m_savedVars.remove(k2);
            m_pendingVars.remove(k2);
        } else if (key == k2) {
            m_savedVars.remove(k1);
            m_pendingVars.remove(k1);
        }
    };
    removeAlias(QStringLiteral("shadowColour"), QStringLiteral("shadowColor"));
    removeAlias(QStringLiteral("inactiveShadowColour"), QStringLiteral("inactiveShadowColor"));
    removeAlias(QStringLiteral("activeWindowBorderColour"), QStringLiteral("activeWindowBorderColor"));
    removeAlias(QStringLiteral("inactiveWindowBorderColour"), QStringLiteral("inactiveWindowBorderColor"));

    FlightDeckWriter::instance()->removeHyprOption(canonicalKey);
    FlightDeckWriter::instance()->removeHyprOption(key);
    FlightDeckWriter::instance()->save();

    save();

    QVariant defaultVal = getDefault(key);
    if (!defaultVal.isNull() && defaultVal.isValid()) {
        applyKeywordToHyprland(canonicalKey.isEmpty() ? key : canonicalKey, defaultVal);
    }

    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
}

void CaelestiaVars::discardAll() {
    m_pendingVars.clear();
    emit pendingChanged();
    emit dirtyChanged();
}

QStringList CaelestiaVars::getBinds(const QString& key) const {
    const QVariant val = get(key);
    if (val.typeId() == QMetaType::QVariantList || val.typeId() == QMetaType::QStringList) {
        return val.toStringList();
    }
    const QString str = val.toString();
    return str.isEmpty() ? QStringList() : QStringList{ str };
}

void CaelestiaVars::setBinds(const QString& key, const QStringList& binds) {
    if (binds.size() == 1) {
        set(key, binds.first());
    } else {
        set(key, QVariant::fromValue(binds));
    }
}

QString CaelestiaVars::formatLua() const {
    QVariantMap fullVars = m_savedVars;
    for (auto it = m_pendingVars.constBegin(); it != m_pendingVars.constEnd(); ++it) {
        fullVars[it.key()] = it.value();
    }

    QString out;
    out += QStringLiteral("local scheme = require(\"scheme.current\")\n\n");
    out += QStringLiteral("return {\n");

    auto writeSection = [&out, &fullVars](const QString& title, const QStringList& keys) {
        out += QStringLiteral("    -- ") + title + QStringLiteral("\n");
        for (const QString& key : keys) {
            if (!fullVars.contains(key)) continue;

            const QVariant val = fullVars.value(key);
            QString valStr;
            if (val.typeId() == QMetaType::Bool) {
                valStr = val.toBool() ? QStringLiteral("true") : QStringLiteral("false");
            } else if (val.typeId() == QMetaType::QVariantList || val.typeId() == QMetaType::QStringList) {
                QStringList items;
                const QStringList rawList = val.toStringList();
                for (const QString& s : rawList) {
                    items.append(QStringLiteral("\"") + s + QStringLiteral("\""));
                }
                valStr = QStringLiteral("{ ") + items.join(QStringLiteral(", ")) + QStringLiteral(" }");
            } else if (key == QStringLiteral("windowOpacity")) {
                valStr = QString::number(val.toDouble(), 'f', 2);
            } else if (key == QStringLiteral("touchpadScrollFactor")) {
                valStr = QString::number(val.toDouble(), 'g', 4);
            } else if (val.typeId() == QMetaType::Double || val.typeId() == QMetaType::Float) {
                if (val.toDouble() == std::floor(val.toDouble())) {
                    valStr = QString::number(static_cast<qint64>(std::round(val.toDouble())));
                } else {
                    valStr = QString::number(val.toDouble(), 'g', 6);
                }
            } else if (val.typeId() == QMetaType::Int || val.typeId() == QMetaType::LongLong || val.typeId() == QMetaType::UInt || val.typeId() == QMetaType::ULongLong) {
                valStr = QString::number(val.toLongLong());
            } else {
                const QString s = val.toString();
                if (s.startsWith(QLatin1String("\"")) && s.endsWith(QLatin1String("\""))) {
                    valStr = s;
                } else if (s.contains(QLatin1String("..")) || s.contains(QLatin1String("scheme."))) {
                    // String contains lua variable concatenation
                    valStr = s;
                } else {
                    valStr = QStringLiteral("\"") + s + QStringLiteral("\"");
                }
            }

            const QString padding = QString(static_cast<qsizetype>(std::max(1, static_cast<int>(28 - key.length()))), QLatin1Char(' '));
            out += QStringLiteral("    %1%2= %3,\n").arg(key, padding, valStr);
        }
        out += QStringLiteral("\n");
    };

    for (const auto& sVal : m_sections) {
        const QVariantMap sec = sVal.toMap();
        const QString title = sec.value(QStringLiteral("label")).toString();
        const QVariantList opts = sec.value(QStringLiteral("options")).toList();
        QStringList keys;
        for (const auto& oVal : opts) {
            keys.append(oVal.toMap().value(QStringLiteral("key")).toString());
        }
        if (!keys.isEmpty()) {
            writeSection(title, keys);
        }
    }

    out += QStringLiteral("}\n");
    return out;
}

bool CaelestiaVars::save() {
    const QString path = varsFilePath();
    const QFileInfo fi(path);
    if (!fi.dir().exists()) {
        fi.dir().mkpath(QStringLiteral("."));
    }

    const QString lua = formatLua();
    QString validationError;
    if (!LuaValidator::validate(lua, &validationError)) {
        qWarning() << "Lua validation failed for hypr-vars.lua:" << validationError;
        emit saveFailed(QStringLiteral("Lua syntax error: %1").arg(validationError));
        return false;
    }

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        emit saveFailed(file.errorString());
        return false;
    }

    file.write(lua.toUtf8());
    file.close();

    // Also persist native Hyprland options into astra-flightdeck.lua
    FlightDeckWriter::instance()->save();

    for (auto it = m_pendingVars.constBegin(); it != m_pendingVars.constEnd(); ++it) {
        m_savedVars[it.key()] = it.value();
    }
    m_pendingVars.clear();

    emit varsChanged();
    emit pendingChanged();
    emit dirtyChanged();
    emit saveSucceeded();
    return true;
}

void CaelestiaVars::reload() {
    loadFromFile();
}

} // namespace FlightDeck::Caelestia
