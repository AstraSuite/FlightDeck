#include "hyprlandstate.hpp"
#include "hyprlandsocket.hpp"
#include "hyprlandevents.hpp"

#include <QJsonObject>
#include <QJsonArray>
#include <QProcess>

namespace Helm::Hyprland {

HyprlandState* HyprlandState::instance() {
    static HyprlandState inst;
    return &inst;
}

HyprlandState* HyprlandState::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

HyprlandState::HyprlandState(QObject* parent)
    : QObject(parent) {
    HyprlandEvents* events = HyprlandEvents::instance();
    events->start();

    connect(events, &HyprlandEvents::monitorChanged, this, &HyprlandState::monitorsChanged);
    connect(events, &HyprlandEvents::workspaceChanged, this, &HyprlandState::workspacesChanged);
    connect(events, &HyprlandEvents::activeWindowChanged, this, &HyprlandState::activeWindowChanged);
    connect(events, &HyprlandEvents::configReloaded, this, &HyprlandState::refresh);

    checkDevices();
}

bool HyprlandState::online() const {
    return HyprlandSocket::isOnline();
}

QString HyprlandState::version() const {
    if (!m_version.isEmpty()) return m_version;

    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("version"));
    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        m_version = obj.value(QStringLiteral("tag")).toString();
        if (m_version.isEmpty()) {
            m_version = obj.value(QStringLiteral("version")).toString();
        }
    }
    if (m_version.isEmpty()) {
        m_version = QStringLiteral("v0.56.0");
    }
    return m_version;
}

bool HyprlandState::hasTouchpad() const {
    return m_hasTouchpad;
}

bool HyprlandState::hasTouchscreen() const {
    return m_hasTouchscreen;
}

void HyprlandState::checkDevices() {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("devices"));
    if (doc.isObject()) {
        const QJsonObject root = doc.object();
        if (root.contains(QStringLiteral("mice")) && root.value(QStringLiteral("mice")).isArray()) {
            const QJsonArray mice = root.value(QStringLiteral("mice")).toArray();
            for (const auto& item : mice) {
                const QJsonObject m = item.toObject();
                if (m.value(QStringLiteral("touchpad")).toBool() || m.value(QStringLiteral("name")).toString().contains(QLatin1String("touchpad"), Qt::CaseInsensitive)) {
                    m_hasTouchpad = true;
                    break;
                }
            }
        }
        if (root.contains(QStringLiteral("touch")) && root.value(QStringLiteral("touch")).isArray()) {
            m_hasTouchscreen = !root.value(QStringLiteral("touch")).toArray().isEmpty();
        }
    } else {
        m_hasTouchpad = true;
        m_hasTouchscreen = true;
    }
    emit devicesChanged();
}

QVariantList HyprlandState::monitors() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("monitors"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return {};
}

QVariantList HyprlandState::workspaces() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("workspaces"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return {};
}

QVariantList HyprlandState::clients() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("clients"));
    if (doc.isArray()) {
        return doc.array().toVariantList();
    }
    return {};
}

QVariantMap HyprlandState::activeWindow() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("activewindow"));
    if (doc.isObject()) {
        return doc.object().toVariantMap();
    }
    return {};
}

int HyprlandState::activeWorkspaceId() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("activeworkspace"));
    if (doc.isObject()) {
        return doc.object().value(QStringLiteral("id")).toInt(1);
    }
    return 1;
}

void HyprlandState::refresh() {
    m_version.clear();
    emit stateChanged();
    emit monitorsChanged();
    emit workspacesChanged();
    emit clientsChanged();
    emit activeWindowChanged();
    checkDevices();
}

void HyprlandState::reloadCompositor() {
    HyprlandSocket::instance()->reload();
    refresh();
}

void HyprlandState::setCursor(const QString& theme, int size) {
    HyprlandSocket::instance()->dispatch(QStringLiteral("setcursor"), QStringLiteral("%1 %2").arg(theme).arg(size));
}

bool HyprlandState::dispatch(const QString& dispatcher, const QString& arg) {
    return HyprlandSocket::instance()->dispatch(dispatcher, arg);
}

bool HyprlandState::keyword(const QString& key, const QVariant& value) {
    return HyprlandSocket::instance()->keyword(key, value);
}

QVariantMap HyprlandState::getOption(const QString& key) const {
    return HyprlandSocket::instance()->getOption(key);
}

} // namespace Helm::Hyprland
