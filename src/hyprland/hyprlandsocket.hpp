#pragma once

#include <QObject>
#include <QString>
#include <QJsonDocument>
#include <QJsonValue>
#include <QVariant>
#include <QPair>

namespace FlightDeck::Hyprland {

class HyprlandSocket : public QObject {
    Q_OBJECT

public:
    explicit HyprlandSocket(QObject* parent = nullptr);

    static HyprlandSocket* instance();

    static QString instanceSignature();
    static QString socketDir();
    static QString commandSocketPath();
    static QString eventSocketPath();

    static bool isOnline();

    QString send(const QString& command, int timeoutMs = 2000) const;
    QJsonDocument queryJson(const QString& command, int timeoutMs = 2000) const;

    // Apply the cursor theme/size across every active Hyprland instance, cycling
    // through a fallback theme first to force wlroots to bust its internal cursor
    // cache (mirrors Bibata's reload_system_cursors behaviour).
    bool setCursorAll(const QString& theme, int size);

    bool keyword(const QString& key, const QVariant& value);
    bool keywordBatch(const QList<QPair<QString, QVariant>>& commands);
    bool evalLua(const QString& luaCode);
    bool dispatch(const QString& dispatcher, const QString& args = QString());
    bool setCursor(const QString& theme, int size);
    bool reload();

    QVariantMap getOption(const QString& optionKey) const;

signals:
    void commandFailed(const QString& command, const QString& error);

private:
    QString sendToPath(const QString& path, const QString& command, int timeoutMs) const;
};

} // namespace FlightDeck::Hyprland
