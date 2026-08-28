#pragma once

#include <QObject>
#include <QString>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class AirlockManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool hasAirlockConfig READ hasAirlockConfig NOTIFY configStatusChanged)
    Q_PROPERTY(bool isSyncing READ isSyncing NOTIFY syncingChanged)
    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY messageChanged)

public:
    static AirlockManager* instance();
    static AirlockManager* create(QQmlEngine*, QJSEngine*);

    explicit AirlockManager(QObject* parent = nullptr);

    bool hasAirlockConfig() const;
    bool isSyncing() const;
    QString lastMessage() const;

    Q_INVOKABLE void checkConfig();
    Q_INVOKABLE bool syncToAirlock();
    Q_INVOKABLE QString generateAirlockLua() const;

signals:
    void configStatusChanged();
    void syncingChanged();
    void messageChanged();
    void syncFinished(bool success, const QString& message);

private:
    bool m_hasAirlockConfig = false;
    bool m_isSyncing = false;
    QString m_lastMessage;
};

} // namespace FlightDeck::Managers
