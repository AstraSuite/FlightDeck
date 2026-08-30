#include "hyprlandstate.hpp"
#include "hyprlandsocket.hpp"
#include "hyprlandevents.hpp"

#include <QJsonObject>
#include <QJsonArray>
#include <QProcess>
#include <QDir>
#include <QFile>

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <drm/drm.h>
#include <drm/drm_mode.h>
#include <cmath>

namespace FlightDeck::Hyprland {

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
    } else {
        m_hasTouchpad = true;
        m_hasTouchscreen = true;
    }
    emit devicesChanged();
}

struct MonitorCaps {
    bool tenBit = false;
    bool hdr = false;
    bool vrr = false;
    double maxLuminance = 0;
    double maxAvgLuminance = 0;
    double minLuminance = 0;
    bool hasMasteringLuminance = false;
};

static MonitorCaps queryMonitorHardwareCaps(const QString& connectorName) {
    MonitorCaps caps;
    const QDir drmDir(QStringLiteral("/sys/class/drm"));
    if (!drmDir.exists()) return caps;

    QString matchedPath;
    QString cardName;
    const auto entries = drmDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& entry : entries) {
        if (entry.startsWith(QLatin1String("card")) && entry.endsWith(QLatin1String("-") + connectorName)) {
            matchedPath = drmDir.filePath(entry);
            int hyphenIdx = entry.indexOf(QLatin1Char('-'));
            if (hyphenIdx != -1) {
                cardName = entry.left(hyphenIdx);
            }
            break;
        }
    }

    if (matchedPath.isEmpty()) return caps;

    // 1. Read EDID from sysfs
    QFile edidFile(matchedPath + QStringLiteral("/edid"));
    if (edidFile.open(QIODevice::ReadOnly)) {
        const QByteArray edid = edidFile.readAll();
        edidFile.close();

        if (edid.size() >= 128) {
            quint8 vMajor = static_cast<quint8>(edid.at(18));
            quint8 vMinor = static_cast<quint8>(edid.at(19));
            if (vMajor > 1 || (vMajor == 1 && vMinor >= 4)) {
                quint8 depthCode = (static_cast<quint8>(edid.at(20)) >> 4) & 0x07;
                caps.tenBit = (depthCode >= 3);
            }

            quint8 numExt = static_cast<quint8>(edid.at(126));
            for (int extIdx = 0; extIdx < numExt; ++extIdx) {
                int offset = 128 * (extIdx + 1);
                if (offset + 128 > edid.size()) break;
                if (static_cast<quint8>(edid.at(offset)) != 0x02) continue; // CEA extension

                int dtdStart = qMin(static_cast<int>(static_cast<quint8>(edid.at(offset + 2))), 128);
                int pos = 4;
                while (pos < dtdStart - 1) {
                    quint8 header = static_cast<quint8>(edid.at(offset + pos));
                    quint8 tag = (header >> 5) & 0x07;
                    quint8 length = header & 0x1F;
                    if (tag == 7 && length >= 1) { // Extended tag
                        quint8 extTag = static_cast<quint8>(edid.at(offset + pos + 1));
                        if (extTag == 6) { // HDR Static Metadata
                            caps.hdr = true;
                            if (length >= 4) {
                                quint8 maxLumCode = static_cast<quint8>(edid.at(offset + pos + 3));
                                caps.maxLuminance = 50.0 * std::pow(2.0, maxLumCode / 32.0);
                                caps.hasMasteringLuminance = true;
                                if (length >= 5) {
                                    quint8 maxAvgCode = static_cast<quint8>(edid.at(offset + pos + 4));
                                    caps.maxAvgLuminance = 50.0 * std::pow(2.0, maxAvgCode / 32.0);
                                }
                                if (length >= 6) {
                                    quint8 minLumCode = static_cast<quint8>(edid.at(offset + pos + 5));
                                    caps.minLuminance = caps.maxLuminance * std::pow(minLumCode / 255.0, 2.0) / 100.0;
                                }
                            }
                            break;
                        }
                    }
                    pos += length + 1;
                }
            }
        }
    }

    // 2. Query VRR capability via DRM ioctl
    if (!cardName.isEmpty()) {
        const QString devPath = QStringLiteral("/dev/dri/%1").arg(cardName);
        int fd = ::open(devPath.toUtf8().constData(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (fd >= 0) {
            struct drm_mode_card_res res {};
            if (::ioctl(fd, DRM_IOCTL_MODE_GETRESOURCES, &res) == 0 && res.count_connectors > 0) {
                QVector<uint32_t> connIds(res.count_connectors);
                res.connector_id_ptr = reinterpret_cast<uint64_t>(connIds.data());
                if (::ioctl(fd, DRM_IOCTL_MODE_GETRESOURCES, &res) == 0) {
                    for (uint32_t connId : connIds) {
                        struct drm_mode_get_connector conn {};
                        conn.connector_id = connId;
                        if (::ioctl(fd, DRM_IOCTL_MODE_GETCONNECTOR, &conn) == 0) {
                            static const char* connTypes[] = {
                                "Unknown", "VGA", "DVI-I", "DVI-D", "DVI-A",
                                "Composite", "SVIDEO", "LVDS", "Component", "DIN",
                                "DP", "HDMI-A", "HDMI-B", "TV", "eDP",
                                "Virtual", "DSI", "DPI", "Writeback", "SPI", "USB"
                            };
                            QString typeName = (conn.connector_type < sizeof(connTypes)/sizeof(connTypes[0]))
                                ? QString::fromLatin1(connTypes[conn.connector_type])
                                : QString::number(conn.connector_type);
                            QString drmName = QStringLiteral("%1-%2").arg(typeName).arg(conn.connector_type_id);
                            if (drmName == connectorName && conn.connection == 1) { // 1 == DRM_MODE_CONNECTED
                                if (conn.count_props > 0) {
                                    QVector<uint32_t> props(conn.count_props);
                                    QVector<uint64_t> propVals(conn.count_props);
                                    QVector<uint32_t> encs(qMax(conn.count_encoders, 1u));
                                    QByteArray modesBuf(68 * qMax(conn.count_modes, 1u), 0);

                                    struct drm_mode_get_connector conn2 {};
                                    conn2.connector_id = connId;
                                    conn2.count_props = conn.count_props;
                                    conn2.props_ptr = reinterpret_cast<uint64_t>(props.data());
                                    conn2.prop_values_ptr = reinterpret_cast<uint64_t>(propVals.data());
                                    conn2.count_encoders = conn.count_encoders;
                                    conn2.encoders_ptr = reinterpret_cast<uint64_t>(encs.data());
                                    conn2.count_modes = conn.count_modes;
                                    conn2.modes_ptr = reinterpret_cast<uint64_t>(modesBuf.data());

                                    if (::ioctl(fd, DRM_IOCTL_MODE_GETCONNECTOR, &conn2) == 0) {
                                        for (uint32_t p = 0; p < conn2.count_props; ++p) {
                                            struct drm_mode_get_property prop {};
                                            prop.prop_id = props[p];
                                            if (::ioctl(fd, DRM_IOCTL_MODE_GETPROPERTY, &prop) == 0) {
                                                if (qstrcmp(prop.name, "vrr_capable") == 0) {
                                                    caps.vrr = (propVals[p] == 1);
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            }
            ::close(fd);
        }
    }

    return caps;
}

QVariantList HyprlandState::monitors() const {
    const QJsonDocument doc = HyprlandSocket::instance()->queryJson(QStringLiteral("monitors all"));
    if (doc.isArray()) {
        QVariantList list;
        const QJsonArray arr = doc.array();
        for (const auto& item : arr) {
            QVariantMap mon = item.toObject().toVariantMap();
            QString name = mon.value(QStringLiteral("name")).toString();
            MonitorCaps caps = queryMonitorHardwareCaps(name);

            mon[QStringLiteral("supportsHdr")] = caps.hdr;
            mon[QStringLiteral("supports10Bit")] = caps.tenBit;
            mon[QStringLiteral("supportsVrr")] = caps.vrr;
            if (caps.hasMasteringLuminance) {
                mon[QStringLiteral("edidMinLuminance")] = caps.minLuminance;
                mon[QStringLiteral("edidMaxLuminance")] = caps.maxLuminance;
                mon[QStringLiteral("edidMaxAvgLuminance")] = caps.maxAvgLuminance;
            }

            if (mon.contains(QStringLiteral("colorManagementPreset"))) {
                mon[QStringLiteral("colorManagement")] = mon.value(QStringLiteral("colorManagementPreset"));
            }

            list.append(mon);
        }
        return list;
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

void HyprlandState::startCapture() {
    auto socket = HyprlandSocket::instance();
    if (!socket) return;
    socket->evalLua(QStringLiteral("hl.define_submap(\"flightdeck_capture\", function() hl.bind(\"catchall\", function() end) end); hl.dispatch(hl.dsp.submap(\"flightdeck_capture\"))"));
}

void HyprlandState::stopCapture() {
    auto socket = HyprlandSocket::instance();
    if (!socket) return;
    socket->evalLua(QStringLiteral("hl.dispatch(hl.dsp.submap(\"reset\"))"));
}

} // namespace FlightDeck::Hyprland
