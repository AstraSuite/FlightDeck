#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>

namespace FlightDeck::Hyprland {

class HyprlandState : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool online READ online NOTIFY stateChanged)
    Q_PROPERTY(QString version READ version NOTIFY stateChanged)
    Q_PROPERTY(bool hasTouchpad READ hasTouchpad NOTIFY devicesChanged)
    Q_PROPERTY(bool hasTouchscreen READ hasTouchscreen NOTIFY devicesChanged)
    Q_PROPERTY(QVariantList monitors READ monitors NOTIFY monitorsChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)
    Q_PROPERTY(QVariantList clients READ clients NOTIFY clientsChanged)
    Q_PROPERTY(QVariantMap activeWindow READ activeWindow NOTIFY activeWindowChanged)
    Q_PROPERTY(int activeWorkspaceId READ activeWorkspaceId NOTIFY workspacesChanged)

public:
    static HyprlandState* instance();
    static HyprlandState* create(QQmlEngine*, QJSEngine*);

    explicit HyprlandState(QObject* parent = nullptr);

    bool online() const;
    QString version() const;
    bool hasTouchpad() const;
    bool hasTouchscreen() const;

    QVariantList monitors() const;
    QVariantList workspaces() const;
    QVariantList clients() const;
    QVariantMap activeWindow() const;
    int activeWorkspaceId() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void reloadCompositor();
    Q_INVOKABLE void setCursor(const QString& theme, int size);
    Q_INVOKABLE bool dispatch(const QString& dispatcher, const QString& arg = QString());
    Q_INVOKABLE bool keyword(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariantMap getOption(const QString& key) const;

signals:
    void stateChanged();
    void monitorsChanged();
    void workspacesChanged();
    void clientsChanged();
    void activeWindowChanged();
    void devicesChanged();

private:
    void checkDevices();

    mutable QString m_version;
    bool m_hasTouchpad = false;
    bool m_hasTouchscreen = false;
};

} // namespace FlightDeck::Hyprland
