#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class ProfileManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList profiles READ profiles NOTIFY profilesChanged)

public:
    static ProfileManager* instance();
    static ProfileManager* create(QQmlEngine*, QJSEngine*);

    explicit ProfileManager(QObject* parent = nullptr);

    QStringList profiles() const;

    Q_INVOKABLE bool createProfile(const QString& name);
    Q_INVOKABLE bool restoreProfile(const QString& name);
    Q_INVOKABLE bool deleteProfile(const QString& name);
    Q_INVOKABLE void refresh();

signals:
    void profilesChanged();
    void operationFinished(bool success, const QString& message);

private:
    QString profilesDir() const;
    QStringList m_profiles;
};

} // namespace FlightDeck::Managers
