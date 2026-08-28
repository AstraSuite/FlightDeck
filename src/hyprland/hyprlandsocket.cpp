#include "hyprlandsocket.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QLocalSocket>
#include <QProcessEnvironment>
#include <QDebug>
#include <unistd.h>

namespace Helm::Hyprland {

HyprlandSocket::HyprlandSocket(QObject* parent)
    : QObject(parent) {}

HyprlandSocket* HyprlandSocket::instance() {
    static HyprlandSocket inst;
    return &inst;
}

QString HyprlandSocket::instanceSignature() {
    return qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
}

QString HyprlandSocket::socketDir() {
    const QString sig = instanceSignature();
    if (sig.isEmpty()) {
        return {};
    }
    const QString runtime = qEnvironmentVariable("XDG_RUNTIME_DIR", QStringLiteral("/run/user/%1").arg(getuid()));
    return QStringLiteral("%1/hypr/%2").arg(runtime, sig);
}

QString HyprlandSocket::commandSocketPath() {
    const QString dir = socketDir();
    if (dir.isEmpty()) return {};
    return dir + QStringLiteral("/.socket.sock");
}

QString HyprlandSocket::eventSocketPath() {
    const QString dir = socketDir();
    if (dir.isEmpty()) return {};
    return dir + QStringLiteral("/.socket2.sock");
}

bool HyprlandSocket::isOnline() {
    const QString path = commandSocketPath();
    return !path.isEmpty() && QFile::exists(path);
}

QString HyprlandSocket::send(const QString& command, int timeoutMs) const {
    const QString path = commandSocketPath();
    if (path.isEmpty() || !QFile::exists(path)) {
        return {};
    }

    QLocalSocket socket;
    socket.connectToServer(path);
    if (!socket.waitForConnected(timeoutMs)) {
        qWarning() << "HyprlandSocket: failed to connect to" << path << socket.errorString();
        return {};
    }

    const QByteArray cmdBytes = command.toUtf8();
    socket.write(cmdBytes);
    if (!socket.waitForBytesWritten(timeoutMs)) {
        qWarning() << "HyprlandSocket: failed to write command:" << socket.errorString();
        return {};
    }

    QByteArray response;
    while (socket.waitForReadyRead(timeoutMs)) {
        response.append(socket.readAll());
    }
    response.append(socket.readAll());
    socket.disconnectFromServer();

    return QString::fromUtf8(response);
}

QJsonDocument HyprlandSocket::queryJson(const QString& command, int timeoutMs) const {
    const QString fullCmd = command.startsWith(QLatin1String("j/")) ? command : (QStringLiteral("j/") + command);
    const QString resp = send(fullCmd, timeoutMs);
    if (resp.isEmpty()) {
        return {};
    }

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(resp.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) {
        qWarning() << "HyprlandSocket: JSON parse error for command" << fullCmd << ":" << err.errorString();
        return {};
    }
    return doc;
}

bool HyprlandSocket::keyword(const QString& key, const QVariant& value) {
    QString valStr;
    if (value.typeId() == QMetaType::Bool) {
        valStr = value.toBool() ? QStringLiteral("1") : QStringLiteral("0");
    } else {
        valStr = value.toString();
    }

    const QString resp = send(QStringLiteral("/keyword %1 %2").arg(key, valStr));
    const QString trimmed = resp.trimmed();
    if (trimmed.compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0) {
        return true;
    }

    // Hyprland 0.55+ with Lua config manager might ask for eval
    if (trimmed.contains(QLatin1String("eval"), Qt::CaseInsensitive)) {
        // Construct Lua fallback: hl.config({ ... })
        return evalLua(QStringLiteral("hl.set_option(\"%1\", %2)").arg(key, valStr));
    }

    emit commandFailed(key, resp);
    return false;
}

bool HyprlandSocket::keywordBatch(const QList<QPair<QString, QVariant>>& commands) {
    if (commands.isEmpty()) return true;

    QStringList batchList;
    for (const auto& [k, v] : commands) {
        QString valStr = (v.typeId() == QMetaType::Bool) ? (v.toBool() ? QStringLiteral("1") : QStringLiteral("0")) : v.toString();
        batchList.append(QStringLiteral("keyword %1 %2").arg(k, valStr));
    }

    const QString batchPayload = QStringLiteral("[[BATCH]]%1").arg(batchList.join(QLatin1Char(';')));
    const QString resp = send(batchPayload, 5000);
    return !resp.isEmpty();
}

bool HyprlandSocket::evalLua(const QString& luaCode) {
    const QString resp = send(QStringLiteral("/eval %1").arg(luaCode));
    const QString trimmed = resp.trimmed();
    if (trimmed.compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0) {
        return true;
    }
    emit commandFailed(luaCode, resp);
    return false;
}

bool HyprlandSocket::dispatch(const QString& dispatcher, const QString& args) {
    const QString payload = args.isEmpty() ? QStringLiteral("/dispatch %1").arg(dispatcher)
                                           : QStringLiteral("/dispatch %1 %2").arg(dispatcher, args);
    const QString resp = send(payload);
    return !resp.isEmpty() && resp.trimmed().compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0;
}

bool HyprlandSocket::setCursor(const QString& theme, int size) {
    return dispatch(QStringLiteral("setcursor"), QStringLiteral("%1 %2").arg(theme).arg(size));
}

bool HyprlandSocket::reload() {
    const QString resp = send(QStringLiteral("/reload"));
    return resp.trimmed().compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0;
}

QVariantMap HyprlandSocket::getOption(const QString& optionKey) const {
    const QJsonDocument doc = queryJson(QStringLiteral("getoption %1").arg(optionKey));
    if (doc.isObject()) {
        return doc.object().toVariantMap();
    }
    return {};
}

} // namespace Helm::Hyprland
