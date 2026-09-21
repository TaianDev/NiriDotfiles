pragma Singleton
import QtQuick

QtObject {
    id: root

    function alpha(baseColor, opacity) {
        if (opacity < 0) opacity = 0
        if (opacity > 1) opacity = 1
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, opacity)
    }

    function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value))
    }

    function mix(c1, c2, t) {
        t = clamp(t, 0, 1)
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    function rgba(r, g, b, a) {
        return Qt.rgba(r / 255, g / 255, b / 255, a)
    }
}
