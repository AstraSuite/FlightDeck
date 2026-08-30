#include "hyprlandschema.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QRegularExpression>

namespace FlightDeck::Hyprland {

static HyprlandSchema* s_instance = nullptr;

HyprlandSchema* HyprlandSchema::instance() {
    if (!s_instance) {
        s_instance = new HyprlandSchema();
    }
    return s_instance;
}

HyprlandSchema* HyprlandSchema::create(QQmlEngine*, QJSEngine*) {
    return instance();
}

HyprlandSchema::HyprlandSchema(QObject* parent)
    : QObject(parent)
{
    loadSchema();
    buildAliases();
}

int HyprlandSchema::optionCount() const {
    return m_rawCatalog.size();
}

QVariantList HyprlandSchema::groups() const {
    return m_groups;
}

void HyprlandSchema::loadSchema() {
    // Try embedded resource first, then local filesystem
    QStringList candidatePaths = {
        QStringLiteral(":/schema/hyprland_options.json"),
        QStringLiteral("/home/dim/Projects/AstraSuite/FlightDeck/data/schema/hyprland_options.json")
    };

    QByteArray catalogData;
    for (const auto& path : candidatePaths) {
        QFile file(path);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            catalogData = file.readAll();
            break;
        }
    }

    if (!catalogData.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(catalogData);
        if (doc.isObject()) {
            m_rawCatalog = doc.object().toVariantMap();
        }
    }

    QStringList groupPaths = {
        QStringLiteral(":/schema/options.json"),
        QStringLiteral("/home/dim/Projects/AstraSuite/FlightDeck/data/schema/options.json")
    };

    QByteArray groupsData;
    for (const auto& path : groupPaths) {
        QFile file(path);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            groupsData = file.readAll();
            break;
        }
    }

    if (!groupsData.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(groupsData);
        if (doc.isObject() && doc.object().contains(QStringLiteral("groups"))) {
            m_groups = doc.object().value(QStringLiteral("groups")).toArray().toVariantList();
        }
    }

    emit schemaLoaded();
}

void HyprlandSchema::buildAliases() {
    // Common aliases used in FlightDeck / Caelestia
    const QList<QPair<QString, QString>> commonAliases = {
        { QStringLiteral("mouseAccelProfile"), QStringLiteral("input:accel_profile") },
        { QStringLiteral("mouseSensitivity"), QStringLiteral("input:sensitivity") },
        { QStringLiteral("mouseForceNoAccel"), QStringLiteral("input:force_no_accel") },
        { QStringLiteral("mouseLeftHanded"), QStringLiteral("input:left_handed") },
        { QStringLiteral("mouseScrollFactor"), QStringLiteral("input:scroll_factor") },
        { QStringLiteral("mouseNaturalScroll"), QStringLiteral("input:natural_scroll") },
        { QStringLiteral("kbLayout"), QStringLiteral("input:kb_layout") },
        { QStringLiteral("kbModel"), QStringLiteral("input:kb_model") },
        { QStringLiteral("kbVariant"), QStringLiteral("input:kb_variant") },
        { QStringLiteral("kbOptions"), QStringLiteral("input:kb_options") },
        { QStringLiteral("kbRules"), QStringLiteral("input:kb_rules") },
        { QStringLiteral("kbNumlock"), QStringLiteral("input:numlock_by_default") },
        { QStringLiteral("kbRepeatRate"), QStringLiteral("input:repeat_rate") },
        { QStringLiteral("kbRepeatDelay"), QStringLiteral("input:repeat_delay") },
        { QStringLiteral("touchpadTapToClick"), QStringLiteral("input:touchpad:tap-to-click") },
        { QStringLiteral("touchpadNaturalScroll"), QStringLiteral("input:touchpad:natural_scroll") },
        { QStringLiteral("touchpadDisableWhileTyping"), QStringLiteral("input:touchpad:disable_while_typing") },
        { QStringLiteral("touchpadScrollFactor"), QStringLiteral("input:touchpad:scroll_factor") },
        { QStringLiteral("touchpadMiddleButtonEmulation"), QStringLiteral("input:touchpad:middle_button_emulation") },
        { QStringLiteral("touchpadClickfingerBehavior"), QStringLiteral("input:touchpad:clickfinger_behavior") },
        { QStringLiteral("touchpadTapAndDrag"), QStringLiteral("input:touchpad:tap-and-drag") },
        { QStringLiteral("touchpadDragLock"), QStringLiteral("input:touchpad:drag_lock") },
        { QStringLiteral("activeOpacity"), QStringLiteral("decoration:active_opacity") },
        { QStringLiteral("inactiveOpacity"), QStringLiteral("decoration:inactive_opacity") },
        { QStringLiteral("fullscreenOpacity"), QStringLiteral("decoration:fullscreen_opacity") },
        { QStringLiteral("dimInactive"), QStringLiteral("decoration:dim_inactive") },
        { QStringLiteral("dimStrength"), QStringLiteral("decoration:dim_strength") },
        { QStringLiteral("dimSpecial"), QStringLiteral("decoration:dim_special") },
        { QStringLiteral("dimAround"), QStringLiteral("decoration:dim_around") },
        { QStringLiteral("dimModal"), QStringLiteral("decoration:dim_modal") },
        { QStringLiteral("snapEnabled"), QStringLiteral("general:snap:enabled") },
        { QStringLiteral("snapWindowGap"), QStringLiteral("general:snap:window_gap") },
        { QStringLiteral("snapMonitorGap"), QStringLiteral("general:snap:monitor_gap") },
        { QStringLiteral("snapBorderOverlap"), QStringLiteral("general:snap:border_overlap") },
        { QStringLiteral("snapRespectGaps"), QStringLiteral("general:snap:respect_gaps") },
        { QStringLiteral("dwindlePreserveSplit"), QStringLiteral("dwindle:preserve_split") },
        { QStringLiteral("dwindleSmartSplit"), QStringLiteral("dwindle:smart_split") },
        { QStringLiteral("dwindleSmartResizing"), QStringLiteral("dwindle:smart_resizing") },
        { QStringLiteral("dwindleForceSplit"), QStringLiteral("dwindle:force_split") },
        { QStringLiteral("dwindleDefaultSplitRatio"), QStringLiteral("dwindle:default_split_ratio") },
        { QStringLiteral("masterMfact"), QStringLiteral("master:mfact") },
        { QStringLiteral("masterNewStatus"), QStringLiteral("master:new_status") },
        { QStringLiteral("masterNewOnTop"), QStringLiteral("master:new_on_top") },
        { QStringLiteral("masterOrientation"), QStringLiteral("master:orientation") },
        { QStringLiteral("masterSmartResizing"), QStringLiteral("master:smart_resizing") },
        { QStringLiteral("masterDropAtCursor"), QStringLiteral("master:drop_at_cursor") },
        { QStringLiteral("cursorInactiveTimeout"), QStringLiteral("cursor:inactive_timeout") },
        { QStringLiteral("cursorNoWarps"), QStringLiteral("cursor:no_warps") },
        { QStringLiteral("cursorHideOnKeyPress"), QStringLiteral("cursor:hide_on_key_press") },
        { QStringLiteral("cursorHideOnTouch"), QStringLiteral("cursor:hide_on_touch") },
        { QStringLiteral("cursorZoomFactor"), QStringLiteral("cursor:zoom_factor") },
        { QStringLiteral("miscVrr"), QStringLiteral("misc:vrr") },
        { QStringLiteral("miscDisableHyprlandLogo"), QStringLiteral("misc:disable_hyprland_logo") },
        { QStringLiteral("miscDisableSplashRendering"), QStringLiteral("misc:disable_splash_rendering") },
        { QStringLiteral("miscForceDefaultWallpaper"), QStringLiteral("misc:force_default_wallpaper") },
        { QStringLiteral("miscMiddleClickPaste"), QStringLiteral("misc:middle_click_paste") },
        { QStringLiteral("miscAnrDialog"), QStringLiteral("misc:enable_anr_dialog") },
        { QStringLiteral("xwaylandEnabled"), QStringLiteral("xwayland:enabled") },
        { QStringLiteral("xwaylandForceZeroScaling"), QStringLiteral("xwayland:force_zero_scaling") },
        { QStringLiteral("xwaylandUseNearestNeighbor"), QStringLiteral("xwayland:use_nearest_neighbor") },
        { QStringLiteral("ecosystemNoUpdateNews"), QStringLiteral("ecosystem:no_update_news") },
        { QStringLiteral("ecosystemNoDonationNag"), QStringLiteral("ecosystem:no_donation_nag") },
    };

    for (const auto& pair : commonAliases) {
        m_aliasToHyprKey[pair.first] = pair.second;
        m_hyprKeyToAlias[pair.second] = pair.first;
    }
}

bool HyprlandSchema::hasOption(const QString& key) const {
    QString canonical = toHyprKey(key);
    return m_rawCatalog.contains(canonical);
}

QVariantMap HyprlandSchema::getOption(const QString& key) const {
    QString canonical = toHyprKey(key);
    return m_rawCatalog.value(canonical).toMap();
}

QVariant HyprlandSchema::getDefault(const QString& key, const QVariant& fallback) const {
    QVariantMap opt = getOption(key);
    if (opt.contains(QStringLiteral("default"))) {
        return opt.value(QStringLiteral("default"));
    }
    return fallback;
}

QString HyprlandSchema::getType(const QString& key) const {
    return getOption(key).value(QStringLiteral("type")).toString();
}

QString HyprlandSchema::getDescription(const QString& key) const {
    return getOption(key).value(QStringLiteral("description")).toString();
}

QString HyprlandSchema::getLabel(const QString& key) const {
    return getOption(key).value(QStringLiteral("label")).toString();
}

double HyprlandSchema::getMin(const QString& key, double fallback) const {
    QVariantMap opt = getOption(key);
    if (opt.contains(QStringLiteral("min"))) {
        return opt.value(QStringLiteral("min")).toDouble();
    }
    return fallback;
}

double HyprlandSchema::getMax(const QString& key, double fallback) const {
    QVariantMap opt = getOption(key);
    if (opt.contains(QStringLiteral("max"))) {
        return opt.value(QStringLiteral("max")).toDouble();
    }
    return fallback;
}

double HyprlandSchema::getStep(const QString& key, double fallback) const {
    QVariantMap opt = getOption(key);
    if (opt.contains(QStringLiteral("step"))) {
        return opt.value(QStringLiteral("step")).toDouble();
    }
    return fallback;
}

QVariantList HyprlandSchema::getChoices(const QString& key) const {
    return getOption(key).value(QStringLiteral("values")).toList();
}

QStringList HyprlandSchema::allKeys() const {
    return m_rawCatalog.keys();
}

QString HyprlandSchema::toHyprKey(const QString& key) const {
    if (m_aliasToHyprKey.contains(key)) {
        return m_aliasToHyprKey.value(key);
    }
    return key;
}

QString HyprlandSchema::toShortKey(const QString& key) const {
    if (m_hyprKeyToAlias.contains(key)) {
        return m_hyprKeyToAlias.value(key);
    }
    return key;
}

static void insertNestedOption(QVariantMap& tree, const QStringList& pathParts, const QVariant& value) {
    if (pathParts.isEmpty()) return;
    if (pathParts.size() == 1) {
        QString leaf = pathParts.first();
        leaf.replace(QLatin1Char('-'), QLatin1Char('_'));
        tree[leaf] = value;
        return;
    }

    QString head = pathParts.first();
    head.replace(QLatin1Char('-'), QLatin1Char('_'));
    QVariantMap subTree = tree.value(head).toMap();
    insertNestedOption(subTree, pathParts.mid(1), value);
    tree[head] = subTree;
}

static QString formatLuaValue(const QVariant& val) {
    if (val.typeId() == QMetaType::Bool) {
        return val.toBool() ? QStringLiteral("true") : QStringLiteral("false");
    }
    if (val.typeId() == QMetaType::Int || val.typeId() == QMetaType::LongLong) {
        return QString::number(val.toLongLong());
    }
    if (val.typeId() == QMetaType::Double) {
        return QString::number(val.toDouble());
    }
    QString str = val.toString();
    if (str == QStringLiteral("true") || str == QStringLiteral("false")) {
        return str;
    }
    bool ok = false;
    double d = str.toDouble(&ok);
    if (ok && !str.startsWith(QStringLiteral("0x")) && !str.startsWith(QStringLiteral("+")) && !str.contains(QStringLiteral(" "))) {
        return str;
    }
    return QStringLiteral("\"%1\"").arg(str);
}

static QString formatLuaTree(const QVariantMap& tree, int indentLevel) {
    QString out;
    const QString indent(indentLevel * 4, QLatin1Char(' '));

    for (auto it = tree.constBegin(); it != tree.constEnd(); ++it) {
        QString k = it.key();
        if (it.value().typeId() == QMetaType::QVariantMap) {
            QVariantMap sub = it.value().toMap();
            if (!sub.isEmpty()) {
                out += QStringLiteral("%1%2 = {\n").arg(indent, k);
                out += formatLuaTree(sub, indentLevel + 1);
                out += QStringLiteral("%1},\n").arg(indent);
            }
        } else {
            out += QStringLiteral("%1%2 = %3,\n").arg(indent, k, formatLuaValue(it.value()));
        }
    }
    return out;
}

QString HyprlandSchema::serializeToLuaConfig(const QVariantMap& options) const {
    if (options.isEmpty()) return QString();

    QVariantMap rootTree;
    for (auto it = options.constBegin(); it != options.constEnd(); ++it) {
        QString hyprKey = toHyprKey(it.key());
        QStringList parts = hyprKey.split(QLatin1Char(':'));
        insertNestedOption(rootTree, parts, it.value());
    }

    if (rootTree.isEmpty()) return QString();

    QString result = QStringLiteral("hl.config({\n");
    result += formatLuaTree(rootTree, 1);
    result += QStringLiteral("})\n");
    return result;
}

} // namespace FlightDeck::Hyprland
