#include "hyprlandsocket.hpp"
#include "hyprlandschema.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QLocalSocket>
#include <QProcessEnvironment>
#include <QSet>
#include <QThread>
#include <QDebug>
#include <unistd.h>

namespace FlightDeck::Hyprland {

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
    return sendToPath(path, command, timeoutMs);
}

QString HyprlandSocket::sendToPath(const QString& path, const QString& command, int timeoutMs) const {
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

bool HyprlandSocket::isLuaMode() {
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    const QString base = !xdg.isEmpty() ? xdg : QDir::homePath() + QStringLiteral("/.config");
    return QFile::exists(base + QStringLiteral("/hypr/hyprland.lua"));
}

bool HyprlandSocket::applyMonitor(const QVariantMap& mon) {
    const QString output = mon.value(QStringLiteral("output")).toString();
    if (output.isEmpty()) return false;

    const bool disabled = mon.value(QStringLiteral("disabled")).toBool();

    if (isLuaMode()) {
        if (disabled) {
            QString lua = QStringLiteral("hl.monitor({ output = \"%1\", disabled = true })").arg(output);
            return evalLua(lua);
        }

        QStringList fields;
        fields.append(QStringLiteral("output = \"%1\"").arg(output));
        fields.append(QStringLiteral("disabled = false"));

        if (mon.contains(QStringLiteral("mode")) && !mon.value(QStringLiteral("mode")).toString().isEmpty()) {
            fields.append(QStringLiteral("mode = \"%1\"").arg(mon.value(QStringLiteral("mode")).toString()));
        }
        if (mon.contains(QStringLiteral("position")) && !mon.value(QStringLiteral("position")).toString().isEmpty()) {
            fields.append(QStringLiteral("position = \"%1\"").arg(mon.value(QStringLiteral("position")).toString()));
        }
        if (mon.contains(QStringLiteral("scale"))) {
            fields.append(QStringLiteral("scale = %1").arg(mon.value(QStringLiteral("scale")).toDouble()));
        }
        if (mon.contains(QStringLiteral("transform"))) {
            int tr = mon.value(QStringLiteral("transform")).toInt();
            if (tr >= 0) {
                fields.append(QStringLiteral("transform = %1").arg(tr));
            }
        }
        if (mon.contains(QStringLiteral("vrr")) && !mon.value(QStringLiteral("vrr")).isNull()) {
            fields.append(QStringLiteral("vrr = %1").arg(mon.value(QStringLiteral("vrr")).toInt()));
        }
        if (mon.contains(QStringLiteral("bitdepth")) && !mon.value(QStringLiteral("bitdepth")).isNull()) {
            fields.append(QStringLiteral("bitdepth = %1").arg(mon.value(QStringLiteral("bitdepth")).toInt()));
        }
        if (mon.contains(QStringLiteral("cm")) && !mon.value(QStringLiteral("cm")).toString().isEmpty()) {
            fields.append(QStringLiteral("cm = \"%1\"").arg(mon.value(QStringLiteral("cm")).toString()));
        }
        if (mon.contains(QStringLiteral("sdrbrightness")) && !mon.value(QStringLiteral("sdrbrightness")).isNull()) {
            fields.append(QStringLiteral("sdrbrightness = %1").arg(mon.value(QStringLiteral("sdrbrightness")).toDouble()));
        }
        if (mon.contains(QStringLiteral("sdrsaturation")) && !mon.value(QStringLiteral("sdrsaturation")).isNull()) {
            fields.append(QStringLiteral("sdrsaturation = %1").arg(mon.value(QStringLiteral("sdrsaturation")).toDouble()));
        }
        if (mon.contains(QStringLiteral("sdr_min_luminance")) && !mon.value(QStringLiteral("sdr_min_luminance")).isNull()) {
            fields.append(QStringLiteral("sdr_min_luminance = %1").arg(mon.value(QStringLiteral("sdr_min_luminance")).toDouble()));
        }
        if (mon.contains(QStringLiteral("sdr_max_luminance")) && !mon.value(QStringLiteral("sdr_max_luminance")).isNull()) {
            fields.append(QStringLiteral("sdr_max_luminance = %1").arg(mon.value(QStringLiteral("sdr_max_luminance")).toDouble()));
        }
        if (mon.contains(QStringLiteral("min_luminance")) && !mon.value(QStringLiteral("min_luminance")).isNull()) {
            fields.append(QStringLiteral("min_luminance = %1").arg(mon.value(QStringLiteral("min_luminance")).toDouble()));
        }
        if (mon.contains(QStringLiteral("max_luminance")) && !mon.value(QStringLiteral("max_luminance")).isNull()) {
            fields.append(QStringLiteral("max_luminance = %1").arg(mon.value(QStringLiteral("max_luminance")).toDouble()));
        }
        if (mon.contains(QStringLiteral("max_avg_luminance")) && !mon.value(QStringLiteral("max_avg_luminance")).isNull()) {
            fields.append(QStringLiteral("max_avg_luminance = %1").arg(mon.value(QStringLiteral("max_avg_luminance")).toDouble()));
        }
        if (mon.contains(QStringLiteral("mirror")) && !mon.value(QStringLiteral("mirror")).toString().isEmpty() && mon.value(QStringLiteral("mirror")).toString() != QLatin1String("none")) {
            fields.append(QStringLiteral("mirror = \"%1\"").arg(mon.value(QStringLiteral("mirror")).toString()));
        }

        QString lua = QStringLiteral("hl.monitor({\n    %1\n})").arg(fields.join(QStringLiteral(",\n    ")));
        return evalLua(lua);
    } else {
        if (disabled) {
            return send(QStringLiteral("keyword monitor %1,disable").arg(output)).trimmed().compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0;
        }

        QString mode = mon.value(QStringLiteral("mode"), QStringLiteral("preferred")).toString();
        QString pos = mon.value(QStringLiteral("position"), QStringLiteral("auto")).toString();
        double scale = mon.value(QStringLiteral("scale"), 1.0).toDouble();

        QStringList parts;
        parts << output << mode << pos << QString::number(scale);

        if (mon.contains(QStringLiteral("transform")) && mon.value(QStringLiteral("transform")).toInt() > 0) {
            parts << QStringLiteral("transform") << QString::number(mon.value(QStringLiteral("transform")).toInt());
        }
        if (mon.contains(QStringLiteral("vrr")) && !mon.value(QStringLiteral("vrr")).isNull()) {
            parts << QStringLiteral("vrr") << QString::number(mon.value(QStringLiteral("vrr")).toInt());
        }
        if (mon.contains(QStringLiteral("bitdepth")) && !mon.value(QStringLiteral("bitdepth")).isNull()) {
            parts << QStringLiteral("bitdepth") << QString::number(mon.value(QStringLiteral("bitdepth")).toInt());
        }
        if (mon.contains(QStringLiteral("cm")) && !mon.value(QStringLiteral("cm")).toString().isEmpty()) {
            parts << QStringLiteral("cm") << mon.value(QStringLiteral("cm")).toString();
        }
        if (mon.contains(QStringLiteral("sdrbrightness")) && !mon.value(QStringLiteral("sdrbrightness")).isNull()) {
            parts << QStringLiteral("sdrbrightness") << QString::number(mon.value(QStringLiteral("sdrbrightness")).toDouble());
        }
        if (mon.contains(QStringLiteral("sdrsaturation")) && !mon.value(QStringLiteral("sdrsaturation")).isNull()) {
            parts << QStringLiteral("sdrsaturation") << QString::number(mon.value(QStringLiteral("sdrsaturation")).toDouble());
        }
        if (mon.contains(QStringLiteral("sdr_min_luminance")) && !mon.value(QStringLiteral("sdr_min_luminance")).isNull()) {
            parts << QStringLiteral("sdr_min_luminance") << QString::number(mon.value(QStringLiteral("sdr_min_luminance")).toDouble());
        }
        if (mon.contains(QStringLiteral("sdr_max_luminance")) && !mon.value(QStringLiteral("sdr_max_luminance")).isNull()) {
            parts << QStringLiteral("sdr_max_luminance") << QString::number(mon.value(QStringLiteral("sdr_max_luminance")).toDouble());
        }
        if (mon.contains(QStringLiteral("min_luminance")) && !mon.value(QStringLiteral("min_luminance")).isNull()) {
            parts << QStringLiteral("min_luminance") << QString::number(mon.value(QStringLiteral("min_luminance")).toDouble());
        }
        if (mon.contains(QStringLiteral("max_luminance")) && !mon.value(QStringLiteral("max_luminance")).isNull()) {
            parts << QStringLiteral("max_luminance") << QString::number(mon.value(QStringLiteral("max_luminance")).toDouble());
        }
        if (mon.contains(QStringLiteral("max_avg_luminance")) && !mon.value(QStringLiteral("max_avg_luminance")).isNull()) {
            parts << QStringLiteral("max_avg_luminance") << QString::number(mon.value(QStringLiteral("max_avg_luminance")).toDouble());
        }
        if (mon.contains(QStringLiteral("mirror")) && !mon.value(QStringLiteral("mirror")).toString().isEmpty() && mon.value(QStringLiteral("mirror")).toString() != QLatin1String("none")) {
            parts << QStringLiteral("mirror") << mon.value(QStringLiteral("mirror")).toString();
        }

        const QString resp = send(QStringLiteral("keyword monitor %1").arg(parts.join(QLatin1Char(','))));
        return resp.trimmed().compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0;
    }
}

bool HyprlandSocket::keyword(const QString& key, const QVariant& value) {
    if (key == QLatin1String("monitor")) {
        QString monStr = value.toString();
        QStringList parts = monStr.split(QLatin1Char(','));
        if (!parts.isEmpty()) {
            QVariantMap mon;
            mon[QStringLiteral("output")] = parts[0].trimmed();
            if (parts.size() >= 2 && parts[1].trimmed().toLower() == QLatin1String("disable")) {
                mon[QStringLiteral("disabled")] = true;
            } else {
                mon[QStringLiteral("disabled")] = false;
                if (parts.size() >= 2) mon[QStringLiteral("mode")] = parts[1].trimmed();
                if (parts.size() >= 3) mon[QStringLiteral("position")] = parts[2].trimmed();
                if (parts.size() >= 4) mon[QStringLiteral("scale")] = parts[3].trimmed().toDouble();
                for (int i = 4; i + 1 < parts.size(); i += 2) {
                    QString k = parts[i].trimmed().toLower();
                    QString v = parts[i + 1].trimmed();
                    if (k == QLatin1String("transform")) mon[QStringLiteral("transform")] = v.toInt();
                    else if (k == QLatin1String("mirror")) mon[QStringLiteral("mirror")] = v;
                    else if (k == QLatin1String("bitdepth")) mon[QStringLiteral("bitdepth")] = v.toInt();
                    else if (k == QLatin1String("vrr")) mon[QStringLiteral("vrr")] = v.toInt();
                    else if (k == QLatin1String("cm")) mon[QStringLiteral("cm")] = v;
                    else mon[k] = v;
                }
            }
            return applyMonitor(mon);
        }
    }

    auto schema = HyprlandSchema::instance();
    QString canonicalKey = schema ? schema->toHyprKey(key) : key;
    if (canonicalKey.isEmpty()) canonicalKey = key;

    if (isLuaMode()) {
        QVariantMap optMap;
        optMap[canonicalKey] = value;
        QString luaConfig = schema ? schema->serializeToLuaConfig(optMap) : QString();
        if (!luaConfig.isEmpty()) {
            if (evalLua(luaConfig)) {
                return true;
            }
        }
    }

    QString valStr;
    if (value.typeId() == QMetaType::Bool) {
        valStr = value.toBool() ? QStringLiteral("1") : QStringLiteral("0");
    } else {
        valStr = value.toString();
    }

    const QString resp = send(QStringLiteral("keyword %1 %2").arg(canonicalKey, valStr));
    const QString trimmed = resp.trimmed();
    if (trimmed.compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0) {
        return true;
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
    const QString resp = send(QStringLiteral("eval %1").arg(luaCode));
    const QString trimmed = resp.trimmed();
    if (trimmed.compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0 || trimmed.isEmpty()) {
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
    const QString resp = send(QStringLiteral("setcursor %1 %2").arg(theme).arg(size));
    return !resp.isEmpty() && resp.trimmed().compare(QLatin1String("ok"), Qt::CaseInsensitive) == 0;
}

bool HyprlandSocket::setCursorAll(const QString& theme, int size) {
    // Enumerate every active Hyprland instance socket under the runtime dir, plus the
    // current default instance. Each instance is handled through its own socket.
    const QString runtime = qEnvironmentVariable("XDG_RUNTIME_DIR", QStringLiteral("/run/user/%1").arg(getuid()));

    QStringList socketPaths;
    QSet<QString> seenSigs;

    QDir hyprDir(runtime + QStringLiteral("/hypr"));
    if (hyprDir.exists()) {
        const auto entries = hyprDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString& sig : entries) {
            if (seenSigs.contains(sig)) continue;
            seenSigs.insert(sig);
            const QString sock = hyprDir.filePath(sig) + QStringLiteral("/.socket.sock");
            if (QFile::exists(sock)) socketPaths.append(sock);
        }
    }

    // Ensure the default (current) instance is included even if it wasn't enumerated.
    const QString currentSig = instanceSignature();
    if (!currentSig.isEmpty() && !seenSigs.contains(currentSig)) {
        const QString sock = runtime + QStringLiteral("/hypr/") + currentSig + QStringLiteral("/.socket.sock");
        if (QFile::exists(sock)) socketPaths.append(sock);
    }

    if (socketPaths.isEmpty()) {
        return setCursor(theme, size);
    }

    const QString cycleCmd = QStringLiteral("setcursor %1 %2");
    bool anyApplied = false;
    for (const QString& sock : socketPaths) {
        // Cycle to a fallback theme first to force Hyprland/wlroots to bust the
        // internal cursor cache, then apply the real theme/size.
        sendToPath(sock, cycleCmd.arg(QStringLiteral("Adwaita"), QString::number(size)), 2000);
        QThread::msleep(50);
        const QString resp = sendToPath(sock, cycleCmd.arg(theme, QString::number(size)), 2000);
        anyApplied = anyApplied || !resp.isEmpty();
    }
    return anyApplied;
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

} // namespace FlightDeck::Hyprland
