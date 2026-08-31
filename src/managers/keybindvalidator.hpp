#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>
#include <QHash>
#include <QStringList>

namespace FlightDeck::Managers {

class KeybindValidator : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList conflicts READ conflicts NOTIFY conflictsChanged)
    Q_PROPERTY(QVariantList trueConflicts READ trueConflicts NOTIFY conflictsChanged)
    Q_PROPERTY(QVariantList overrides READ overrides NOTIFY conflictsChanged)
    Q_PROPERTY(int conflictCount READ conflictCount NOTIFY conflictsChanged)
    Q_PROPERTY(int trueConflictCount READ trueConflictCount NOTIFY conflictsChanged)
    Q_PROPERTY(int overrideCount READ overrideCount NOTIFY conflictsChanged)

public:
    static KeybindValidator* instance();
    static KeybindValidator* create(QQmlEngine* engine, QJSEngine* scriptEngine);

    explicit KeybindValidator(QObject* parent = nullptr);

    QVariantList conflicts() const;
    QVariantList trueConflicts() const;
    QVariantList overrides() const;
    int conflictCount() const;
    int trueConflictCount() const;
    int overrideCount() const;

    Q_INVOKABLE QString normalizeChord(const QVariant& keyVal, const QString& explicitMainMod = QString()) const;
    Q_INVOKABLE QVariantMap checkConflictForChord(const QString& chord, int ignoreCustomIndex = -1) const;
    Q_INVOKABLE QVariantMap checkChord(const QString& chord, int ignoreCustomIndex = -1) const;
    Q_INVOKABLE bool hasConflict(const QString& chord, int ignoreCustomIndex = -1) const;
    Q_INVOKABLE bool hasTrueConflict(const QString& chord, int ignoreCustomIndex = -1) const;
    Q_INVOKABLE bool isOverridden(const QString& chord) const;
    Q_INVOKABLE QVariantMap getOverrideInfo(const QString& chord) const;
    Q_INVOKABLE void refresh();

signals:
    void conflictsChanged();

private:
    void analyzeConflicts();

    QVariantList m_conflicts;
    QVariantList m_trueConflicts;
    QVariantList m_overrides;
    QHash<QString, QVariantList> m_chordMap;
};

} // namespace FlightDeck::Managers
