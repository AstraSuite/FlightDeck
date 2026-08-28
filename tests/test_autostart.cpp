#include <QCoreApplication>
#include <QDebug>
#include <cassert>
#include "managers/autostartmanager.hpp"
#include "caelestia/flightdeckwriter.hpp"

using namespace FlightDeck::Managers;

int main(int argc, char* argv[]) {
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

    qDebug() << "=== ALL AUTOSTART UNIT TESTS PASSED SUCCESSFULLY! ===";
    return 0;
}
