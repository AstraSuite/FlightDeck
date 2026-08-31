#include <QCoreApplication>
#include <QDebug>
#include <cassert>
#include "managers/keybindvalidator.hpp"
#include "managers/targetinspector.hpp"
#include "managers/diagnosticsmanager.hpp"
#include "caelestia/caelestiavars.hpp"
#include "caelestia/flightdeckwriter.hpp"
#include "caelestia/luavalidator.hpp"
#include "hyprland/hyprlandschema.hpp"

using namespace FlightDeck::Managers;

int main(int argc, char* argv[]) {
    Q_INIT_RESOURCE(test_phase1_schema_resources);
    QCoreApplication app(argc, argv);

    qDebug() << "=== Running Phase 1 Unit Tests ===";

    // Test 1: Keybind chord normalization
    auto validator = KeybindValidator::instance();
    assert(validator->normalizeChord("SUPER + Q") == "SUPER+Q");
    assert(validator->normalizeChord("SUPER, q") == "SUPER+Q");
    assert(validator->normalizeChord("SHIFT + SUPER + Return") == "SUPER+SHIFT+RETURN");
    assert(validator->normalizeChord("ctrl + alt + t") == "CTRL+ALT+T");
    assert(validator->normalizeChord("ALT+CTRL+Shift+Super+k") == "SUPER+CTRL+ALT+SHIFT+K");

    // Test 2: $mainMod resolution
    assert(validator->normalizeChord("$mainMod, Return") == "SUPER+RETURN");
    assert(validator->normalizeChord("$mainMod + Shift, D") == "SUPER+SHIFT+D");

    // Test 3: Conflict & Override detection
    auto writer = FlightDeck::Caelestia::FlightDeckWriter::instance();
    writer->setCustomBinds(QVariantList{
        QVariantMap{ { QStringLiteral("key"), QStringLiteral("SUPER + Q") }, { QStringLiteral("dispatcher"), QStringLiteral("killactive") }, { QStringLiteral("args"), QString() } },
        QVariantMap{ { QStringLiteral("key"), QStringLiteral("SUPER, q") }, { QStringLiteral("dispatcher"), QStringLiteral("exec") }, { QStringLiteral("args"), QStringLiteral("rofi -show drun") } },
        QVariantMap{ { QStringLiteral("key"), QStringLiteral("SUPER + T") }, { QStringLiteral("dispatcher"), QStringLiteral("exec") }, { QStringLiteral("args"), QStringLiteral("kitty") } }
    });
    validator->refresh();

    assert(validator->hasTrueConflict(QStringLiteral("SUPER+Q")));
    assert(validator->trueConflictCount() >= 1);
    assert(validator->isOverridden(QStringLiteral("SUPER+T")));
    assert(!validator->hasTrueConflict(QStringLiteral("SUPER+T")));

    QVariantMap conflict = validator->checkConflictForChord(QStringLiteral("SUPER+Q"));
    assert(!conflict.isEmpty());
    assert(conflict[QStringLiteral("chord")].toString() == QStringLiteral("SUPER+Q"));
    assert(conflict[QStringLiteral("isTrueConflict")].toBool() == true);

    QVariantMap overrideInfo = validator->getOverrideInfo(QStringLiteral("SUPER+T"));
    assert(!overrideInfo.isEmpty());
    assert(overrideInfo[QStringLiteral("isOverride")].toBool() == true);

    // Test checkChord on existing single custom shortcut
    QVariantMap checkCustom = validator->checkChord(QStringLiteral("SUPER + T"));
    assert(!checkCustom.isEmpty());
    assert(checkCustom[QStringLiteral("customCount")].toInt() >= 1);
    assert(checkCustom[QStringLiteral("hasCustomConflict")].toBool() == true);

    // Test checkChord on existing single default system bind
    QVariantMap checkSystem = validator->checkChord(QStringLiteral("SUPER + W"));
    assert(!checkSystem.isEmpty());
    assert(checkSystem[QStringLiteral("systemCount")].toInt() >= 1);
    assert(checkSystem[QStringLiteral("isOverride")].toBool() == true);

    // Test 4: TargetInspector singleton instantiation & initial states
    auto inspector = TargetInspector::instance();
    assert(inspector != nullptr);
    assert(!inspector->isPicking());
    inspector->startWindowPicker();
    assert(inspector->isPicking());
    inspector->cancelPicker();
    assert(!inspector->isPicking());

    // Test 5: DiagnosticsManager checks
    auto diag = DiagnosticsManager::instance();
    diag->runAllChecks();
    QVariantList results = diag->results();
    assert(!results.isEmpty());
    qDebug() << "Diagnostics total checks:" << results.size();
    qDebug() << "Pass count:" << diag->passCount() << "Warnings:" << diag->warningCount() << "Errors:" << diag->errorCount();

    // Verify presence of core diagnostic checks
    bool hasCompositor = false;
    bool hasGraphics = false;
    bool hasKeybinds = false;
    for (const auto& itemVal : results) {
        QVariantMap item = itemVal.toMap();
        QString cat = item["category"].toString();
        if (cat == "Compositor") hasCompositor = true;
        if (cat == "Graphics") hasGraphics = true;
        if (cat == "Keybinds") hasKeybinds = true;
    }
    assert(hasCompositor);
    assert(hasGraphics);
    assert(hasKeybinds);

    qDebug() << "=== ALL PHASE 1 UNIT TESTS PASSED SUCCESSFULLY! ===";
    return 0;
}
