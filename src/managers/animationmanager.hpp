#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class AnimationManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString activePreset READ activePreset WRITE setActivePreset NOTIFY presetChanged)
    Q_PROPERTY(QStringList availablePresets READ availablePresets NOTIFY presetsChanged)
    Q_PROPERTY(QVariantList bezierCurves READ bezierCurves NOTIFY curvesChanged)
    Q_PROPERTY(QVariantList animationTargets READ animationTargets NOTIFY targetsChanged)

public:
    static AnimationManager* instance();
    static AnimationManager* create(QQmlEngine*, QJSEngine*);

    explicit AnimationManager(QObject* parent = nullptr);

    QString activePreset() const;
    void setActivePreset(const QString& preset);

    QStringList availablePresets() const;
    QVariantList bezierCurves() const;
    QVariantList animationTargets() const;

    Q_INVOKABLE void testCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2);
    Q_INVOKABLE void addBezierCurve(const QString& name, qreal x1, qreal y1, qreal x2, qreal y2);
    Q_INVOKABLE void removeBezierCurve(const QString& name);
    Q_INVOKABLE void setTargetEnabled(const QString& target, bool enabled);
    Q_INVOKABLE void updateTarget(const QString& target, bool enabled, qreal speed, const QString& curve, const QString& style = QString());
    Q_INVOKABLE void applyPreset(const QString& presetName);
    Q_INVOKABLE void scanPresets();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool save();

signals:
    void presetChanged();
    void presetsChanged();
    void curvesChanged();
    void targetsChanged();

private:
    QString m_activePreset;
    QStringList m_presets;
    QVariantList m_curves;
    QVariantList m_targets;
};

} // namespace FlightDeck::Managers
