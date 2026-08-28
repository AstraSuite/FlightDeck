<p align="center">
  <img src="assets/icons/flightdeck.svg" width="140" alt="FlightDeck Logo">
</p>

<h1 align="center">FlightDeck</h1>

**FlightDeck** is a powerful, modern Hyprland configuration manager built with C++20 and Qt 6 / QML for the Astra Suite and Caelestia dotfiles. It features the unified Astra design language, real-time Caelestia shell tokens, and live scheme reloading.

## Features

- **Caelestia Dotfiles Integration**: Safe and non-destructive management of `~/.config/caelestia/hypr-vars.lua` and `~/.config/caelestia/flightdeck.lua` (or `astra-helm.lua`). Base `~/.config/hypr/` is completely untouched.
- **Unified Astra Design Language**: Built on Astra Suite's modular QML architecture with GPU-accelerated blob shaders, Google Sans Flex variable typography, and Material 3 design tokens.
- **Live Scheme Reloading**: Instant, seamless theme synchronization with `~/.local/state/caelestia/scheme.json`.
- **Display & Monitor Layout Preview**: Interactive 2D canvas for visually arranging and snapping monitors, adjusting resolutions, refresh rates, scaling factors, rotation, and VRR with live Hyprland IPC sync.
- **Animations & Bezier Curve Editor**: Interactive cubic-bezier curve graphical editor with draggable control handles, real-time velocity track preview, target switches, and Caelestia animation presets (`~/.config/caelestia/animations/*.lua`).
- **Keybindings Suite**: Interactive keybindings editor for window management, application shortcuts, utilities, custom keybinds, and workspace navigation modifiers.
- **Window & Layer Rules Management**: Graphical rule builder and editor for floating, pinned, opacity, workspace placement, and layer blur with live window client and layer namespace pickers.
- **Cursor Themes & Scaling**: System-wide Hyprcursor and XCursor theme discovery and instant sizing via `hyprctl setcursor`.
- **Autostart Manager**: Discovery and toggling of installed desktop applications and custom startup hooks.
- **Profiles & Snapshots**: Create, restore, and manage configuration backups.
- **Pending Changes & Live Testing**: Review sparse modifications, individual key reverts, and live IPC testing before writing to disk.

## Requirements

Build:

- Qt 6.5+ (Core, Gui, Widgets, Quick, QuickControls2, ShaderTools, Concurrent, Network, DBus, Svg)
- CMake (>= 3.19)
- C++20 compiler (GCC 11+ or Clang 13+)
- Ninja build system

Runtime:

- `hyprland` (running compositor)
- `caelestia-cli` / `caelestia-shell` (optional for automatic scheme notifications)

## Installation

### Arch Linux / AUR

FlightDeck is available on the [AUR](https://aur.archlinux.org):

```bash
# Release (builds from source)
paru -S astra-flightdeck
# or yay -S astra-flightdeck

# Precompiled binary (fast install)
paru -S astra-flightdeck-bin
# or yay -S astra-flightdeck-bin

# Latest git development
paru -S astra-flightdeck-git
# or yay -S astra-flightdeck-git
```

### Manual Installation (From Source)

Build and install FlightDeck system-wide:

```bash
mkdir -p build
cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

This installs the `flightdeck` binary to `/usr/bin/flightdeck`, desktop launcher to `/usr/share/applications/flightdeck.desktop`, and icons to `/usr/share/icons/hicolor/scalable/apps/flightdeck.svg`.

## Running the GUI

Launch the graphical interface:

```bash
flightdeck
```

## Using the CLI

Query a configuration variable:

```bash
flightdeck get terminal
flightdeck get windowRounding
```

Set a configuration variable and apply live:

```bash
flightdeck set terminal kitty
flightdeck set windowRounding 12
flightdeck set blurEnabled true
```

Reload Hyprland compositor:

```bash
flightdeck reload
```

Manage configuration profiles:

```bash
flightdeck profile list
flightdeck profile create my-setup
flightdeck profile restore my-setup
flightdeck profile delete my-setup
```

Show help and all available options:

```bash
flightdeck --help
```

## Acknowledgements

- UI design language, tokens, and components adapted from [Caelestia Shell](https://github.com/caelestia-dots/shell).
- Material Design icons and specifications by Google.
- Reference concepts from [Hyprmod](https://github.com/bluemancz/hyprmod).

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.
