#pragma once

#include <QObject>
#include <QString>
#include <QJsonDocument>
#include <QJsonValue>
#include <QVariant>
#include <QPair>

namespace Helm::Hyprland {

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

    bool keyword(const QString& key, const QVariant& value);
    bool keywordBatch(const QList<QPair<QString, QVariant>>& commands);
    bool evalLua(const QString& luaCode);
    bool dispatch(const QString& dispatcher, const QString& args = QString());
    bool setCursor(const QString& theme, int size);
    bool reload();

    QVariantMap getOption(const QString& optionKey) const;

signals:
    void commandFailed(const QString& command, const QString& error);
};

} // namespace Helm::Hyprland
