#include "clihandler.hpp"
#include "../caelestia/caelestiavars.hpp"
#include "../caelestia/flightdeckwriter.hpp"
#include "../hyprland/hyprlandsocket.hpp"
#include "../hyprland/hyprlandschema.hpp"
#include "../managers/profilemanager.hpp"
#include "../managers/diagnosticsmanager.hpp"
#include "../managers/keybindvalidator.hpp"
#include "../managers/hyprpmmanager.hpp"

#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QJsonObject>
#include <QJsonDocument>
#include <QSet>
#include <iostream>
#include <unistd.h>

#ifndef ASTRA_VERSION
#define ASTRA_VERSION "1.0.0"
#endif

namespace FlightDeck::Cli {

int CliHandler::run(int argc, char* argv[]) {
    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("FlightDeck - Hyprland Configuration Suite for Astra"));
    parser.addHelpOption();
    parser.addVersionOption();

    parser.addPositionalArgument(QStringLiteral("command"), QStringLiteral("Command to execute (get, set, reload, profile, doctor, bind, plugin)"));
    parser.addPositionalArgument(QStringLiteral("args"), QStringLiteral("Arguments for command"), QStringLiteral("[args...]"));

    parser.addOption(QCommandLineOption(QStringList() << QStringLiteral("c") << QStringLiteral("conflicts"), QStringLiteral("Show conflicting bindings only")));
    parser.addOption(QCommandLineOption(QStringList() << QStringLiteral("val-only"), QStringLiteral("Output raw value only without formatting")));

    QStringList args;
    for (int i = 0; i < argc; ++i) {
        args.append(QString::fromUtf8(argv[i]));
    }

    if (args.size() > 1 && args.at(1) == QStringLiteral("plugin") && (args.contains(QStringLiteral("--help")) || args.contains(QStringLiteral("-h")))) {
        std::cout << "\033[1;36mFlightDeck Plugin Manager CLI\033[0m\n\n"
                  << "Usage:\n"
                  << "  flightdeck plugin [list]                    List installed plugins & available catalog\n"
                  << "  flightdeck plugin install <url> [revision]  Install a plugin repository\n"
                  << "  flightdeck plugin enable <name>             Enable an installed plugin\n"
                  << "  flightdeck plugin disable <name>            Disable an installed plugin\n"
                  << "  flightdeck plugin remove <name>             Uninstall a plugin\n"
                  << "  flightdeck plugin update                    Compile and update all installed plugins\n"
                  << "  flightdeck plugin reload                    Reload active plugins in Hyprland\n"
                  << "  flightdeck plugin repair                    Fix root permission errors in ~/.local/share/hyprpm\n\n";
        return 0;
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

    if (cmd == QStringLiteral("reset")) {
        if (posArgs.size() < 2) {
            std::cerr << "Usage: flightdeck reset <key>\n";
            return 1;
        }
        const QString key = posArgs.at(1);
        Caelestia::CaelestiaVars::instance()->resetToDefault(key);
        std::cout << "Reset " << key.toStdString() << " to default.\n";
        return 0;
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

    if (cmd == QStringLiteral("doctor")) {
        auto diag = Managers::DiagnosticsManager::instance();
        diag->runAllChecks();

        const QVariantList results = diag->results();
        std::cout << "\033[1;36m=== FlightDeck Compositor Doctor ===\033[0m\n\n";

        for (const auto& itemVal : results) {
            const QVariantMap item = itemVal.toMap();
            const QString category = item.value(QStringLiteral("category")).toString();
            const QString title = item.value(QStringLiteral("title")).toString();
            const QString status = item.value(QStringLiteral("status")).toString();
            const QString message = item.value(QStringLiteral("message")).toString();
            const QString detail = item.value(QStringLiteral("detail")).toString();
            const QString fix = item.value(QStringLiteral("suggestedFix")).toString();

            if (status == QStringLiteral("pass")) {
                std::cout << "  \033[1;32m[PASS]\033[0m " << category.toStdString() << " :: " << title.toStdString() << "\n";
                std::cout << "         " << message.toStdString() << "\n";
            } else if (status == QStringLiteral("warning")) {
                std::cout << "  \033[1;33m[WARN]\033[0m " << category.toStdString() << " :: " << title.toStdString() << "\n";
                std::cout << "         " << message.toStdString() << "\n";
                if (!fix.isEmpty()) {
                    std::cout << "         \033[0;33m-> Suggested Fix: " << fix.toStdString() << "\033[0m\n";
                }
            } else if (status == QStringLiteral("error")) {
                std::cout << "  \033[1;31m[FAIL]\033[0m " << category.toStdString() << " :: " << title.toStdString() << "\n";
                std::cout << "         " << message.toStdString() << "\n";
                if (!fix.isEmpty()) {
                    std::cout << "         \033[0;31m-> Suggested Fix: " << fix.toStdString() << "\033[0m\n";
                }
            }
            if (!detail.isEmpty()) {
                std::cout << "         \033[0;90mDetail: " << detail.toStdString() << "\033[0m\n";
            }
            std::cout << "\n";
        }

        std::cout << "\033[1mSummary:\033[0m "
                  << "\033[1;32m" << diag->passCount() << " Passed\033[0m, "
                  << "\033[1;33m" << diag->warningCount() << " Warnings\033[0m, "
                  << "\033[1;31m" << diag->errorCount() << " Errors\033[0m\n";

        return diag->errorCount() > 0 ? 1 : 0;
    }

    if (cmd == QStringLiteral("bind")) {
        const bool showConflictsOnly = (parser.isSet(QStringLiteral("conflicts")) || parser.isSet(QStringLiteral("c")) ||
                                        posArgs.contains(QStringLiteral("conflicts")) || posArgs.contains(QStringLiteral("--conflicts")));
        auto kv = Managers::KeybindValidator::instance();
        kv->refresh();

        if (showConflictsOnly) {
            const QVariantList trueConflicts = kv->trueConflicts();
            const QVariantList overrides = kv->overrides();

            if (trueConflicts.isEmpty()) {
                std::cout << "\033[1;32mNo unresolvable keybinding collisions detected.\033[0m\n";
                if (!overrides.isEmpty()) {
                    std::cout << "\033[0;36mActive Custom Overrides (" << overrides.size() << "):\033[0m\n";
                    for (const auto& oVal : overrides) {
                        const QVariantMap o = oVal.toMap();
                        const QVariantMap c = o.value(QStringLiteral("customOverride")).toMap();
                        const QVariantMap s = o.value(QStringLiteral("systemShadowed")).toMap();
                        std::cout << "  \033[1m" << o.value(QStringLiteral("chord")).toString().toStdString() << "\033[0m: "
                                  << c.value(QStringLiteral("label")).toString().toStdString()
                                  << " \033[0;90m(Overrides default: " << s.value(QStringLiteral("label")).toString().toStdString() << ")\033[0m\n";
                    }
                }
                return 0;
            }

            std::cout << "\033[1;31m=== Keybinding Collisions (" << trueConflicts.size() << ") ===\033[0m\n\n";
            for (const auto& cVal : trueConflicts) {
                const QVariantMap c = cVal.toMap();
                std::cout << "  \033[1;31mChord:\033[0m " << c.value(QStringLiteral("chord")).toString().toStdString() << "\n";
                const QVariantList sources = c.value(QStringLiteral("sources")).toList();
                for (const auto& sVal : sources) {
                    const QVariantMap s = sVal.toMap();
                    std::cout << "    - [" << s.value(QStringLiteral("type")).toString().toStdString() << "] "
                              << s.value(QStringLiteral("label")).toString().toStdString()
                              << " (" << s.value(QStringLiteral("rawVal")).toString().toStdString() << ")\n";
                }
                std::cout << "\n";
            }
            return 1;
        }

        // List all bindings
        std::cout << "\033[1;36m=== Active Keybindings ===\033[0m\n\n";
        auto vars = Caelestia::CaelestiaVars::instance();
        const QVariantList sections = vars->keybindSections();
        for (const auto& sVal : sections) {
            const QVariantMap sec = sVal.toMap();
            std::cout << "\033[1m[" << sec.value(QStringLiteral("label")).toString().toStdString() << "]\033[0m\n";
            const QVariantList options = sec.value(QStringLiteral("options")).toList();
            for (const auto& optVal : options) {
                const QVariantMap opt = optVal.toMap();
                const QString keyName = opt.value(QStringLiteral("key")).toString();
                const QString optLabel = opt.value(QStringLiteral("label")).toString();
                QVariant val = vars->get(keyName);
                if (val.isNull() || !val.isValid() || val.toString().isEmpty()) {
                    val = vars->getDefault(keyName, QVariant());
                }
                QString chord = kv->normalizeChord(val);
                bool isOvr = kv->isOverridden(chord);
                std::cout << "  " << optLabel.toStdString() << ": \033[1;32m" << val.toString().toStdString() << "\033[0m";
                if (isOvr) {
                    std::cout << " \033[0;33m[Overridden by custom shortcut]\033[0m";
                }
                std::cout << "\n";
            }
            std::cout << "\n";
        }
        return 0;
    }

    if (cmd == QStringLiteral("plugin")) {
        auto pm = Managers::HyprpmManager::instance();
        pm->refresh();

        auto runInteractiveHyprpm = [](const QStringList& args) -> int {
            QProcess proc;
            proc.setProcessChannelMode(QProcess::ForwardedChannels);
            proc.setInputChannelMode(QProcess::ForwardedInputChannel);
            proc.start(QStringLiteral("hyprpm"), args);
            proc.waitForFinished(-1);
            return proc.exitCode();
        };

        auto findPlugin = [&](const QString& query) -> QVariantMap {
            const QString qLower = query.trimmed().toLower();
            const QString qNoHyphen = QString(qLower).remove(QLatin1Char('-')).remove(QLatin1Char('_'));
            for (const auto& pVal : pm->allPlugins()) {
                const QVariantMap p = pVal.toMap();
                const QString name = p.value(QStringLiteral("name")).toString().toLower();
                const QString id = p.value(QStringLiteral("id")).toString().toLower();
                const QString nameNoHyphen = QString(name).remove(QLatin1Char('-')).remove(QLatin1Char('_'));
                if (name == qLower || id == qLower || nameNoHyphen == qNoHyphen) {
                    return p;
                }
            }
            return QVariantMap();
        };

        auto printPluginList = [&]() {
            std::cout << "\033[1;36m=== FlightDeck Plugin Store ===\033[0m\n\n";
            std::cout << "\033[1;32mInstalled Plugins (" << pm->installedCount() << "):\033[0m\n";
            if (pm->installedCount() == 0) {
                std::cout << "  (No plugins currently installed)\n";
            } else {
                for (const auto& pVal : pm->installedPlugins()) {
                    const QVariantMap p = pVal.toMap();
                    bool isEn = p.value(QStringLiteral("isEnabled")).toBool();
                    std::cout << "  • \033[1m" << p.value(QStringLiteral("name")).toString().toStdString() << "\033[0m: "
                              << (isEn ? "\033[1;32mEnabled\033[0m" : "\033[1;33mDisabled\033[0m")
                              << " - " << p.value(QStringLiteral("description")).toString().toStdString() << "\n";
                }
            }
            std::cout << "\n\033[1;34mAvailable in Store Catalog (" << pm->availableCount() << "):\033[0m\n";
            for (const auto& pVal : pm->availablePlugins()) {
                const QVariantMap p = pVal.toMap();
                std::cout << "  • \033[1m" << p.value(QStringLiteral("name")).toString().toStdString() << "\033[0m ("
                          << p.value(QStringLiteral("author")).toString().toStdString() << "): "
                          << p.value(QStringLiteral("description")).toString().toStdString() << "\n";
            }
            std::cout << "\n\033[2mTip: Run 'flightdeck plugin install <name>' or 'flightdeck plugin store' for interactive TUI.\033[0m\n";
        };

        auto runStoreTui = [&]() -> int {
            while (true) {
                pm->refresh();
                const QVariantList all = pm->allPlugins();

                std::cout << "\n\033[1;36m==============================================\033[0m\n";
                std::cout << "\033[1;36m           FlightDeck Plugin Store            \033[0m\n";
                std::cout << "\033[1;36m==============================================\033[0m\n\n";

                for (int i = 0; i < all.size(); ++i) {
                    const QVariantMap p = all.at(i).toMap();
                    const QString name = p.value(QStringLiteral("name")).toString();
                    const bool isInst = p.value(QStringLiteral("isInstalled")).toBool();
                    const bool isEn = p.value(QStringLiteral("isEnabled")).toBool();

                    std::string statusBadge;
                    if (!isInst) {
                        statusBadge = "\033[0;34m[Available]\033[0m";
                    } else if (isEn) {
                        statusBadge = "\033[1;32m[Enabled]\033[0m  ";
                    } else {
                        statusBadge = "\033[1;33m[Disabled]\033[0m ";
                    }

                    printf("  \033[1;37m[%2d]\033[0m %s \033[1m%-24s\033[0m %s\n",
                           i + 1,
                           statusBadge.c_str(),
                           name.toStdString().c_str(),
                           p.value(QStringLiteral("description")).toString().left(48).toStdString().c_str());
                }

                std::cout << "\n\033[1mOptions:\033[0m Enter \033[1m[1-" << all.size() << "]\033[0m or plugin name to manage\n";
                std::cout << "         \033[1m[u]\033[0mpdate all | \033[1m[r]\033[0meload | \033[1m[s]\033[0mearch | \033[1m[q]\033[0muit\n";
                std::cout << "\033[1;36mSelect > \033[0m";
                std::cout.flush();

                std::string input;
                if (!std::getline(std::cin, input)) break;
                QString qInput = QString::fromStdString(input).trimmed();
                if (qInput.isEmpty()) continue;

                if (qInput == QStringLiteral("q") || qInput == QStringLiteral("quit") || qInput == QStringLiteral("exit")) {
                    break;
                }

                if (qInput == QStringLiteral("u") || qInput == QStringLiteral("update")) {
                    std::cout << "\n\033[1mUpdating all Hyprland plugins...\033[0m\n";
                    runInteractiveHyprpm({ QStringLiteral("update") });
                    continue;
                }

                if (qInput == QStringLiteral("r") || qInput == QStringLiteral("reload")) {
                    std::cout << "\n\033[1mReloading plugins in Hyprland...\033[0m\n";
                    runInteractiveHyprpm({ QStringLiteral("reload"), QStringLiteral("-n") });
                    continue;
                }

                if (qInput == QStringLiteral("s") || qInput == QStringLiteral("search")) {
                    std::cout << "\nEnter search keyword: ";
                    std::cout.flush();
                    std::string sQuery;
                    if (std::getline(std::cin, sQuery)) {
                        QString sq = QString::fromStdString(sQuery).trimmed().toLower();
                        std::cout << "\n\033[1;36mMatching Plugins:\033[0m\n";
                        for (int i = 0; i < all.size(); ++i) {
                            const QVariantMap p = all.at(i).toMap();
                            QString pName = p.value(QStringLiteral("name")).toString();
                            QString pDesc = p.value(QStringLiteral("description")).toString();
                            if (pName.toLower().contains(sq) || pDesc.toLower().contains(sq)) {
                                std::cout << "  • [" << (i + 1) << "] " << pName.toStdString() << " - " << pDesc.toStdString() << "\n";
                            }
                        }
                    }
                    std::cout << "\nPress Enter to return to store menu...";
                    std::string dummy;
                    std::getline(std::cin, dummy);
                    continue;
                }

                // Resolve selected plugin by number or name
                QVariantMap selected;
                bool isNum = false;
                int idx = qInput.toInt(&isNum);
                if (isNum && idx >= 1 && idx <= all.size()) {
                    selected = all.at(idx - 1).toMap();
                } else {
                    selected = findPlugin(qInput);
                }

                if (selected.isEmpty()) {
                    std::cout << "\033[1;31mPlugin \"" << qInput.toStdString() << "\" not found.\033[0m\n";
                    continue;
                }

                // Show detailed card and actions
                const QString name = selected.value(QStringLiteral("name")).toString();
                const QString label = selected.value(QStringLiteral("label")).toString();
                const QString repo = selected.value(QStringLiteral("repository")).toString();
                const QString desc = selected.value(QStringLiteral("description")).toString();
                const QString author = selected.value(QStringLiteral("author")).toString();
                const bool isInstalled = selected.value(QStringLiteral("isInstalled")).toBool();
                const bool isEnabled = selected.value(QStringLiteral("isEnabled")).toBool();

                std::cout << "\n\033[1;35m--------------------------------------------------\033[0m\n";
                std::cout << "  \033[1m" << (label.isEmpty() ? name.toStdString() : label.toStdString()) << "\033[0m (" << name.toStdString() << ")\n";
                std::cout << "  Status:      " << (isInstalled ? (isEnabled ? "\033[1;32mInstalled (Enabled)\033[0m" : "\033[1;33mInstalled (Disabled)\033[0m") : "\033[1;34mAvailable in Store (Not installed)\033[0m") << "\n";
                if (!author.isEmpty()) std::cout << "  Author:      " << author.toStdString() << "\n";
                if (!repo.isEmpty())   std::cout << "  Repository:  " << repo.toStdString() << "\n";
                std::cout << "  Description: " << desc.toStdString() << "\n";
                std::cout << "\033[1;35m--------------------------------------------------\033[0m\n";

                std::cout << "Actions:\n";
                if (!isInstalled) {
                    std::cout << "  \033[1m[i]\033[0m Install and enable\n";
                } else {
                    if (isEnabled) {
                        std::cout << "  \033[1m[t]\033[0m Disable plugin\n";
                    } else {
                        std::cout << "  \033[1m[t]\033[0m Enable plugin\n";
                    }
                    std::cout << "  \033[1m[u]\033[0m Uninstall / remove\n";
                }
                std::cout << "  \033[1m[b]\033[0m Back to store\n";
                std::cout << "\033[1;36mAction > \033[0m";
                std::cout.flush();

                std::string action;
                if (!std::getline(std::cin, action)) break;
                QString qAction = QString::fromStdString(action).trimmed().toLower();

                if (qAction == QStringLiteral("i") && !isInstalled) {
                    std::cout << "\n\033[1mAdding repository " << repo.toStdString() << "...\033[0m\n";
                    int r = runInteractiveHyprpm({ QStringLiteral("add"), repo });
                    if (r == 0) {
                        std::cout << "\033[1mEnabling " << name.toStdString() << "...\033[0m\n";
                        runInteractiveHyprpm({ QStringLiteral("enable"), name, QStringLiteral("-n") });
                        std::cout << "\033[1;32m✔ " << name.toStdString() << " installed and enabled successfully!\033[0m\n";
                    }
                } else if (qAction == QStringLiteral("t") && isInstalled) {
                    if (isEnabled) {
                        std::cout << "\n\033[1mDisabling " << name.toStdString() << "...\033[0m\n";
                        runInteractiveHyprpm({ QStringLiteral("disable"), name, QStringLiteral("-n") });
                    } else {
                        std::cout << "\n\033[1mEnabling " << name.toStdString() << "...\033[0m\n";
                        runInteractiveHyprpm({ QStringLiteral("enable"), name, QStringLiteral("-n") });
                    }
                } else if (qAction == QStringLiteral("u") && isInstalled) {
                    std::cout << "\n\033[1mUninstalling " << name.toStdString() << "...\033[0m\n";
                    runInteractiveHyprpm({ QStringLiteral("remove"), name });
                }
            }
            return 0;
        };

        if (posArgs.size() < 2) {
            // If in an interactive terminal, open the full interactive store TUI
            if (isatty(STDIN_FILENO)) {
                return runStoreTui();
            } else {
                printPluginList();
                return 0;
            }
        }

        const QString sub = posArgs.at(1);
        if (sub == QStringLiteral("store") || sub == QStringLiteral("tui") || sub == QStringLiteral("ui") || sub == QStringLiteral("browse")) {
            return runStoreTui();
        }

        if (sub == QStringLiteral("list") || sub == QStringLiteral("ls")) {
            printPluginList();
            return 0;
        }

        if (sub == QStringLiteral("help") || sub == QStringLiteral("--help") || sub == QStringLiteral("-h")) {
            std::cout << "\033[1;36mFlightDeck Plugin Store & Manager CLI\033[0m\n\n"
                      << "Usage:\n"
                      << "  flightdeck plugin                           Open interactive Plugin Store TUI\n"
                      << "  flightdeck plugin list                      List installed plugins & store catalog\n"
                      << "  flightdeck plugin search <query>            Search plugins by name, keyword, or author\n"
                      << "  flightdeck plugin install <name | url>      Install & enable plugin (by store name or git url)\n"
                      << "  flightdeck plugin toggle <name>             Toggle plugin enabled/disabled state\n"
                      << "  flightdeck plugin enable <name>             Enable an installed plugin\n"
                      << "  flightdeck plugin disable <name>            Disable an installed plugin\n"
                      << "  flightdeck plugin remove <name>             Uninstall a plugin\n"
                      << "  flightdeck plugin update                    Compile and update all installed plugins\n"
                      << "  flightdeck plugin reload                    Reload active plugins in Hyprland\n"
                      << "  flightdeck plugin repair                    Fix root permission errors in ~/.local/share/hyprpm\n\n";
            return 0;
        }

        if (sub == QStringLiteral("search") || sub == QStringLiteral("find")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin search <keyword>\n";
                return 1;
            }
            QString query = posArgs.at(2).toLower();
            std::cout << "\033[1;36mSearch results for \"" << query.toStdString() << "\":\033[0m\n\n";
            int matches = 0;
            for (const auto& pVal : pm->allPlugins()) {
                const QVariantMap p = pVal.toMap();
                const QString name = p.value(QStringLiteral("name")).toString();
                const QString label = p.value(QStringLiteral("label")).toString();
                const QString desc = p.value(QStringLiteral("description")).toString();
                const QString author = p.value(QStringLiteral("author")).toString();
                if (name.toLower().contains(query) || label.toLower().contains(query) ||
                    desc.toLower().contains(query) || author.toLower().contains(query)) {
                    matches++;
                    bool isInst = p.value(QStringLiteral("isInstalled")).toBool();
                    bool isEn = p.value(QStringLiteral("isEnabled")).toBool();
                    std::string statusTag = !isInst ? "\033[1;34m[Store: Available]\033[0m" : (isEn ? "\033[1;32m[Installed: Enabled]\033[0m" : "\033[1;33m[Installed: Disabled]\033[0m");
                    std::cout << "  • \033[1m" << name.toStdString() << "\033[0m " << statusTag << "\n"
                              << "    " << desc.toStdString() << "\n\n";
                }
            }
            if (matches == 0) {
                std::cout << "  No plugins found matching \"" << query.toStdString() << "\".\n";
            }
            return 0;
        }

        if (sub == QStringLiteral("install") || sub == QStringLiteral("add")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin install <plugin_name | repository_url> [git_revision]\n";
                return 1;
            }
            QString target = posArgs.at(2);
            QString rev = posArgs.size() > 3 ? posArgs.at(3) : QString();

            QString repoUrl = target;
            QString pluginName = target;

            // Resolve target against store catalog
            QVariantMap catalogPlugin = findPlugin(target);
            if (!catalogPlugin.isEmpty()) {
                repoUrl = catalogPlugin.value(QStringLiteral("repository")).toString();
                pluginName = catalogPlugin.value(QStringLiteral("name")).toString();
                std::cout << "\033[1;36mFound \"" << pluginName.toStdString() << "\" in store catalog:\033[0m " << repoUrl.toStdString() << "\n";
            } else if (!target.startsWith(QStringLiteral("http")) && !target.contains(QLatin1Char('/'))) {
                std::cerr << "\033[1;31mPlugin \"" << target.toStdString() << "\" not found in store catalog.\033[0m\n"
                          << "Run 'flightdeck plugin search <keyword>' or provide a full git repository URL.\n";
                return 1;
            }

            std::cout << "\033[1mInstalling plugin repository:\033[0m " << repoUrl.toStdString() << "\n";
            QStringList addArgs = { QStringLiteral("add"), repoUrl };
            if (!rev.isEmpty()) addArgs.append(rev);
            int res = runInteractiveHyprpm(addArgs);
            if (res != 0) {
                std::cerr << "\033[1;31m✖ Failed to add plugin repository (exit code " << res << ").\033[0m\n";
                return res;
            }

            std::cout << "\n\033[1mEnabling plugin:\033[0m " << pluginName.toStdString() << "\n";
            res = runInteractiveHyprpm({ QStringLiteral("enable"), pluginName, QStringLiteral("-n") });
            if (res == 0) {
                std::cout << "\n\033[1;32m✔ Plugin \"" << pluginName.toStdString() << "\" installed and enabled successfully!\033[0m\n";
            }
            return res;
        }

        if (sub == QStringLiteral("toggle")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin toggle <plugin_name>\n";
                return 1;
            }
            QString target = posArgs.at(2);
            QVariantMap plugin = findPlugin(target);
            QString name = !plugin.isEmpty() ? plugin.value(QStringLiteral("name")).toString() : target;
            bool isInstalled = !plugin.isEmpty() && plugin.value(QStringLiteral("isInstalled")).toBool();
            bool isEnabled = !plugin.isEmpty() && plugin.value(QStringLiteral("isEnabled")).toBool();

            if (!isInstalled && !plugin.isEmpty()) {
                std::cout << "Plugin \"" << name.toStdString() << "\" is not installed yet.\n";
                std::cout << "Would you like to install it from the store? [Y/n]: ";
                std::cout.flush();
                std::string reply;
                std::getline(std::cin, reply);
                if (reply.empty() || reply[0] == 'y' || reply[0] == 'Y') {
                    QString repoUrl = plugin.value(QStringLiteral("repository")).toString();
                    int res = runInteractiveHyprpm({ QStringLiteral("add"), repoUrl });
                    if (res == 0) {
                        runInteractiveHyprpm({ QStringLiteral("enable"), name, QStringLiteral("-n") });
                        std::cout << "\033[1;32m✔ Successfully installed and enabled " << name.toStdString() << "!\033[0m\n";
                    }
                    return res;
                }
                return 0;
            }

            if (isEnabled) {
                std::cout << "Disabling " << name.toStdString() << "...\n";
                int res = runInteractiveHyprpm({ QStringLiteral("disable"), name, QStringLiteral("-n") });
                if (res == 0) std::cout << "\033[1;33m✔ " << name.toStdString() << " is now disabled.\033[0m\n";
                return res;
            } else {
                std::cout << "Enabling " << name.toStdString() << "...\n";
                int res = runInteractiveHyprpm({ QStringLiteral("enable"), name, QStringLiteral("-n") });
                if (res == 0) std::cout << "\033[1;32m✔ " << name.toStdString() << " is now enabled.\033[0m\n";
                return res;
            }
        }

        if (sub == QStringLiteral("enable")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin enable <plugin_name>\n";
                return 1;
            }
            QString target = posArgs.at(2);
            QVariantMap plugin = findPlugin(target);
            QString name = !plugin.isEmpty() ? plugin.value(QStringLiteral("name")).toString() : target;
            return runInteractiveHyprpm({ QStringLiteral("enable"), name, QStringLiteral("-n") });
        }

        if (sub == QStringLiteral("disable")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin disable <plugin_name>\n";
                return 1;
            }
            QString target = posArgs.at(2);
            QVariantMap plugin = findPlugin(target);
            QString name = !plugin.isEmpty() ? plugin.value(QStringLiteral("name")).toString() : target;
            return runInteractiveHyprpm({ QStringLiteral("disable"), name, QStringLiteral("-n") });
        }

        if (sub == QStringLiteral("remove") || sub == QStringLiteral("uninstall")) {
            if (posArgs.size() < 3) {
                std::cerr << "Usage: flightdeck plugin remove <plugin_name>\n";
                return 1;
            }
            QString target = posArgs.at(2);
            QVariantMap plugin = findPlugin(target);
            QString name = !plugin.isEmpty() ? plugin.value(QStringLiteral("name")).toString() : target;
            std::cout << "Removing plugin " << name.toStdString() << "...\n";
            return runInteractiveHyprpm({ QStringLiteral("remove"), name });
        }

        if (sub == QStringLiteral("update")) {
            return runInteractiveHyprpm({ QStringLiteral("update") });
        }

        if (sub == QStringLiteral("repair") || sub == QStringLiteral("repair-permissions")) {
            std::cout << "Fixing permissions on ~/.local/share/hyprpm via sudo...\n";
            QProcess proc;
            proc.setProcessChannelMode(QProcess::ForwardedChannels);
            proc.setInputChannelMode(QProcess::ForwardedInputChannel);
            QString path = QDir::homePath() + QStringLiteral("/.local/share/hyprpm");
            proc.start(QStringLiteral("sudo"), {
                QStringLiteral("chown"),
                QStringLiteral("-R"),
                QStringLiteral("%1:%2").arg(getuid()).arg(getgid()),
                path
            });
            proc.waitForFinished(-1);
            if (proc.exitCode() == 0) {
                std::cout << "\033[1;32m✔ Permissions successfully restored.\033[0m\n";
            }
            return proc.exitCode();
        }

        if (sub == QStringLiteral("reload")) {
            return runInteractiveHyprpm({ QStringLiteral("reload"), QStringLiteral("-n") });
        }

        std::cerr << "Unknown plugin action: " << sub.toStdString() << "\nRun 'flightdeck plugin --help' for available commands.\n";
        return 1;
    }

    std::cerr << "Unknown command: " << cmd.toStdString() << "\n";
    return 1;
}

} // namespace FlightDeck::Cli
