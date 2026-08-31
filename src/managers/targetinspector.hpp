#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>
#include <QVariantList>

namespace FlightDeck::Managers {

class TargetInspector : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isPicking READ isPicking NOTIFY isPickingChanged)
    Q_PROPERTY(QVariantMap lastInspectedWindow READ lastInspectedWindow NOTIFY windowInspected)
    Q_PROPERTY(QVariantMap lastInspectedLayer READ lastInspectedLayer NOTIFY layerInspected)

public:
    static TargetInspector* instance();
    static TargetInspector* create(QQmlEngine* engine, QJSEngine* scriptEngine);

    explicit TargetInspector(QObject* parent = nullptr);

    bool isPicking() const;
    QVariantMap lastInspectedWindow() const;
    QVariantMap lastInspectedLayer() const;

    Q_INVOKABLE QVariantMap inspectActiveWindow();
    Q_INVOKABLE QVariantList activeClients() const;
    Q_INVOKABLE QVariantList activeLayers() const;

    Q_INVOKABLE void startWindowPicker();
    Q_INVOKABLE void cancelPicker();

signals:
    void isPickingChanged();
    void windowInspected(const QVariantMap& windowInfo);
    void layerInspected(const QVariantMap& layerInfo);

private slots:
    void onActiveWindowChanged();

private:
    bool m_isPicking = false;
    QVariantMap m_lastWindow;
    QVariantMap m_lastLayer;
};

} // namespace FlightDeck::Managers
