#include "clihandler.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../managers/profilemanager.hpp"

#include <QCommandLineParser>
#include <iostream>

#ifndef ASTRA_VERSION
#define ASTRA_VERSION "1.0.0"
#endif

namespace FlightDeck::Cli {

int CliHandler::run(int argc, char* argv[]) {
    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("FlightDeck - Hyprland Configuration Suite for Astra"));
    parser.addHelpOption();
    parser.addVersionOption();

    parser.addPositionalArgument(QStringLiteral("command"), QStringLiteral("Command to execute (get, set, reload, profile)"));
    parser.addPositionalArgument(QStringLiteral("args"), QStringLiteral("Arguments for command"), QStringLiteral("[args...]"));

    QStringList args;
    for (int i = 0; i < argc; ++i) {
        args.append(QString::fromUtf8(argv[i]));
    }
    parser.process(args);

    const QStringList posArgs = parser.positionalArguments();
    if (posArgs.isEmpty()) {
        parser.showHelp(0);
        return 0;
    }

    const QString cmd = posArgs.first();

    if (cmd == QStringLiteral("reload")) {
        bool ok = Hyprland::HyprlandSocket::instance()->reload();
        std::cout << (ok ? "Hyprland reloaded successfully.\n" : "Failed to reload Hyprland.\n");
        return ok ? 0 : 1;
    }

    if (cmd == QStringLiteral("get")) {
        if (posArgs.size() < 2) {
            std::cerr << "Usage: flightdeck get <key>\n";
            return 1;
        }
        const QString key = posArgs.at(1);
        const QVariant val = Caelestia::CaelestiaVars::instance()->get(key);
        std::cout << val.toString().toStdString() << "\n";
        return 0;
    }

    if (cmd == QStringLiteral("set")) {
        if (posArgs.size() < 3) {
            std::cerr << "Usage: flightdeck set <key> <value>\n";
            return 1;
        }
        const QString key = posArgs.at(1);
        const QString valStr = posArgs.at(2);
        QVariant val;
        if (valStr == QStringLiteral("true")) val = true;
        else if (valStr == QStringLiteral("false")) val = false;
        else {
            bool ok = false;
            double d = valStr.toDouble(&ok);
            if (ok) val = d;
            else val = valStr;
        }

        Caelestia::CaelestiaVars::instance()->set(key, val);
        bool ok = Caelestia::CaelestiaVars::instance()->save();
        if (ok) {
            std::cout << "Saved " << key.toStdString() << " = " << valStr.toStdString() << "\n";
            Hyprland::HyprlandSocket::instance()->keyword(key, val);
        } else {
            std::cerr << "Failed to save variable.\n";
        }
        return ok ? 0 : 1;
    }

    if (cmd == QStringLiteral("profile")) {
        if (posArgs.size() < 2) {
            std::cerr << "Usage: flightdeck profile <list|create|restore|delete> [name]\n";
            return 1;
        }
        const QString sub = posArgs.at(1);
        if (sub == QStringLiteral("list")) {
            for (const QString& p : Managers::ProfileManager::instance()->profiles()) {
                std::cout << "  - " << p.toStdString() << "\n";
            }
            return 0;
        }
        if (posArgs.size() < 3) {
            std::cerr << "Please specify a profile name.\n";
            return 1;
        }
        const QString name = posArgs.at(2);
        if (sub == QStringLiteral("create")) {
            return Managers::ProfileManager::instance()->createProfile(name) ? 0 : 1;
        }
        if (sub == QStringLiteral("restore")) {
            return Managers::ProfileManager::instance()->restoreProfile(name) ? 0 : 1;
        }
        if (sub == QStringLiteral("delete")) {
            return Managers::ProfileManager::instance()->deleteProfile(name) ? 0 : 1;
        }
    }

    std::cerr << "Unknown command: " << cmd.toStdString() << "\n";
    return 1;
}

} // namespace FlightDeck::Cli
