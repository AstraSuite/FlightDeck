#include "clihandler.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../caelestia/flightdeckwriter.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../hyprland/hyprlandschema.hpp"
#include "../managers/profilemanager.hpp"

#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QJsonObject>
#include <QJsonDocument>
#include <QSet>
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
            std::cerr << "Usage: flightdeck get <key> [--val-only]\n";
            return 1;
        }
        const QString searchKey = posArgs.at(1);
        const bool valOnly = (posArgs.contains(QStringLiteral("--val-only")) || posArgs.contains(QStringLiteral("-v")));

        auto schema = Hyprland::HyprlandSchema::instance();
        QString canonicalKey = schema ? schema->toHyprKey(searchKey) : searchKey;
        if (canonicalKey.isEmpty()) canonicalKey = searchKey;
        QString shortKey = schema ? schema->toShortKey(canonicalKey) : QString();

        QString leafKey = canonicalKey;
        if (leafKey.contains(QLatin1Char(':'))) {
            leafKey = leafKey.section(QLatin1Char(':'), -1);
        } else if (leafKey.contains(QLatin1Char('.'))) {
            leafKey = leafKey.section(QLatin1Char('.'), -1);
        }

        // Get effective value
        QVariant effectiveVal = Caelestia::CaelestiaVars::instance()->get(searchKey);
        if (effectiveVal.isNull() || !effectiveVal.isValid() || effectiveVal.toString().isEmpty()) {
            effectiveVal = Caelestia::CaelestiaVars::instance()->get(canonicalKey);
        }
        if (effectiveVal.isNull() || !effectiveVal.isValid() || effectiveVal.toString().isEmpty()) {
            effectiveVal = Caelestia::FlightDeckWriter::instance()->getHyprOption(canonicalKey);
        }
        if (effectiveVal.isNull() || !effectiveVal.isValid() || effectiveVal.toString().isEmpty()) {
            if (schema && schema->hasOption(canonicalKey)) {
                effectiveVal = schema->getDefault(canonicalKey);
            }
        }

        if (valOnly) {
            std::cout << effectiveVal.toString().toStdString() << "\n";
            return 0;
        }

        // Collect all candidate config files
        QString home = QDir::homePath();
        QStringList candidateFiles = {
            home + QStringLiteral("/.config/caelestia/astra-flightdeck.lua"),
            home + QStringLiteral("/.config/hypr/variables.lua"),
            home + QStringLiteral("/.config/caelestia/hypr-user.lua"),
            home + QStringLiteral("/.config/caelestia/hypr-vars.lua"),
            home + QStringLiteral("/.config/hypr/hyprland.lua")
        };

        QDir hyprDir(home + QStringLiteral("/.config/hypr"));
        for (const QFileInfo& fi : hyprDir.entryInfoList(QStringList() << "*.lua" << "*.conf", QDir::Files | QDir::NoDotAndDotDot)) {
            if (!candidateFiles.contains(fi.absoluteFilePath())) candidateFiles.append(fi.absoluteFilePath());
        }
        QDir hyprSubDir(home + QStringLiteral("/.config/hypr/hyprland"));
        for (const QFileInfo& fi : hyprSubDir.entryInfoList(QStringList() << "*.lua" << "*.conf", QDir::Files | QDir::NoDotAndDotDot)) {
            if (!candidateFiles.contains(fi.absoluteFilePath())) candidateFiles.append(fi.absoluteFilePath());
        }

        struct DefMatch {
            QString filePath;
            int line;
            QString content;
        };
        QList<DefMatch> matches;

        QSet<QString> exactTokens = { searchKey, canonicalKey };
        if (!shortKey.isEmpty()) exactTokens.insert(shortKey);

        for (const QString& fPath : candidateFiles) {
            QFile f(fPath);
            if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) continue;
            QTextStream stream(&f);
            int lineNum = 0;
            QStringList tableStack;
            while (!stream.atEnd()) {
                lineNum++;
                QString line = stream.readLine();
                QString trimmed = line.trimmed();
                if (trimmed.startsWith(QStringLiteral("--")) || trimmed.startsWith(QStringLiteral("#"))) {
                    continue;
                }

                QRegularExpression tableOpenRe(QStringLiteral(R"(([a-zA-Z0-9_\-]+)\s*=\s*\{)"));
                auto openMatch = tableOpenRe.match(trimmed);
                if (openMatch.hasMatch()) {
                    QString tbl = openMatch.captured(1);
                    tbl.replace(QLatin1Char('-'), QLatin1Char('_'));
                    tableStack.append(tbl);
                }

                bool matchFound = false;
                for (const QString& tok : exactTokens) {
                    QRegularExpression re(QStringLiteral(R"((?:^|[^a-zA-Z0-9_\-\.])(?:vars\.)?(?:\[[\'\"])?%1(?:[\'\"]\])?\s*=)").arg(QRegularExpression::escape(tok)));
                    if (re.match(trimmed).hasMatch()) {
                        matchFound = true;
                        break;
                    }
                }

                if (!matchFound && !leafKey.isEmpty()) {
                    QRegularExpression leafRe(QStringLiteral(R"(^(?:vars\.)?(?:\[[\'\"])?%1(?:[\'\"]\])?\s*=)").arg(QRegularExpression::escape(leafKey)));
                    if (leafRe.match(trimmed).hasMatch()) {
                        if (canonicalKey.contains(QLatin1Char(':'))) {
                            QStringList keyParts = canonicalKey.split(QLatin1Char(':'));
                            keyParts.removeLast();
                            for (QString& kp : keyParts) kp.replace(QLatin1Char('-'), QLatin1Char('_'));

                            bool stackMatches = true;
                            for (const QString& kp : keyParts) {
                                if (!tableStack.contains(kp) && !fPath.contains(kp)) {
                                    stackMatches = false;
                                    break;
                                }
                            }
                            if (stackMatches) {
                                matchFound = true;
                            }
                        } else {
                            matchFound = true;
                        }
                    }
                }

                if (matchFound) {
                    matches.append({ fPath, lineNum, trimmed });
                }

                if (trimmed.contains(QLatin1Char('}'))) {
                    if (!tableStack.isEmpty()) {
                        tableStack.removeLast();
                    }
                }
            }
            f.close();
        }

        // Query Hyprland runtime state
        QJsonObject hyprOpt;
        auto socket = Hyprland::HyprlandSocket::instance();
        if (socket && socket->isOnline()) {
            QString hyprQueryKey = canonicalKey;
            if (schema && !schema->hasOption(hyprQueryKey)) {
                QVariantMap caelOpt = schema->getOption(searchKey);
                if (caelOpt.contains(QStringLiteral("hyprKeyword"))) {
                    hyprQueryKey = caelOpt.value(QStringLiteral("hyprKeyword")).toString();
                } else {
                    hyprQueryKey.clear();
                }
            }

            if (!hyprQueryKey.isEmpty()) {
                QJsonDocument doc = socket->queryJson(QStringLiteral("getoption %1").arg(hyprQueryKey));
                if (doc.isObject()) {
                    hyprOpt = doc.object();
                }
            }
        }

        // Print header & value
        std::cout << "\033[1;36mSetting:\033[0m " << canonicalKey.toStdString();
        if (canonicalKey != searchKey) {
            std::cout << " (alias: " << searchKey.toStdString() << ")";
        }
        std::cout << "\n";

        std::cout << "\033[1;32mValue:\033[0m " << effectiveVal.toString().toStdString() << "\n\n";

        // Print definitions
        std::cout << "\033[1;33mDefined in configuration:\033[0m\n";
        if (matches.isEmpty()) {
            std::cout << "  (No file definitions found - using schema default)\n";
        } else {
            for (const auto& m : matches) {
                std::cout << "  • \033[1;34m" << m.filePath.toStdString() << ":" << m.line << "\033[0m\n";
                std::cout << "    " << m.content.toStdString() << "\n";
            }
        }
        std::cout << "\n";

        // Print compositor runtime state
        if (!hyprOpt.isEmpty()) {
            std::cout << "\033[1;35mCompositor Runtime State (Hyprland IPC):\033[0m\n";
            std::cout << "  • Option: " << hyprOpt.value(QStringLiteral("option")).toString().toStdString() << "\n";
            if (hyprOpt.contains(QStringLiteral("str"))) {
                std::cout << "  • Value: " << hyprOpt.value(QStringLiteral("str")).toString().toStdString() << "\n";
            } else if (hyprOpt.contains(QStringLiteral("int"))) {
                std::cout << "  • Value: " << hyprOpt.value(QStringLiteral("int")).toInteger() << "\n";
            } else if (hyprOpt.contains(QStringLiteral("float"))) {
                std::cout << "  • Value: " << hyprOpt.value(QStringLiteral("float")).toDouble() << "\n";
            }
            std::cout << "  • Custom Set: " << (hyprOpt.value(QStringLiteral("set")).toBool() ? "true" : "false") << "\n";
        }

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
