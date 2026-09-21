pragma Singleton
import QtQuick

QtObject {
    id: root

    signal themeUpdated()

    property color background: "#111318"
    property color inkBg: "#e2e2e9"
    property color surface: "#111318"
    property color inkSurf: "#e2e2e9"
    property color surfaceVariant: "#44474f"
    property color inkSurfVar: "#c4c6d0"

    property color primary: "#adc6ff"
    property color inkPrim: "#112f60"
    property color primaryContainer: "#2b4678"
    property color inkPrimCont: "#d8e2ff"

    property color secondary: "#bfc6dc"
    property color inkSec: "#293041"
    property color secondaryContainer: "#3f4759"
    property color inkSecCont: "#dbe2f9"

    property color tertiary: "#debcdf"
    property color inkTer: "#402843"
    property color tertiaryContainer: "#583e5b"
    property color inkTerCont: "#fcd7fb"

    property color err: "#ffb4ab"
    property color inkErr: "#690005"
    property color errContainer: "#93000a"
    property color inkErrCont: "#ffdad6"

    property color outline: "#8e9099"
    property color outlineVariant: "#44474f"
    property color colorShadow: "#000000"

    property color inkBgMuted: "#9a9ca6"

    // Aliases for semantic color names used across modules
    readonly property alias onBackground: root.inkBg
    readonly property alias onPrimary: root.inkPrim
    readonly property alias onPrimaryContainer: root.inkPrimCont
    readonly property alias error: root.err
    readonly property alias onBackgroundMuted: root.inkBgMuted

    function alpha(baseColor, opacity) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, opacity)
    }

    readonly property real barPillBorderWidth: 2

    function barPillBorderColor() {
        return alpha(outline, 0.30)
    }

    function barPillBackgroundColor() {
        return alpha(surfaceVariant, 0.6)
    }

    function applyFromParsed(colors) {
        if (colors.background !== undefined) background = colors.background
        if (colors.onBackground !== undefined) inkBg = colors.onBackground
        if (colors.surface !== undefined) surface = colors.surface
        if (colors.onSurface !== undefined) inkSurf = colors.onSurface
        if (colors.surfaceVariant !== undefined) surfaceVariant = colors.surfaceVariant
        if (colors.onSurfaceVariant !== undefined) inkSurfVar = colors.onSurfaceVariant
        if (colors.primary !== undefined) primary = colors.primary
        if (colors.onPrimary !== undefined) inkPrim = colors.onPrimary
        if (colors.primaryContainer !== undefined) primaryContainer = colors.primaryContainer
        if (colors.onPrimaryContainer !== undefined) inkPrimCont = colors.onPrimaryContainer
        if (colors.secondary !== undefined) secondary = colors.secondary
        if (colors.onSecondary !== undefined) inkSec = colors.onSecondary
        if (colors.secondaryContainer !== undefined) secondaryContainer = colors.secondaryContainer
        if (colors.onSecondaryContainer !== undefined) inkSecCont = colors.onSecondaryContainer
        if (colors.tertiary !== undefined) tertiary = colors.tertiary
        if (colors.onTertiary !== undefined) inkTer = colors.onTertiary
        if (colors.tertiaryContainer !== undefined) tertiaryContainer = colors.tertiaryContainer
        if (colors.onTertiaryContainer !== undefined) inkTerCont = colors.onTertiaryContainer
        if (colors.error !== undefined) err = colors.error
        if (colors.onError !== undefined) inkErr = colors.onError
        if (colors.errorContainer !== undefined) errContainer = colors.errorContainer
        if (colors.onErrorContainer !== undefined) inkErrCont = colors.onErrorContainer
        if (colors.outline !== undefined) outline = colors.outline
        if (colors.outlineVariant !== undefined) outlineVariant = colors.outlineVariant
        if (colors.shadow !== undefined) colorShadow = colors.shadow
        if (colors.onBackgroundMuted !== undefined) inkBgMuted = colors.onBackgroundMuted
        themeUpdated()
    }
}
