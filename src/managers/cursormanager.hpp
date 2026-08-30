#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QImage>
#include <QQmlEngine>

namespace FlightDeck::Managers {

class CursorManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString currentTheme READ currentTheme WRITE setCurrentTheme NOTIFY themeChanged)
    Q_PROPERTY(int currentSize READ currentSize WRITE setCurrentSize NOTIFY sizeChanged)
    Q_PROPERTY(QVariantList availableThemes READ availableThemes NOTIFY themesChanged)
    Q_PROPERTY(QList<int> availableSizes READ availableSizes CONSTANT)

public:
    static CursorManager* instance();
    static CursorManager* create(QQmlEngine*, QJSEngine*);

    explicit CursorManager(QObject* parent = nullptr);

    QString currentTheme() const;
    Q_INVOKABLE void setCurrentTheme(const QString& theme);
    Q_INVOKABLE void resetTheme();

    int currentSize() const;
    Q_INVOKABLE void setCurrentSize(int size);

    QVariantList availableThemes() const;
    QList<int> availableSizes() const;

    Q_INVOKABLE void apply(const QString& theme, int size);
    Q_INVOKABLE void applySystemWide(const QString& theme, int size);
    Q_INVOKABLE void scanThemes();

    static QImage loadCursorPreview(const QString& themeName, int targetSize = 48);

signals:
    void themeChanged();
    void sizeChanged();
    void themesChanged();

private:
    void applyAll(const QString& theme, int size);
    void applyGSettings(const QString& theme, int size);
    void applyGtkConfig(const QString& theme, int size);
    void applyDefaultIconTheme(const QString& theme);
    void applyXresources(const QString& theme, int size);

    QString m_currentTheme;
    int m_currentSize = 24;
    QVariantList m_themes;
};

} // namespace FlightDeck::Managers
