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
    assert(checkCustom[QStringLiteral("isOverride")].toBool() == true);
    assert(checkCustom[QStringLiteral("isOverridingSystem")].toBool() == false);

    // Test checkChord on existing single default system bind
    QVariantMap checkSystem = validator->checkChord(QStringLiteral("SUPER + W"));
    assert(!checkSystem.isEmpty());
    assert(checkSystem[QStringLiteral("systemCount")].toInt() >= 1);
    assert(checkSystem[QStringLiteral("isOverride")].toBool() == false);
    assert(checkSystem[QStringLiteral("isOverridingSystem")].toBool() == true);

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

    // Test 6: Keybind Flags Serialization
    writer->setCustomBinds(QVariantList{
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("XF86AudioRaiseVolume") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") },
            { QStringLiteral("flags"), QVariantMap{
                { QStringLiteral("repeating"), true },
                { QStringLiteral("locked"), true }
            } }
        },
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + Q") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("kitty") },
            { QStringLiteral("flags"), QVariantMap{
                { QStringLiteral("description"), QStringLiteral("Open my favourite terminal") }
            } }
        },
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + SUPER_L") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("pkill wofi || wofi") },
            { QStringLiteral("flags"), QVariantMap{
                { QStringLiteral("release"), true }
            } }
        }
    });

    QString lua = writer->formatLua();
    assert(lua.contains("hl.bind(\"XF86AudioRaiseVolume\", hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+\"), { locked = true, repeating = true })"));
    assert(lua.contains("hl.bind(\"SUPER + Q\", hl.dsp.exec_cmd(\"kitty\"), { description = \"Open my favourite terminal\" })"));
    assert(lua.contains("hl.bind(\"SUPER + SUPER_L\", hl.dsp.exec_cmd(\"pkill wofi || wofi\"), { release = true })"));

    // Test 7: Validator handles disparate trigger types on same chord without collision
    writer->setCustomBinds(QVariantList{
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + XF86AudioNext") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("playerctl next") },
            { QStringLiteral("flags"), QVariantMap{ { QStringLiteral("long_press"), true } } }
        },
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + XF86AudioNext") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("playerctl position +5") }
        }
    });
    validator->refresh();
    assert(!validator->hasTrueConflict(QStringLiteral("SUPER+XF86AUDIONEXT")));

    // Test 8: Validator detects true conflicts when triggers match
    writer->setCustomBinds(QVariantList{
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + XF86AudioNext") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("playerctl next") },
            { QStringLiteral("flags"), QVariantMap{ { QStringLiteral("long_press"), true } } }
        },
        QVariantMap{
            { QStringLiteral("key"), QStringLiteral("SUPER + XF86AudioNext") },
            { QStringLiteral("dispatcher"), QStringLiteral("exec") },
            { QStringLiteral("args"), QStringLiteral("playerctl position +5") },
            { QStringLiteral("flags"), QVariantMap{ { QStringLiteral("long_press"), true } } }
        }
    });
    validator->refresh();
    assert(validator->hasTrueConflict(QStringLiteral("SUPER+XF86AUDIONEXT")));

    // Test 9: Animation & Bezier Curve persistence in FlightDeckWriter
    writer->addBezierCurve(QStringLiteral("test_curve"), 0.2, 0.0, 0.0, 1.0);
    writer->setAnimationTarget(QStringLiteral("windows"), true, 6.0, QStringLiteral("test_curve"), QStringLiteral("slide"));
    QString animLua = writer->formatLua();
    assert(animLua.contains("hl.curve(\"test_curve\", { type = \"bezier\", points = { { 0.20, 0.00 }, { 0.00, 1.00 } } })"));
    assert(animLua.contains("hl.animation({\n    leaf = \"windows\",\n    enabled = true,\n    speed = 6,\n    bezier = \"test_curve\",\n    style = \"slide\",\n})"));

    // Toggle enabled off
    writer->setAnimationTargetEnabled(QStringLiteral("windows"), false);
    animLua = writer->formatLua();
    assert(animLua.contains("enabled = false"));

    // Remove bezier curve
    writer->removeBezierCurve(QStringLiteral("test_curve"));
    animLua = writer->formatLua();
    assert(!animLua.contains("hl.curve(\"test_curve\""));

    qDebug() << "=== ALL PHASE 1 UNIT TESTS PASSED SUCCESSFULLY! ===";
    return 0;
}
