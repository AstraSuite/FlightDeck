#include "appearanceconfig.hpp"
#include "tokens.hpp"

#include <qmetaobject.h>

namespace caelestia::config {

template <typename Source, typename Target> static void connectTokenSignals(Source* source, Target* target) {
    const auto* meta = source->metaObject();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);

        if (prop.hasNotifySignal())
            QObject::connect(source, prop.notifySignal(), target,
                target->metaObject()->method(target->metaObject()->indexOfSignal("valuesChanged()")));
    }

    QObject::connect(target, &Target::scaleChanged, target, &Target::valuesChanged);
}

void AppearanceRounding::bindTokens(RoundingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearanceRounding::extraSmall() const {
    return static_cast<int>((m_tokens ? m_tokens->extraSmall() : 4) * m_scale);
}

int AppearanceRounding::small() const {
    return static_cast<int>((m_tokens ? m_tokens->small() : 8) * m_scale);
}

int AppearanceRounding::medium() const {
    return static_cast<int>((m_tokens ? m_tokens->medium() : 12) * m_scale);
}

int AppearanceRounding::large() const {
    return static_cast<int>((m_tokens ? m_tokens->large() : 16) * m_scale);
}

int AppearanceRounding::largeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->largeIncreased() : 20) * m_scale);
}

int AppearanceRounding::extraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLarge() : 28) * m_scale);
}

int AppearanceRounding::extraLargeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLargeIncreased() : 32) * m_scale);
}

int AppearanceRounding::extraExtraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraExtraLarge() : 48) * m_scale);
}

int AppearanceRounding::full() const {
    return m_tokens ? static_cast<int>(m_tokens->full()) : 9999;
}

void AppearanceSpacing::bindTokens(SpacingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearanceSpacing::extraSmall() const {
    return static_cast<int>((m_tokens ? m_tokens->extraSmall() : 4) * m_scale);
}

int AppearanceSpacing::small() const {
    return static_cast<int>((m_tokens ? m_tokens->small() : 8) * m_scale);
}

int AppearanceSpacing::medium() const {
    return static_cast<int>((m_tokens ? m_tokens->medium() : 12) * m_scale);
}

int AppearanceSpacing::large() const {
    return static_cast<int>((m_tokens ? m_tokens->large() : 16) * m_scale);
}

int AppearanceSpacing::largeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->largeIncreased() : 20) * m_scale);
}

int AppearanceSpacing::extraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLarge() : 28) * m_scale);
}

int AppearanceSpacing::extraLargeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLargeIncreased() : 32) * m_scale);
}

int AppearanceSpacing::extraExtraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraExtraLarge() : 48) * m_scale);
}

void AppearancePadding::bindTokens(PaddingTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AppearancePadding::extraSmall() const {
    return static_cast<int>((m_tokens ? m_tokens->extraSmall() : 4) * m_scale);
}

int AppearancePadding::small() const {
    return static_cast<int>((m_tokens ? m_tokens->small() : 8) * m_scale);
}

int AppearancePadding::medium() const {
    return static_cast<int>((m_tokens ? m_tokens->medium() : 12) * m_scale);
}

int AppearancePadding::large() const {
    return static_cast<int>((m_tokens ? m_tokens->large() : 16) * m_scale);
}

int AppearancePadding::largeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->largeIncreased() : 20) * m_scale);
}

int AppearancePadding::extraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLarge() : 28) * m_scale);
}

int AppearancePadding::extraLargeIncreased() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLargeIncreased() : 32) * m_scale);
}

int AppearancePadding::extraExtraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraExtraLarge() : 48) * m_scale);
}

void FontConfig::setDefaults(int size, int weight, const QVariantMap& vaxes) {
    m_size = size;
    m_weight = weight;
    m_vaxes = vaxes;
}

void FontStyleConfig::setDefaultFamily(const QString& family) {
    m_family = family;
}

void AnimDurations::bindTokens(AnimDurationTokens* tokens) {
    m_tokens = tokens;
    connectTokenSignals(tokens, this);
}

int AnimDurations::small() const {
    return static_cast<int>((m_tokens ? m_tokens->small() : 200) * m_scale);
}

int AnimDurations::normal() const {
    return static_cast<int>((m_tokens ? m_tokens->normal() : 400) * m_scale);
}

int AnimDurations::large() const {
    return static_cast<int>((m_tokens ? m_tokens->large() : 600) * m_scale);
}

int AnimDurations::extraLarge() const {
    return static_cast<int>((m_tokens ? m_tokens->extraLarge() : 1000) * m_scale);
}

int AnimDurations::expressiveFastSpatial() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveFastSpatial() : 350) * m_scale);
}

int AnimDurations::expressiveDefaultSpatial() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveDefaultSpatial() : 500) * m_scale);
}

int AnimDurations::expressiveSlowSpatial() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveSlowSpatial() : 650) * m_scale);
}

int AnimDurations::expressiveFastEffects() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveFastEffects() : 150) * m_scale);
}

int AnimDurations::expressiveDefaultEffects() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveDefaultEffects() : 200) * m_scale);
}

int AnimDurations::expressiveSlowEffects() const {
    return static_cast<int>((m_tokens ? m_tokens->expressiveSlowEffects() : 300) * m_scale);
}

}
