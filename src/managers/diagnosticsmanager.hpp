#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>

namespace FlightDeck::Managers {

class DiagnosticsManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList results READ results NOTIFY resultsChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(int passCount READ passCount NOTIFY resultsChanged)
    Q_PROPERTY(int warningCount READ warningCount NOTIFY resultsChanged)
    Q_PROPERTY(int errorCount READ errorCount NOTIFY resultsChanged)

public:
    static DiagnosticsManager* instance();
    static DiagnosticsManager* create(QQmlEngine* engine, QJSEngine* scriptEngine);

    explicit DiagnosticsManager(QObject* parent = nullptr);

    QVariantList results() const;
    bool isRunning() const;
    int passCount() const;
    int warningCount() const;
    int errorCount() const;

    Q_INVOKABLE void runAllChecks();

signals:
    void resultsChanged();
    void isRunningChanged();

private:
    void checkCompositor(QVariantList& list);
    void checkGraphicsAndEnvironment(QVariantList& list);
    void checkDotfilesAndSyntax(QVariantList& list);
    void checkServicesAndDaemons(QVariantList& list);
    void checkKeybinds(QVariantList& list);

    bool m_isRunning = false;
    QVariantList m_results;
    int m_passCount = 0;
    int m_warningCount = 0;
    int m_errorCount = 0;
};

} // namespace FlightDeck::Managers
