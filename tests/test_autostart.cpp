#include <QCoreApplication>
#include <QDebug>
#include <cassert>
#include "managers/autostartmanager.hpp"
#include "caelestia/flightdeckwriter.hpp"
#include "caelestia/luavalidator.hpp"
#include "hyprland/hyprlandschema.hpp"

using namespace FlightDeck::Managers;

int main(int argc, char* argv[]) {
    Q_INIT_RESOURCE(test_schema_resources);
    QCoreApplication app(argc, argv);
    AutostartManager mgr;

    // Test 1: Solaar minimize flag detection
    QVariantMap solaarInfo = mgr.detectMinimizeFlags("solaar");
    qDebug() << "Solaar flag:" << solaarInfo;
    assert(solaarInfo["flag"].toString() == "-w hide");
    assert(solaarInfo["hasFlag"].toBool() == false);

    // Test 2: Solaar with flag already present
    QVariantMap solaarWithFlag = mgr.detectMinimizeFlags("solaar -w hide");
    qDebug() << "Solaar with flag:" << solaarWithFlag;
    assert(solaarWithFlag["hasFlag"].toBool() == true);
    assert(solaarWithFlag["cleanCmd"].toString() == "solaar");

    // Test 3: Element desktop
    QVariantMap elementInfo = mgr.detectMinimizeFlags("element-desktop");
    qDebug() << "Element info:" << elementInfo;
    assert(elementInfo["flag"].toString() == "--hidden");

    // Test 4: Discord / Vesktop
    QVariantMap vesktopInfo = mgr.detectMinimizeFlags("vesktop");
    qDebug() << "Vesktop info:" << vesktopInfo;
    assert(vesktopInfo["flag"].toString() == "--start-minimized");

    // Test 5: Parse command with sleep delay
    QVariantMap parsedSleep = mgr.parseCommand("sleep 5 && solaar -w hide", false);
    qDebug() << "Parsed sleep:" << parsedSleep;
    assert(parsedSleep["delay"].toInt() == 5);
    assert(parsedSleep["command"].toString() == "solaar -w hide");
    assert(parsedSleep["hasMinimizeFlag"].toBool() == true);
    assert(parsedSleep["onReload"].toBool() == false);

    // Test 6: Build final command with delay and minimized
    QString finalCmd1 = mgr.buildFinalCommand("solaar", 3, true, "-w hide");
    qDebug() << "Built final 1:" << finalCmd1;
    assert(finalCmd1 == "sleep 3 && solaar -w hide");

    // Test 7: Build final command without delay and not minimized
    QString finalCmd2 = mgr.buildFinalCommand("solaar -w hide", 0, false, "-w hide");
    qDebug() << "Built final 2:" << finalCmd2;
    assert(finalCmd2 == "solaar");

    // Test 8: Build final command with delay only
    QString finalCmd3 = mgr.buildFinalCommand("waybar", 2, false, "");
    qDebug() << "Built final 3:" << finalCmd3;
    assert(finalCmd3 == "sleep 2 && waybar");

    // Test 9: Add command with reload
    auto writer = FlightDeck::Caelestia::FlightDeckWriter::instance();
    writer->addAutostart("sleep 2 && waybar", true);
    auto entries = writer->autostartEntries();
    bool foundReload = false;
    for (const auto& e : entries) {
        if (e.toMap()["command"].toString() == "sleep 2 && waybar" && e.toMap()["onReload"].toBool() == true) {
            foundReload = true;
            break;
        }
    }
    assert(foundReload);

    // Test 10: Verify isReadOnly system entries
    QVariantMap parsedReadOnly = mgr.parseCommand("gnome-keyring-daemon --start", false, true);
    assert(parsedReadOnly["isReadOnly"].toBool() == true);

    // Test 11: HyprlandSchema option catalog & serialization
    auto schema = FlightDeck::Hyprland::HyprlandSchema::instance();
    qDebug() << "HyprlandSchema total options:" << schema->optionCount();
    qDebug() << "Keybind sections count:" << schema->keybindSections().size();
    assert(schema->keybindSections().size() > 0);
    assert(schema->optionCount() >= 300);
    assert(schema->hasOption("general:border_size"));
    assert(schema->hasOption("input:touchpad:tap-to-click"));
    assert(schema->getType("input:touchpad:tap-to-click") == "bool");
    assert(schema->getDefault("general:border_size").toInt() == 1);
    assert(schema->toHyprKey("mouseAccelProfile") == "input:accel_profile");

    // Test 12: Dynamic serialization
    QVariantMap testOpts = {
        { "input:accel_profile", "adaptive" },
        { "input:touchpad:tap-to-click", true },
        { "general:snap:window_gap", 10 }
    };
    QString serializedLua = schema->serializeToLuaConfig(testOpts);
    qDebug() << "Serialized dynamic Lua config:\n" << serializedLua;
    assert(serializedLua.contains("hl.config({"));
    assert(serializedLua.contains("input = {"));
    assert(serializedLua.contains("touchpad = {"));
    assert(serializedLua.contains("tap_to_click = true,"));
    assert(serializedLua.contains("accel_profile = \"adaptive\","));
    assert(serializedLua.contains("snap = {"));
    assert(serializedLua.contains("window_gap = 10,"));

    // Test 13: FlightDeckWriter getHyprOption/hasHyprOption/removeHyprOption canonical alias resolution
    writer->setHyprOption("mouseAccelProfile", "flat");
    assert(writer->hasHyprOption("mouseAccelProfile"));
    assert(writer->hasHyprOption("input:accel_profile"));
    assert(writer->getHyprOption("mouseAccelProfile").toString() == "flat");
    assert(writer->getHyprOption("input:accel_profile").toString() == "flat");

    // Test 14: Plugin schema detection & serialization
    qDebug() << "Supported plugins count:" << schema->supportedPlugins().size();
    assert(schema->supportedPlugins().size() >= 1);
    assert(schema->hasOption("plugin:dynamic-cursors:mode"));
    assert(schema->getDefault("plugin:dynamic-cursors:mode").toString() == "tilt");
    assert(schema->getDefault("plugin:dynamic-cursors:threshold").toInt() == 2);

    QVariantMap pluginOpts = {
        { "plugin:dynamic-cursors:mode", "rotate" },
        { "plugin:dynamic-cursors:rotate:length", 24 }
    };
    QString pluginLua = schema->serializeToLuaConfig(pluginOpts);
    qDebug() << "Plugin Lua output:\n" << pluginLua;
    // Test 15: Custom binds with special characters, quotes, $() shell commands & Lua validation
    writer->addCustomBind("SUPER + V", "exec", "sleep 0.5s && ydotool type -d 1 \"$(cliphist list | head -1 | cliphist decode)\"", true);
    writer->addCustomBind("ALT + Tab", "global", "caelestia:windowSwitcher", true);
    writer->addCustomBind("SUPER + Q", "killactive", "", true);
    QString flightdeckLua = writer->formatLua();
    qDebug() << "FlightDeck generated Lua:\n" << flightdeckLua;
    assert(flightdeckLua.contains("hl.bind(\"SUPER + V\", hl.dsp.exec_cmd(\"sleep 0.5s && ydotool type -d 1 \\\"$(cliphist list | head -1 | cliphist decode)\\\"\"))"));
    assert(flightdeckLua.contains("hl.bind(\"ALT + Tab\", hl.dsp.global(\"caelestia:windowSwitcher\"))"));
    assert(flightdeckLua.contains("hl.bind(\"SUPER + Q\", hl.dsp.killactive())"));

    QString valErr;
    bool isValid = FlightDeck::Caelestia::LuaValidator::validate(flightdeckLua, &valErr);
    if (!isValid) {
        qCritical() << "Generated Lua validation error:" << valErr;
    }
    // Test 16: Hyprcursor detection & aliases
    assert(schema->toHyprKey("cursorEnableHyprcursor") == "cursor:enable_hyprcursor");
    assert(schema->toHyprKey("cursor_enable_hyprcursor") == "cursor:enable_hyprcursor");
    assert(schema->toHyprKey("cursor:hyprcursor") == "cursor:enable_hyprcursor");
    assert(schema->toHyprKey("cursor.hyprcursor") == "cursor:enable_hyprcursor");
    assert(schema->toHyprKey("cursor.enable_hyprcursor") == "cursor:enable_hyprcursor");
    assert(schema->toHyprKey("enable_hyprcursor") == "cursor:enable_hyprcursor");

    writer->setHyprOption("cursor:enable_hyprcursor", true);
    assert(writer->hasHyprOption("cursorEnableHyprcursor"));
    assert(writer->hasHyprOption("cursor:enable_hyprcursor"));
    assert(writer->getHyprOption("cursorEnableHyprcursor").toBool() == true);
    assert(writer->getHyprOption("cursor:enable_hyprcursor").toBool() == true);

    qDebug() << "=== ALL AUTOSTART & SCHEMA UNIT TESTS PASSED SUCCESSFULLY! ===";
    return 0;
}
