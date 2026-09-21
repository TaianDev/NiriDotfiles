pragma Singleton
import QtQuick

QtObject {
    id: root

    property color background: "#1a2121"
    property color surface: "#252b2c"
    property color surfaceHeader: "#303637"

    property color inkBg: "#dee4e4"
    readonly property alias onBackground: root.inkBg
    property color inkBgMuted: "#bec8c9"
    readonly property alias onBackgroundMuted: root.inkBgMuted

    property color primary: "#81d3dd"
    property color inkPrim: "#00363b"
    readonly property alias onPrimary: root.inkPrim

    property color primaryContainer: "#004f56"
    property color inkPrimCont: "#9df0fa"
    readonly property alias onPrimaryContainer: root.inkPrimCont

    property color secondary: "#b1cbcf"
    property color inkSec: "#1c3437"
    readonly property alias onSecondary: root.inkSec

    property color tertiary: "#b8c6ea"
    property color outline: "#3f484a"
    property color outlineActive: "#899294"

    property color err: "#ffb4ab"
    readonly property alias error: root.err
    property color inkErr: "#690005"
    readonly property alias onError: root.inkErr

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }

    function applyFromParsed(colors) {
        if (colors.background !== undefined) background = colors.background
        if (colors.surface !== undefined) surface = colors.surface
        if (colors.surfaceHeader !== undefined) surfaceHeader = colors.surfaceHeader
        if (colors.onBackground !== undefined) inkBg = colors.onBackground
        if (colors.onBackgroundMuted !== undefined) inkBgMuted = colors.onBackgroundMuted
        if (colors.primary !== undefined) primary = colors.primary
        if (colors.onPrimary !== undefined) inkPrim = colors.onPrimary
        if (colors.primaryContainer !== undefined) primaryContainer = colors.primaryContainer
        if (colors.onPrimaryContainer !== undefined) inkPrimCont = colors.onPrimaryContainer
        if (colors.secondary !== undefined) secondary = colors.secondary
        if (colors.onSecondary !== undefined) inkSec = colors.onSecondary
        if (colors.tertiary !== undefined) tertiary = colors.tertiary
        if (colors.outline !== undefined) outline = colors.outline
        if (colors.outlineActive !== undefined) outlineActive = colors.outlineActive
        if (colors.error !== undefined) err = colors.error
        if (colors.onError !== undefined) inkErr = colors.onError
    }
}
