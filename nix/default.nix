{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  qt6,
  hyprland,
  glib,
  dconf,
  xorg ? null,
  xrdb ? xorg.xrdb,
  lua5_4,
  material-symbols,
  m3shapes,
}:
let
  m3shapesQml = stdenv.mkDerivation {
    pname = "m3shapes-qml";
    version = "unstable";
    src = m3shapes;

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      qt6.wrapQtAppsHook
    ];
    buildInputs = [
      qt6.qtbase
      qt6.qtdeclarative
    ];
    cmakeFlags = [
      "-DINSTALL_QMLDIR=lib/qt6/qml"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "flightdeck";
  version = "1.0.0";

  src = ./..;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.qtshadertools
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
    qt6.qtsvg
    m3shapesQml
  ];

  postPatch = ''
    cp "${material-symbols}/share/fonts/truetype/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \
      assets/fonts/MaterialSymbolsRounded.ttf
  '';

  cmakeFlags = [
    "-DFLIGHTDECK_VERSION=1.0.0"
  ];

  qtWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ hyprland glib dconf xrdb lua5_4 ])
    "--prefix" "QML2_IMPORT_PATH" ":" "${m3shapesQml}/lib/qt6/qml"
    "--prefix" "LD_LIBRARY_PATH" ":" "${m3shapesQml}/lib/qt6/qml/M3Shapes"
    "--set-default" "QT_QUICK_CONTROLS_STYLE" "Basic"
    "--unset" "QT_STYLE_OVERRIDE"
  ];


  meta = with lib; {
    description = "FlightDeck - Qt6 GUI controller and management cockpit for Hyprland and Caelestia";
    homepage = "https://github.com/AstraSuite/FlightDeck";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "flightdeck";
  };
})
