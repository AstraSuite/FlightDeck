#include "hyprlandevents.hpp"
#include "hyprlandsocket.hpp"

#include <QFile>
#include <QLocalSocket>
#include <QDebug>

namespace Helm::Hyprland {

HyprlandEventListener::HyprlandEventListener(QObject* parent)
    : QThread(parent) {}

HyprlandEventListener::~HyprlandEventListener() {
    stop();
    wait(2000);
}

void HyprlandEventListener::stop() {
    m_running = false;
}

void HyprlandEventListener::run() {
    m_running = true;
    const QString eventSocket = HyprlandSocket::eventSocketPath();
    if (eventSocket.isEmpty() || !QFile::exists(eventSocket)) {
        return;
    }

    QLocalSocket socket;
    socket.connectToServer(eventSocket);
    if (!socket.waitForConnected(3000)) {
        return;
    }

    QByteArray buffer;
    while (m_running && socket.state() == QLocalSocket::ConnectedState) {
        if (socket.waitForReadyRead(500)) {
            buffer.append(socket.readAll());
            while (true) {
                const int newlineIndex = buffer.indexOf('\n');
                if (newlineIndex < 0) break;

                const QByteArray line = buffer.left(newlineIndex).trimmed();
                buffer.remove(0, newlineIndex + 1);

                if (line.isEmpty()) continue;

                const QString eventStr = QString::fromUtf8(line);
                const int separator = eventStr.indexOf(QStringLiteral(">>"));
                QString name;
                QString data;
                if (separator >= 0) {
                    name = eventStr.left(separator);
                    data = eventStr.mid(separator + 2);
                } else {
                    name = eventStr;
                }

                emit eventReceived(name, data);

                if (name.startsWith(QStringLiteral("monitoradded")) || name.startsWith(QStringLiteral("monitorremoved"))) {
                    emit monitorChanged();
                } else if (name.startsWith(QStringLiteral("workspace")) || name.startsWith(QStringLiteral("createworkspace")) || name.startsWith(QStringLiteral("destroyworkspace"))) {
                    emit workspaceChanged();
                } else if (name.startsWith(QStringLiteral("activewindow"))) {
                    emit activeWindowChanged();
                } else if (name.startsWith(QStringLiteral("configreloaded"))) {
                    emit configReloaded();
                }
            }
        }
    }
}

HyprlandEvents::HyprlandEvents(QObject* parent)
    : QObject(parent) {
    m_listener = new HyprlandEventListener(this);
    connect(m_listener, &HyprlandEventListener::eventReceived, this, &HyprlandEvents::eventReceived);
    connect(m_listener, &HyprlandEventListener::monitorChanged, this, &HyprlandEvents::monitorChanged);
    connect(m_listener, &HyprlandEventListener::workspaceChanged, this, &HyprlandEvents::workspaceChanged);
    connect(m_listener, &HyprlandEventListener::activeWindowChanged, this, &HyprlandEvents::activeWindowChanged);
    connect(m_listener, &HyprlandEventListener::configReloaded, this, &HyprlandEvents::configReloaded);
}

HyprlandEvents* HyprlandEvents::instance() {
    static HyprlandEvents inst;
    return &inst;
}

void HyprlandEvents::start() {
    if (m_listener && !m_listener->isRunning()) {
        m_listener->start();
    }
}

void HyprlandEvents::stop() {
    if (m_listener && m_listener->isRunning()) {
        m_listener->stop();
    }
}

} // namespace Helm::Hyprland
