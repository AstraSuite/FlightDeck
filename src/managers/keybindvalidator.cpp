#include "keybindvalidator.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../caelestia/flightdeckwriter.hpp"
#include "../hyprland/hyprlandschema.hpp"

#include <QRegularExpression>
#include <QSet>
#include <algorithm>

namespace FlightDeck::Managers {

KeybindValidator* KeybindValidator::instance() {
    static KeybindValidator inst;
    return &inst;
}

KeybindValidator* KeybindValidator::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

KeybindValidator::KeybindValidator(QObject* parent)
    : QObject(parent) {
    auto vars = Caelestia::CaelestiaVars::instance();
    auto writer = Caelestia::FlightDeckWriter::instance();

    connect(vars, &Caelestia::CaelestiaVars::varsChanged, this, &KeybindValidator::refresh);
    connect(vars, &Caelestia::CaelestiaVars::pendingChanged, this, &KeybindValidator::refresh);
    connect(writer, &Caelestia::FlightDeckWriter::customBindsChanged, this, &KeybindValidator::refresh);

    refresh();
}

QVariantList KeybindValidator::conflicts() const {
    return m_conflicts;
}

QVariantList KeybindValidator::trueConflicts() const {
    return m_trueConflicts;
}

QVariantList KeybindValidator::overrides() const {
    return m_overrides;
}

int KeybindValidator::conflictCount() const {
    return m_trueConflicts.size();
}

int KeybindValidator::trueConflictCount() const {
    return m_trueConflicts.size();
}

int KeybindValidator::overrideCount() const {
    return m_overrides.size();
}

QString KeybindValidator::normalizeChord(const QVariant& keyVal, const QString& explicitMainMod) const {
    QStringList tokens;

    if (keyVal.typeId() == QMetaType::QVariantList || keyVal.typeId() == QMetaType::QStringList) {
        const QVariantList list = keyVal.toList();
        for (const auto& item : list) {
            QString s = item.toString().trimmed();
            if (!s.isEmpty()) {
                tokens.append(s);
            }
        }
    } else {
        QString s = keyVal.toString().trimmed();
        if (s.isEmpty()) return QString();

        // Split on +, ,, or whitespace
        const QStringList rawTokens = s.split(QRegularExpression(QStringLiteral("[,+\\s]+")), Qt::SkipEmptyParts);
        for (const auto& t : rawTokens) {
            QString clean = t.trimmed();
            if (!clean.isEmpty()) tokens.append(clean);
        }
    }

    if (tokens.isEmpty()) return QString();

    QString resolvedMainMod = explicitMainMod;
    if (resolvedMainMod.isEmpty()) {
        QVariant mm = Caelestia::CaelestiaVars::instance()->get(QStringLiteral("mainMod"));
        if (!mm.isNull() && !mm.toString().isEmpty()) {
            resolvedMainMod = mm.toString().toUpper().trimmed();
        } else {
            resolvedMainMod = QStringLiteral("SUPER");
        }
    }

    QSet<QString> modifiers;
    QString keyToken;

    for (int i = 0; i < tokens.size(); ++i) {
        QString token = tokens[i].toUpper().trimmed();

        // Replace $mainMod
        if (token == QStringLiteral("$MAINMOD") || token == QStringLiteral("MAINMOD")) {
            token = resolvedMainMod;
        }

        if (token == QStringLiteral("SUPER") || token == QStringLiteral("SUPER_L") ||
            token == QStringLiteral("SUPER_R") || token == QStringLiteral("WIN") ||
            token == QStringLiteral("LOGO") || token == QStringLiteral("MOD4")) {
            modifiers.insert(QStringLiteral("SUPER"));
        } else if (token == QStringLiteral("CTRL") || token == QStringLiteral("CONTROL") ||
                   token == QStringLiteral("CONTROL_L") || token == QStringLiteral("CONTROL_R")) {
            modifiers.insert(QStringLiteral("CTRL"));
        } else if (token == QStringLiteral("ALT") || token == QStringLiteral("ALT_L") ||
                   token == QStringLiteral("ALT_R") || token == QStringLiteral("META") ||
                   token == QStringLiteral("MOD1")) {
            modifiers.insert(QStringLiteral("ALT"));
        } else if (token == QStringLiteral("SHIFT") || token == QStringLiteral("SHIFT_L") ||
                   token == QStringLiteral("SHIFT_R")) {
            modifiers.insert(QStringLiteral("SHIFT"));
        } else {
            // Main key or mouse button
            if (token == QStringLiteral("ENTER") || token == QStringLiteral("RETURN")) {
                keyToken = QStringLiteral("RETURN");
            } else if (token == QStringLiteral("ESC") || token == QStringLiteral("ESCAPE")) {
                keyToken = QStringLiteral("ESCAPE");
            } else if (token == QStringLiteral("SPACE")) {
                keyToken = QStringLiteral("SPACE");
            } else if (token == QStringLiteral("BACKSPACE")) {
                keyToken = QStringLiteral("BACKSPACE");
            } else if (token == QStringLiteral("TAB")) {
                keyToken = QStringLiteral("TAB");
            } else {
                keyToken = token;
            }
        }
    }

    if (keyToken.isEmpty()) return QString();

    QStringList sortedMods;
    if (modifiers.contains(QStringLiteral("SUPER"))) sortedMods.append(QStringLiteral("SUPER"));
    if (modifiers.contains(QStringLiteral("CTRL"))) sortedMods.append(QStringLiteral("CTRL"));
    if (modifiers.contains(QStringLiteral("ALT"))) sortedMods.append(QStringLiteral("ALT"));
    if (modifiers.contains(QStringLiteral("SHIFT"))) sortedMods.append(QStringLiteral("SHIFT"));

    sortedMods.append(keyToken);
    return sortedMods.join(QLatin1Char('+'));
}

void KeybindValidator::analyzeConflicts() {
    m_conflicts.clear();
    m_trueConflicts.clear();
    m_overrides.clear();
    m_chordMap.clear();

    auto vars = Caelestia::CaelestiaVars::instance();
    auto writer = Caelestia::FlightDeckWriter::instance();

    // 1. Collect system keybinds
    const QVariantList sections = vars->keybindSections();
    for (const auto& sVal : sections) {
        const QVariantMap sec = sVal.toMap();
        const QString secLabel = sec.value(QStringLiteral("label")).toString();
        const QVariantList options = sec.value(QStringLiteral("options")).toList();

        for (const auto& optVal : options) {
            const QVariantMap opt = optVal.toMap();
            const QString keyName = opt.value(QStringLiteral("key")).toString();
            const QString optLabel = opt.value(QStringLiteral("label")).toString();

            QVariant val = vars->get(keyName);
            if (val.isNull() || !val.isValid() || (val.typeId() == QMetaType::QString && val.toString().isEmpty())) {
                val = vars->getDefault(keyName, QVariant());
            }

            if (!val.isNull() && val.isValid()) {
                QString chord = normalizeChord(val);
                if (!chord.isEmpty()) {
                    QVariantMap entry{
                        { QStringLiteral("type"), QStringLiteral("system") },
                        { QStringLiteral("key"), keyName },
                        { QStringLiteral("label"), optLabel },
                        { QStringLiteral("section"), secLabel },
                        { QStringLiteral("rawVal"), val.toString() },
                        { QStringLiteral("chord"), chord }
                    };
                    m_chordMap[chord].append(entry);
                }
            }
        }
    }

    // 2. Collect custom binds
    const QVariantList customBinds = writer->customBinds();
    for (int i = 0; i < customBinds.size(); ++i) {
        const QVariantMap b = customBinds[i].toMap();
        const QString rawKey = b.value(QStringLiteral("key")).toString();
        const QString dsp = b.value(QStringLiteral("dispatcher")).toString();
        const QString args = b.value(QStringLiteral("args")).toString();

        QString chord = normalizeChord(rawKey);
        if (!chord.isEmpty()) {
            QVariantMap entry{
                { QStringLiteral("type"), QStringLiteral("custom") },
                { QStringLiteral("index"), i },
                { QStringLiteral("key"), rawKey },
                { QStringLiteral("label"), QStringLiteral("Custom: ") + dsp + (args.isEmpty() ? QString() : QStringLiteral(" ") + args) },
                { QStringLiteral("dispatcher"), dsp },
                { QStringLiteral("args"), args },
                { QStringLiteral("chord"), chord }
            };
            m_chordMap[chord].append(entry);
        }
    }

    // 3. Classify into true conflicts vs intentional overrides
    for (auto it = m_chordMap.constBegin(); it != m_chordMap.constEnd(); ++it) {
        const QVariantList sources = it.value();
        if (sources.size() > 1) {
            int customCount = 0;
            int systemCount = 0;
            QVariantMap firstCustom;
            QVariantMap firstSystem;

            for (const auto& sVal : sources) {
                QVariantMap s = sVal.toMap();
                if (s.value(QStringLiteral("type")).toString() == QStringLiteral("custom")) {
                    customCount++;
                    if (firstCustom.isEmpty()) firstCustom = s;
                } else {
                    systemCount++;
                    if (firstSystem.isEmpty()) firstSystem = s;
                }
            }

            bool isTrueConflict = (customCount >= 2) || (systemCount >= 2 && customCount == 0);
            bool isOverride = (customCount == 1 && systemCount >= 1);

            QVariantMap conflictObj{
                { QStringLiteral("chord"), it.key() },
                { QStringLiteral("count"), sources.size() },
                { QStringLiteral("customCount"), customCount },
                { QStringLiteral("systemCount"), systemCount },
                { QStringLiteral("isTrueConflict"), isTrueConflict },
                { QStringLiteral("isOverride"), isOverride },
                { QStringLiteral("customOverride"), firstCustom },
                { QStringLiteral("systemShadowed"), firstSystem },
                { QStringLiteral("sources"), sources }
            };

            m_conflicts.append(conflictObj);

            if (isTrueConflict) {
                m_trueConflicts.append(conflictObj);
            } else if (isOverride) {
                m_overrides.append(conflictObj);
            }
        }
    }
}

QVariantMap KeybindValidator::checkChord(const QString& chord, int ignoreCustomIndex) const {
    const QString normalized = normalizeChord(chord);
    if (normalized.isEmpty() || !m_chordMap.contains(normalized)) {
        return QVariantMap();
    }

    const QVariantList allSources = m_chordMap.value(normalized);
    QVariantList filteredSources;
    int customCount = 0;
    int systemCount = 0;
    QVariantMap firstCustom;
    QVariantMap firstSystem;

    for (const auto& sVal : allSources) {
        const QVariantMap s = sVal.toMap();
        if (ignoreCustomIndex >= 0 && s.value(QStringLiteral("type")).toString() == QStringLiteral("custom") &&
            s.value(QStringLiteral("index")).toInt() == ignoreCustomIndex) {
            continue;
        }
        filteredSources.append(s);
        if (s.value(QStringLiteral("type")).toString() == QStringLiteral("custom")) {
            customCount++;
            if (firstCustom.isEmpty()) firstCustom = s;
        } else {
            systemCount++;
            if (firstSystem.isEmpty()) firstSystem = s;
        }
    }

    if (filteredSources.isEmpty()) {
        return QVariantMap();
    }

    bool isTrueConflict = (customCount >= 2) || (systemCount >= 2 && customCount == 0);
    bool hasCustomConflict = (customCount >= 1);
    bool isOverride = (customCount >= 1 && systemCount >= 1) || (customCount == 0 && systemCount > 0);

    return QVariantMap{
        { QStringLiteral("chord"), normalized },
        { QStringLiteral("count"), filteredSources.size() },
        { QStringLiteral("customCount"), customCount },
        { QStringLiteral("systemCount"), systemCount },
        { QStringLiteral("isTrueConflict"), isTrueConflict },
        { QStringLiteral("hasCustomConflict"), hasCustomConflict },
        { QStringLiteral("isOverride"), isOverride },
        { QStringLiteral("customOverride"), firstCustom },
        { QStringLiteral("systemShadowed"), firstSystem },
        { QStringLiteral("sources"), filteredSources }
    };
}

QVariantMap KeybindValidator::checkConflictForChord(const QString& chord, int ignoreCustomIndex) const {
    return checkChord(chord, ignoreCustomIndex);
}

bool KeybindValidator::hasConflict(const QString& chord, int ignoreCustomIndex) const {
    QVariantMap res = checkChord(chord, ignoreCustomIndex);
    return res.value(QStringLiteral("isTrueConflict")).toBool();
}

bool KeybindValidator::hasTrueConflict(const QString& chord, int ignoreCustomIndex) const {
    QVariantMap res = checkChord(chord, ignoreCustomIndex);
    return res.value(QStringLiteral("isTrueConflict")).toBool();
}

bool KeybindValidator::isOverridden(const QString& chord) const {
    const QString normalized = normalizeChord(chord);
    if (normalized.isEmpty()) return false;

    for (const auto& item : m_overrides) {
        const QVariantMap o = item.toMap();
        if (o.value(QStringLiteral("chord")).toString() == normalized) {
            return true;
        }
    }
    return false;
}

QVariantMap KeybindValidator::getOverrideInfo(const QString& chord) const {
    const QString normalized = normalizeChord(chord);
    if (normalized.isEmpty()) return QVariantMap();

    for (const auto& item : m_overrides) {
        const QVariantMap o = item.toMap();
        if (o.value(QStringLiteral("chord")).toString() == normalized) {
            return o;
        }
    }
    return QVariantMap();
}

void KeybindValidator::refresh() {
    analyzeConflicts();
    emit conflictsChanged();
}

} // namespace FlightDeck::Managers
