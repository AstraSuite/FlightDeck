#include "tokens.hpp"
#include "monitorconfigmanager.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>
#include <QSettings>

namespace caelestia::config {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

}

TokenConfig::TokenConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    QSettings settings(QStringLiteral("astra-foundry"), QStringLiteral("astra"));
    bool sync = settings.value(QStringLiteral("theme/syncTokens"), true).toBool();
    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));
    if (!sync) {
        resetDefaults();
    }
}

TokenConfig::TokenConfig(TokenConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    if (!filePath.isEmpty())
        setupFileBackend(filePath, screen);
    if (fallback)
        syncFromGlobal(fallback);
}

TokenConfig* TokenConfig::instance() {
    static TokenConfig instance;
    return &instance;
}

TokenConfig* TokenConfig::defaults() {
    if (!m_defaults)
        m_defaults = new TokenConfig(nullptr, QString(), QString(), this);
    return m_defaults;
}

TokenConfig* TokenConfig::forScreen(const QString& screen) {
    return MonitorConfigManager::instance()->tokensForScreen(screen);
}

TokenConfig* TokenConfig::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

void TokenConfig::resetDefaults() {
    clearLoadedKeys();
    if (m_appearance) {
        if (m_appearance->rounding()) {
            m_appearance->rounding()->set_extraSmall(4);
            m_appearance->rounding()->set_small(8);
            m_appearance->rounding()->set_medium(12);
            m_appearance->rounding()->set_large(16);
            m_appearance->rounding()->set_largeIncreased(20);
            m_appearance->rounding()->set_extraLarge(28);
            m_appearance->rounding()->set_extraLargeIncreased(32);
            m_appearance->rounding()->set_extraExtraLarge(48);
        }
        if (m_appearance->spacing()) {
            m_appearance->spacing()->set_extraSmall(4);
            m_appearance->spacing()->set_small(8);
            m_appearance->spacing()->set_medium(12);
            m_appearance->spacing()->set_large(16);
            m_appearance->spacing()->set_largeIncreased(20);
            m_appearance->spacing()->set_extraLarge(28);
            m_appearance->spacing()->set_extraLargeIncreased(32);
            m_appearance->spacing()->set_extraExtraLarge(48);
        }
        if (m_appearance->padding()) {
            m_appearance->padding()->set_extraSmall(4);
            m_appearance->padding()->set_small(8);
            m_appearance->padding()->set_medium(12);
            m_appearance->padding()->set_large(16);
            m_appearance->padding()->set_largeIncreased(20);
            m_appearance->padding()->set_extraLarge(28);
            m_appearance->padding()->set_extraLargeIncreased(32);
            m_appearance->padding()->set_extraExtraLarge(48);
        }
        if (m_appearance->fontSize()) {
            m_appearance->fontSize()->set_small(11);
            m_appearance->fontSize()->set_smaller(12);
            m_appearance->fontSize()->set_normal(13);
            m_appearance->fontSize()->set_larger(15);
            m_appearance->fontSize()->set_large(18);
            m_appearance->fontSize()->set_extraLarge(28);
        }
    }
    emit loaded(QString());
}

void TokenConfig::setSync(bool sync) {
    if (sync) {
        reload();
    } else {
        resetDefaults();
    }
}

}
