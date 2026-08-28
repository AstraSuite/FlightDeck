pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import FlightDeck.Config
import FlightDeck.Theme

QtObject {
    id: root

    property bool showPreview
    property string scheme: ThemeWatcher.name
    property string flavour: ThemeWatcher.flavour
    property string variant: ThemeWatcher.variant
    property string previewScheme: ""
    property string previewFlavour: ""
    property string previewVariant: ""
    readonly property bool light: showPreview ? previewLight : currentLight
    readonly property bool currentLight: ThemeWatcher.isLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}
    readonly property real wallLuminance: 0.0

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    readonly property bool isWindowMode: true

    function layer(c: color, layer: var): color {
        if (!transparency.enabled || isWindowMode)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function loadFromThemeWatcher(): void {
        const coloursMap = ThemeWatcher.colours;
        for (const name in coloursMap) {
            const hex = "#" + coloursMap[name];
            const propName = name.startsWith("term") ? name : `m3${name}`;
            if (propName in current) {
                current[propName] = hex;
            }
        }
    }

    function setMode(mode: string): void {
        ThemeWatcher.setMode(mode);
    }

    property Connections _conn: Connections {
        target: ThemeWatcher
        function onThemeChanged(): void {
            root.loadFromThemeWatcher();
        }
    }

    Component.onCompleted: {
        root.loadFromThemeWatcher();
    }

    component Transparency: QtObject {
        readonly property bool enabled: Tokens.transparency.enabled
        readonly property real base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Tokens.transparency.layers))
    }

    component M3TPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(root.palette.m3background, 0)
        readonly property color m3onBackground: root.layer(root.palette.m3onBackground)
        readonly property color m3surface: root.layer(root.palette.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(root.palette.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        readonly property color m3outline: root.layer(root.palette.m3outline)
        readonly property color m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        readonly property color m3shadow: root.layer(root.palette.m3shadow)
        readonly property color m3scrim: root.layer(root.palette.m3scrim)
        readonly property color m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        readonly property color m3primary: root.layer(root.palette.m3primary)
        readonly property color m3onPrimary: root.layer(root.palette.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        readonly property color m3secondary: root.layer(root.palette.m3secondary)
        readonly property color m3onSecondary: root.layer(root.palette.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(root.palette.m3tertiary)
        readonly property color m3onTertiary: root.layer(root.palette.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        readonly property color m3error: root.layer(root.palette.m3error)
        readonly property color m3onError: root.layer(root.palette.m3onError)
        readonly property color m3errorContainer: root.layer(root.palette.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        readonly property color m3success: root.layer(root.palette.m3success)
        readonly property color m3onSuccess: root.layer(root.palette.m3onSuccess)
        readonly property color m3successContainer: root.layer(root.palette.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(root.palette.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#4c807d"
        property color m3secondary_paletteKeyColor: "#627c7a"
        property color m3tertiary_paletteKeyColor: "#517d94"
        property color m3neutral_paletteKeyColor: "#737877"
        property color m3neutral_variant_paletteKeyColor: "#6e7978"
        property color m3background: "#0a0f0f"
        property color m3onBackground: "#dce8e6"
        property color m3surface: "#0a0f0f"
        property color m3surfaceDim: "#0a0f0f"
        property color m3surfaceBright: "#242e2d"
        property color m3surfaceContainerLowest: "#000000"
        property color m3surfaceContainerLow: "#0e1514"
        property color m3surfaceContainer: "#131b1a"
        property color m3surfaceContainerHigh: "#192120"
        property color m3surfaceContainerHighest: "#1d2827"
        property color m3onSurface: "#dce8e6"
        property color m3surfaceVariant: "#1d2827"
        property color m3onSurfaceVariant: "#a2adac"
        property color m3inverseSurface: "#f6faf9"
        property color m3inverseOnSurface: "#515655"
        property color m3outline: "#6d7876"
        property color m3outlineVariant: "#3f4a49"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#9bd0cc"
        property color m3primary: "#9bd0cc"
        property color m3onPrimary: "#0d4845"
        property color m3primaryContainer: "#255b58"
        property color m3onPrimaryContainer: "#b8ede9"
        property color m3inversePrimary: "#336764"
        property color m3secondary: "#b0ccc9"
        property color m3onSecondary: "#2c4543"
        property color m3secondaryContainer: "#27403e"
        property color m3onSecondaryContainer: "#a9c5c2"
        property color m3tertiary: "#d5efff"
        property color m3onTertiary: "#2e5c72"
        property color m3tertiaryContainer: "#b6e3fe"
        property color m3onTertiaryContainer: "#255369"
        property color m3error: "#fa746f"
        property color m3onError: "#490006"
        property color m3errorContainer: "#871f21"
        property color m3onErrorContainer: "#ff9993"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color m3primaryFixed: "#b7ede9"
        property color m3primaryFixedDim: "#a9deda"
        property color m3onPrimaryFixed: "#0c4744"
        property color m3onPrimaryFixedVariant: "#306461"
        property color m3secondaryFixed: "#cce8e5"
        property color m3secondaryFixedDim: "#bedad7"
        property color m3onSecondaryFixed: "#2b4442"
        property color m3onSecondaryFixedVariant: "#47605e"
        property color m3tertiaryFixed: "#b6e3fe"
        property color m3tertiaryFixedDim: "#a8d5ef"
        property color m3onTertiaryFixed: "#0b4156"
        property color m3onTertiaryFixedVariant: "#2f5d73"
        property color term0: "#343434"
        property color term1: "#769e00"
        property color term2: "#56e2c0"
        property color term3: "#81fcce"
        property color term4: "#76b6b3"
        property color term5: "#7aaee9"
        property color term6: "#83d8c9"
        property color term7: "#cddcd3"
        property color term8: "#9aa59e"
        property color term9: "#85b900"
        property color term10: "#41f7d0"
        property color term11: "#cdffe9"
        property color term12: "#a3c8c3"
        property color term13: "#a2c0f7"
        property color term14: "#8bedd9"
        property color term15: "#ffffff"
    }
}
