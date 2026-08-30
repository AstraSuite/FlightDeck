#include <QApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QIcon>
#include <QDir>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQuickWindow>

#include "themewatcher.hpp"
#include "utils/cutils.hpp"
#include "utils/iconimageprovider.hpp"
#include "config/tokensattached.hpp"
#include "config/tokens.hpp"
#include "config/appearanceconfig.hpp"
#include "config/config.hpp"
#include "config/font.hpp"
#include "config/anim.hpp"
#include "blobs/blobgroup.hpp"
#include "blobs/blobinvertedrect.hpp"
#include "blobs/blobrect.hpp"
#include "blobs/blobmaterial.hpp"
#include "blobs/blobshape.hpp"
#include "cli/clihandler.hpp"

#include "caelestia/caelestiavars.hpp"
#include "caelestia/astrahelmwriter.hpp"
#include "caelestia/caelestiabootstrap.hpp"
#include "hyprland/hyprlandstate.hpp"
#include "hyprland/hyprlandschema.hpp"
#include "managers/monitormanager.hpp"
#include "managers/animationmanager.hpp"
#include "managers/cursormanager.hpp"
#include "managers/autostartmanager.hpp"
#include "managers/profilemanager.hpp"
#include "managers/airlockmanager.hpp"
#include "utils/cursorimageprovider.hpp"

#ifndef ASTRA_VERSION
#define ASTRA_VERSION "1.0.0"
#endif

int main(int argc, char* argv[]) {
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    qputenv("QT_NO_XDG_DESKTOP_PORTAL", "1");

    // Perform one-time check that astra-flightdeck.lua is sourced in hypr-user.lua
    FlightDeck::Caelestia::CaelestiaBootstrap::ensureFlightDeckSourced();

    bool isCliCommand = false;
    if (argc > 1) {
        const QString firstArg = QString::fromUtf8(argv[1]);
        if (firstArg == QStringLiteral("get") || firstArg == QStringLiteral("set") ||
            firstArg == QStringLiteral("reload") || firstArg == QStringLiteral("profile") ||
            firstArg == QStringLiteral("-h") || firstArg == QStringLiteral("--help") ||
            firstArg == QStringLiteral("-v") || firstArg == QStringLiteral("--version")) {
            isCliCommand = true;
        }
    }

    if (isCliCommand) {
        QCoreApplication app(argc, argv);
        app.setApplicationName(QStringLiteral("FlightDeck"));
        app.setOrganizationName(QStringLiteral("AstraSuite"));
        app.setApplicationVersion(QStringLiteral(ASTRA_VERSION));

        return FlightDeck::Cli::CliHandler::run(argc, argv);
    }

    const QString userName = qgetenv("USER").isEmpty() ? QStringLiteral("default") : QString::fromLocal8Bit(qgetenv("USER"));
    const QString serverName = QStringLiteral("flightdeck-single-instance-") + userName;

    {
        QLocalSocket socket;
        socket.connectToServer(serverName);
        if (socket.waitForConnected(500)) {
            socket.write("SHOW\n");
            socket.flush();
            socket.waitForBytesWritten(1000);
            return 0;
        }
    }

    QSurfaceFormat format;
    format.setRedBufferSize(8);
    format.setGreenBufferSize(8);
    format.setBlueBufferSize(8);
    format.setAlphaBufferSize(8);
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("FlightDeck"));
    app.setOrganizationName(QStringLiteral("AstraSuite"));
    app.setApplicationVersion(QStringLiteral(ASTRA_VERSION));
    app.setQuitOnLastWindowClosed(true);

    const QString iconPath = QStringLiteral(":/assets/icons/flightdeck.svg");
    if (QFile::exists(iconPath)) {
        app.setWindowIcon(QIcon(iconPath));
    } else {
        app.setWindowIcon(QIcon(QStringLiteral("assets/icons/flightdeck.svg")));
    }

    const QString fontPath = QStringLiteral(":/assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf");
    if (QFontDatabase::addApplicationFont(fontPath) == -1) {
        QFontDatabase::addApplicationFont(QStringLiteral("assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf"));
    }

    // Register Singletons and Types
    const char* themeUris[] = { "FlightDeck.Theme", "Helm.Theme", "Foundry.Theme" };
    for (const char* uri : themeUris) {
        qmlRegisterSingletonType<ThemeWatcher>(uri, 1, 0, "ThemeWatcher", &ThemeWatcher::create);
    }

    const char* caelestiaUris[] = { "FlightDeck.Caelestia", "Helm.Caelestia" };
    for (const char* uri : caelestiaUris) {
        qmlRegisterSingletonType<FlightDeck::Caelestia::CaelestiaVars>(uri, 1, 0, "CaelestiaVars", &FlightDeck::Caelestia::CaelestiaVars::create);
        qmlRegisterSingletonType<FlightDeck::Caelestia::FlightDeckWriter>(uri, 1, 0, "FlightDeckWriter", &FlightDeck::Caelestia::FlightDeckWriter::create);
        qmlRegisterSingletonType<FlightDeck::Caelestia::FlightDeckWriter>(uri, 1, 0, "AstraHelmWriter", &FlightDeck::Caelestia::FlightDeckWriter::create);
    }

    const char* hyprlandUris[] = { "FlightDeck.Hyprland", "Helm.Hyprland" };
    for (const char* uri : hyprlandUris) {
        qmlRegisterSingletonType<FlightDeck::Hyprland::HyprlandState>(uri, 1, 0, "HyprlandState", &FlightDeck::Hyprland::HyprlandState::create);
        qmlRegisterSingletonType<FlightDeck::Hyprland::HyprlandSchema>(uri, 1, 0, "HyprlandSchema", &FlightDeck::Hyprland::HyprlandSchema::create);
    }

    const char* managerUris[] = { "FlightDeck.Managers", "Helm.Managers" };
    for (const char* uri : managerUris) {
        qmlRegisterSingletonType<FlightDeck::Managers::MonitorManager>(uri, 1, 0, "MonitorManager", &FlightDeck::Managers::MonitorManager::create);
        qmlRegisterSingletonType<FlightDeck::Managers::AnimationManager>(uri, 1, 0, "AnimationManager", &FlightDeck::Managers::AnimationManager::create);
        qmlRegisterSingletonType<FlightDeck::Managers::CursorManager>(uri, 1, 0, "CursorManager", &FlightDeck::Managers::CursorManager::create);
        qmlRegisterSingletonType<FlightDeck::Managers::AutostartManager>(uri, 1, 0, "AutostartManager", &FlightDeck::Managers::AutostartManager::create);
        qmlRegisterSingletonType<FlightDeck::Managers::ProfileManager>(uri, 1, 0, "ProfileManager", &FlightDeck::Managers::ProfileManager::create);
        qmlRegisterSingletonType<FlightDeck::Managers::AirlockManager>(uri, 1, 0, "AirlockManager", &FlightDeck::Managers::AirlockManager::create);
    }

    const char* configUris[] = { "FlightDeck.Config", "Helm.Config", "Foundry.Config", "Caelestia.Config" };
    for (const char* uri : configUris) {
        qmlRegisterSingletonType<caelestia::config::TokenConfig>(uri, 1, 0, "Tokens", &caelestia::config::TokenConfig::create);
        qmlRegisterSingletonType<caelestia::config::GlobalConfig>(uri, 1, 0, "GlobalConfig", &caelestia::config::GlobalConfig::create);

        qmlRegisterUncreatableType<caelestia::config::Tokens>(uri, 1, 0, "Tokens", QStringLiteral("Attached property"));
        qmlRegisterAnonymousType<caelestia::config::AppearanceRounding>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearanceSpacing>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearancePadding>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearanceTransparency>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearanceFont>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearanceAnim>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AppearanceConfig>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::FontTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::FontStyleBase>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::FontStyle>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::IconFontStyle>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::FontBuilders>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::IconFontBuilders>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AnimTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AnimDurationTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AnimCurves>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::SizeTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::BarTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::AstraTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::DashboardTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::LauncherTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::NotifsTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::OsdTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::SessionTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::SidebarTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::UtilitiesTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::LockTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::WInfoTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::RoundingTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::SpacingTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::PaddingTokens>(uri, 1);
        qmlRegisterAnonymousType<caelestia::config::FontSizeTokens>(uri, 1);
    }

    const char* blobUris[] = { "FlightDeck.Blobs", "Helm.Blobs", "Foundry.Blobs", "Caelestia.Blobs" };
    for (const char* uri : blobUris) {
        qmlRegisterType<BlobGroup>(uri, 1, 0, "BlobGroup");
        qmlRegisterType<BlobInvertedRect>(uri, 1, 0, "BlobInvertedRect");
        qmlRegisterType<BlobRect>(uri, 1, 0, "BlobRect");
        qmlRegisterType<BlobMaterial>(uri, 1, 0, "BlobMaterial");
        qmlRegisterType<BlobShape>(uri, 1, 0, "BlobShape");
    }

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("icon"), new IconImageProvider());
    engine.addImageProvider(QStringLiteral("cursor"), new CursorImageProvider());

    // Prefer local filesystem QML if running in development tree, fallback to embedded qrc
    QString localQmlDir;
    if (QFile::exists(QDir::currentPath() + QStringLiteral("/qml/Main.qml"))) {
        localQmlDir = QDir::currentPath() + QStringLiteral("/qml");
    } else if (QFile::exists(QDir::currentPath() + QStringLiteral("/../qml/Main.qml"))) {
        localQmlDir = QFileInfo(QDir::currentPath() + QStringLiteral("/../qml")).canonicalFilePath();
    } else if (QFile::exists(QGuiApplication::applicationDirPath() + QStringLiteral("/../qml/Main.qml"))) {
        localQmlDir = QFileInfo(QGuiApplication::applicationDirPath() + QStringLiteral("/../qml")).canonicalFilePath();
    }

    if (!localQmlDir.isEmpty()) {
        engine.addImportPath(localQmlDir);
        engine.addImportPath(QFileInfo(localQmlDir + QStringLiteral("/..")).canonicalFilePath());
    }
    engine.addImportPath(QStringLiteral("qrc:/qml"));
    engine.addImportPath(QStringLiteral("qrc:/"));

    const QUrl url = !localQmlDir.isEmpty()
        ? QUrl::fromLocalFile(localQmlDir + QStringLiteral("/Main.qml"))
        : QUrl(QStringLiteral("qrc:/qml/Main.qml"));

    QObject* rootWindow = nullptr;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url, &rootWindow](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
        if (obj && url == objUrl)
            rootWindow = obj;
    }, Qt::QueuedConnection);

    auto* ipcServer = new QLocalServer(&app);
    ipcServer->setSocketOptions(QLocalServer::UserAccessOption);
    QObject::connect(ipcServer, &QLocalServer::newConnection, ipcServer, [ipcServer, &rootWindow]() {
        while (QLocalSocket* client = ipcServer->nextPendingConnection()) {
            QObject::connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
            QObject::connect(client, &QLocalSocket::readyRead, client, [client, &rootWindow]() {
                while (client->canReadLine()) {
                    const QByteArray command = client->readLine().trimmed();
                    if (command == "SHOW" || command == "OPEN_GUI") {
                        if (QQuickWindow* win = qobject_cast<QQuickWindow*>(rootWindow)) {
                            win->show();
                            win->raise();
                            win->requestActivate();
                        }
                    }
                }
            });
        }
    });

    if (!ipcServer->listen(serverName) && ipcServer->serverError() == QAbstractSocket::AddressInUseError) {
        QLocalServer::removeServer(serverName);
        ipcServer->listen(serverName);
    }

    engine.rootContext()->setContextProperty(QStringLiteral("appVersion"), QStringLiteral(ASTRA_VERSION));
    engine.load(url);

    return app.exec();
}
