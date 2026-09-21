pragma Singleton
import QtQuick

QtObject {
    // Canonical Material You palette parsed by both ThemeLoader (main shell)
    // and the lockscreen. Keep the property names in sync with:
    //   - core/ThemeManager.qml  (applyFromParsed)
    //   - modules/lockscreen/LockTheme.qml (applyFromParsed)

    // ─── BACKGROUNDS ───
    readonly property color background: "{{colors.surface_container.default.hex}}"
    readonly property color surface: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceHeader: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceVariant: "{{colors.surface_variant.default.hex}}"

    // ─── TEXT AND LEGIBILITY ───
    readonly property color onBackground: "{{colors.on_surface.default.hex}}"
    readonly property color onBackgroundMuted: "{{colors.on_surface_variant.default.hex}}"
    readonly property color onSurface: "{{colors.on_surface.default.hex}}"
    readonly property color onSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"

    // ─── PRIMARY ACCENTS ───
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color onPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"

    // ─── SECONDARY AND TERTIARY ───
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color onSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color onSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color onTertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    readonly property color onTertiaryContainer: "{{colors.on_tertiary_container.default.hex}}"

    // ─── BORDERS AND SEPARATORS ───
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color outlineActive: "{{colors.outline.default.hex}}"

    // ─── ERROR / ALERTS ───
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color onError: "{{colors.on_error.default.hex}}"
    readonly property color errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color onErrorContainer: "{{colors.on_error_container.default.hex}}"

    // ─── SHADOW ───
    readonly property color shadow: "{{colors.shadow.default.hex}}"
}
