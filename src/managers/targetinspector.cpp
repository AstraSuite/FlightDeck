#include "targetinspector.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../hyprland/hyprlandevents.hpp"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTimer>

namespace FlightDeck::Managers {

TargetInspector* TargetInspector::instance() {
    static TargetInspector inst;
    return &inst;
}

TargetInspector* TargetInspector::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

TargetInspector::TargetInspector(QObject* parent)
    : QObject(parent) {
    connect(Hyprland::HyprlandEvents::instance(), &Hyprland::HyprlandEvents::activeWindowChanged,
            this, &TargetInspector::onActiveWindowChanged);
}

bool TargetInspector::isPicking() const {
    return m_isPicking;
}

QVariantMap TargetInspector::lastInspectedWindow() const {
    return m_lastWindow;
}

QVariantMap TargetInspector::lastInspectedLayer() const {
    return m_lastLayer;
}

QVariantMap TargetInspector::inspectActiveWindow() {
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("activewindow"));
    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        QVariantMap map = obj.toVariantMap();

        m_lastWindow = map;
        emit windowInspected(map);
        return map;
    }
    return QVariantMap();
}

QVariantList TargetInspector::activeClients() const {
    QVariantList list;
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("clients"));
    if (doc.isArray()) {
        const QJsonArray arr = doc.array();
        for (const auto& item : arr) {
            if (item.isObject()) {
                list.append(item.toObject().toVariantMap());
            }
        }
    }
    return list;
}

QVariantList TargetInspector::activeLayers() const {
    QVariantList list;
    const QJsonDocument doc = Hyprland::HyprlandSocket::instance()->queryJson(QStringLiteral("layers"));
    if (doc.isObject()) {
        const QJsonObject root = doc.object();
        for (auto it = root.constBegin(); it != root.constEnd(); ++it) {
            QString monName = it.key();
            QJsonObject monObj = it.value().toObject();
            QJsonObject levels = monObj.value(QStringLiteral("levels")).toObject();

            for (auto lvlIt = levels.constBegin(); lvlIt != levels.constEnd(); ++lvlIt) {
                QString levelNum = lvlIt.key();
                QJsonArray layerArr = lvlIt.value().toArray();
                for (const auto& lVal : layerArr) {
                    if (lVal.isObject()) {
                        QVariantMap lm = lVal.toObject().toVariantMap();
                        lm[QStringLiteral("monitor")] = monName;
                        lm[QStringLiteral("level")] = levelNum;
                        list.append(lm);
                    }
                }
            }
        }
    }
    return list;
}

void TargetInspector::startWindowPicker() {
    m_isPicking = true;
    emit isPickingChanged();

    // Auto-timeout picking after 15 seconds if nothing clicked
    QTimer::singleShot(15000, this, [this]() {
        if (m_isPicking) {
            cancelPicker();
        }
    });
}

void TargetInspector::cancelPicker() {
    if (m_isPicking) {
        m_isPicking = false;
        emit isPickingChanged();
    }
}

void TargetInspector::onActiveWindowChanged() {
    if (!m_isPicking) return;

    QTimer::singleShot(100, this, [this]() {
        QVariantMap win = inspectActiveWindow();
        if (!win.isEmpty()) {
            m_isPicking = false;
            emit isPickingChanged();
        }
    });
}

} // namespace FlightDeck::Managers
