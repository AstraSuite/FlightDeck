cmake_minimum_required(VERSION 3.19)

# Version selection: pass -DFLIGHTDECK_VERSION=X.Y.Z to pin the version manually,
# otherwise derive it from the most recent git tag (e.g. v1.0.0).
set(FLIGHTDECK_VERSION ""
    CACHE STRING "Version of flightdeck (default: latest git tag)")

if(NOT FLIGHTDECK_VERSION)
    find_package(Git QUIET)
    if(GIT_EXECUTABLE)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags --match "v[0-9]*" --abbrev=0 HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE git_describe_result
            OUTPUT_VARIABLE git_describe_version
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(git_describe_result EQUAL 0 AND git_describe_version)
            string(REGEX REPLACE "^v" "" FLIGHTDECK_VERSION "${git_describe_version}")
        endif()
    endif()
endif()

if(NOT FLIGHTDECK_VERSION)
    # Dev version: 0.YYYYMMDD
    find_package(Git REQUIRED)
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" log -1 --format=%cd --date=format:%Y%m%d
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        OUTPUT_VARIABLE git_date
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(FLIGHTDECK_VERSION "0.${git_date}")
endif()

project(FlightDeck VERSION ${FLIGHTDECK_VERSION} LANGUAGES CXX)

add_compile_definitions(ASTRA_VERSION="${FLIGHTDECK_VERSION}")

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR CMAKE_INSTALL_PREFIX STREQUAL "/usr/local")
    set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH "Default install prefix" FORCE)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Quick QuickControls2 ShaderTools Concurrent Network DBus Svg)

qt_standard_project_setup(REQUIRES 6.5)

# C++ Source files
file(GLOB_RECURSE PROJECT_SOURCES CONFIGURE_DEPENDS
    "src/*.cpp"
    "src/*.hpp"
)

qt_add_executable(flightdeck ${PROJECT_SOURCES})

qt_add_shaders(flightdeck "blob_shaders"
    BATCHABLE
    OPTIMIZED
    PREFIX "/"
    GLSL "300es,120,150,330,450"
    HLSL 50
    MSL 20000
    FILES
        shaders/blob.vert
        shaders/blob.frag
)

target_include_directories(flightdeck PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/blobs
    ${CMAKE_CURRENT_SOURCE_DIR}/src/caelestia
    ${CMAKE_CURRENT_SOURCE_DIR}/src/cli
    ${CMAKE_CURRENT_SOURCE_DIR}/src/config
    ${CMAKE_CURRENT_SOURCE_DIR}/src/hyprland
    ${CMAKE_CURRENT_SOURCE_DIR}/src/managers
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
)

target_link_libraries(flightdeck PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::ShaderTools
    Qt6::Concurrent
    Qt6::Network
    Qt6::DBus
    Qt6::Svg
)

# Embed assets resources
qt_add_resources(flightdeck "resources"
    PREFIX "/"
    FILES
        assets/icons/flightdeck.svg
        assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf
)

# Add QML files with CONFIGURE_DEPENDS
file(GLOB_RECURSE QML_FILES CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "qml/*.qml" "qml/**/qmldir")
qt_add_resources(flightdeck "qml_resources"
    PREFIX "/"
    FILES ${QML_FILES}
)

# Tests
add_executable(test_autostart
    tests/test_autostart.cpp
    src/managers/autostartmanager.cpp
    src/caelestia/flightdeckwriter.cpp
    src/caelestia/luavalidator.cpp
    src/hyprland/hyprlandsocket.cpp
)
target_include_directories(test_autostart PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/managers
    ${CMAKE_CURRENT_SOURCE_DIR}/src/caelestia
    ${CMAKE_CURRENT_SOURCE_DIR}/src/hyprland
)
target_link_libraries(test_autostart PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Network
)

# Installation
include(GNUInstallDirs)

install(TARGETS flightdeck
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES assets/flightdeck.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES assets/icons/flightdeck.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)
