#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QFileSystemWatcher>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QtQml/qqmlengine.h>

class ThemeWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString name READ name NOTIFY themeChanged)
    Q_PROPERTY(QString flavour READ flavour NOTIFY themeChanged)
    Q_PROPERTY(QString mode READ mode NOTIFY themeChanged)
    Q_PROPERTY(QString variant READ variant NOTIFY themeChanged)
    Q_PROPERTY(bool isLight READ isLight NOTIFY themeChanged)
    Q_PROPERTY(QVariantMap colours READ colours NOTIFY themeChanged)
    Q_PROPERTY(bool syncScheme READ syncScheme WRITE setSyncScheme NOTIFY syncSchemeChanged)
    Q_PROPERTY(bool syncTokens READ syncTokens WRITE setSyncTokens NOTIFY syncTokensChanged)

public:
    static ThemeWatcher* instance();
    static ThemeWatcher* create(QQmlEngine* = nullptr, QJSEngine* = nullptr);

    explicit ThemeWatcher(QObject* parent = nullptr);

    [[nodiscard]] QString name() const { return m_name; }
    [[nodiscard]] QString flavour() const { return m_flavour; }
    [[nodiscard]] QString mode() const { return m_mode; }
    [[nodiscard]] QString variant() const { return m_variant; }
    [[nodiscard]] bool isLight() const { return m_mode == QStringLiteral("light"); }
    [[nodiscard]] QVariantMap colours() const { return m_colours; }
    [[nodiscard]] bool syncScheme() const { return m_syncScheme; }
    [[nodiscard]] bool syncTokens() const { return m_syncTokens; }

    void setSyncScheme(bool sync);
    void setSyncTokens(bool sync);

    Q_INVOKABLE void reload();
    Q_INVOKABLE void setMode(const QString& mode);
    void applyTokensSync();

signals:
    void themeChanged();
    void syncSchemeChanged();
    void syncTokensChanged();

private:
    void applyFallbackColours();
    QString getSchemeFilePath() const;

    QFileSystemWatcher m_watcher;
    QString m_name{ QStringLiteral("astra-foundry") };
    QString m_flavour{ QStringLiteral("default") };
    QString m_mode{ QStringLiteral("dark") };
    QString m_variant{ QStringLiteral("content") };
    QVariantMap m_colours;
    bool m_syncScheme{true};
    bool m_syncTokens{true};
};
