#pragma once

#include <QObject>
#include <QThread>
#include <QLocalSocket>

namespace FlightDeck::Hyprland {

class HyprlandEventListener : public QThread {
    Q_OBJECT

public:
    explicit HyprlandEventListener(QObject* parent = nullptr);
    ~HyprlandEventListener() override;

    void stop();

protected:
    void run() override;

signals:
    void eventReceived(const QString& eventName, const QString& eventData);
    void monitorChanged();
    void workspaceChanged();
    void activeWindowChanged();
    void configReloaded();

private:
    std::atomic<bool> m_running{false};
};

class HyprlandEvents : public QObject {
    Q_OBJECT

public:
    static HyprlandEvents* instance();

    void start();
    void stop();

signals:
    void eventReceived(const QString& eventName, const QString& eventData);
    void monitorChanged();
    void workspaceChanged();
    void activeWindowChanged();
    void configReloaded();

private:
    explicit HyprlandEvents(QObject* parent = nullptr);
    HyprlandEventListener* m_listener = nullptr;
};

} // namespace FlightDeck::Hyprland
