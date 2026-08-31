#include <QCoreApplication>
#include <cassert>
#include <iostream>
#include "../src/managers/hyprpmmanager.hpp"
#include "../src/hyprland/hyprlandschema.hpp"

using namespace FlightDeck::Managers;

int main(int argc, char* argv[]) {
    Q_INIT_RESOURCE(test_hyprpm_schema_resources);
    QCoreApplication app(argc, argv);

    std::cout << "=== Running Hyprpm Manager Unit Tests ===\n";

    // Test 1: Parser for hyprpm list output
    QString sampleList = QStringLiteral(
        "→ Repository HyprGlass (by hyprnux):\n"
        "  │ Plugin hyprglass\n"
        "  └─ enabled: false\n"
        "\n"
        "→ Repository dynamic-cursors (by virtcode):\n"
        "  │ Plugin dynamic-cursors\n"
        "  └─ enabled: true\n"
        "\n"
        "→ Repository https://github.com/outfoxxed/hy3:\n"
        "  │ Plugin hy3\n"
        "  └─ enabled: true\n"
    );

    QList<PluginRepoInfo> parsed = HyprpmManager::parseHyprpmList(sampleList);
    assert(parsed.size() == 3);

    assert(parsed[0].name == "hyprglass");
    assert(parsed[0].author == "hyprnux");
    assert(parsed[0].enabled == false);
    assert(parsed[0].installed == true);

    assert(parsed[1].name == "dynamic-cursors");
    assert(parsed[1].author == "virtcode");
    assert(parsed[1].enabled == true);
    assert(parsed[1].installed == true);

    assert(parsed[2].name == "hy3");
    assert(parsed[2].enabled == true);
    assert(parsed[2].installed == true);

    std::cout << "Test 1: parseHyprpmList passed!\n";

    // Test 2: HyprpmManager singleton and catalog merging
    auto manager = HyprpmManager::instance();
    assert(manager != nullptr);
    assert(!manager->isBusy());

    QVariantList all = manager->allPlugins();
    assert(!all.isEmpty());
    std::cout << "Total plugins in catalog: " << all.size() << "\n";
    std::cout << "Installed plugins count: " << manager->installedCount() << "\n";
    std::cout << "Available plugins count: " << manager->availableCount() << "\n";

    assert(manager->installedCount() + manager->availableCount() >= all.size());

    // Test 3: Check dynamic-cursors or hyprglass presence in catalog
    bool foundDynamicCursors = false;
    for (const auto& pVal : all) {
        QVariantMap p = pVal.toMap();
        if (p["name"].toString() == "dynamic-cursors" || p["id"].toString() == "hypr-dynamic-cursors") {
            foundDynamicCursors = true;
            assert(!p["label"].toString().isEmpty());
            assert(!p["description"].toString().isEmpty());
            break;
        }
    }
    assert(foundDynamicCursors);
    std::cout << "Test 3: Catalog integrity passed!\n";

    std::cout << "=== ALL HYPRPM MANAGER UNIT TESTS PASSED SUCCESSFULLY! ===\n";
    return 0;
}
