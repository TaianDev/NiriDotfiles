import QtQuick
import "../../core"

Item {
    id: root

    property bool active: false
    property bool fromBottom: false
    property bool fromRight: false
    property real cornerRadius: 16
    property real borderAlpha: 1
    property color panelColor: Theme.background

    readonly property bool exitRunning: slideOut.running
    readonly property real startX: fromRight ? Math.max(width, 1) : 0
    readonly property real startY: fromRight ? 0
        : (fromBottom ? Math.max(height, 1) : -Math.max(height, 1))

    default property alias content: inner.data

    anchors.fill: parent
    clip: true

    property real slideX: 0
    property real slideY: 0

    Item {
        id: slideWrap
        width: parent.width
        height: Math.max(parent.height, 1)
        x: root.slideX
        y: root.slideY

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.panelColor
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, root.borderAlpha)
            clip: true

            Item {
                id: inner
                anchors.fill: parent
            }
        }
    }

    onActiveChanged: {
        if (active) {
            slideX = root.startX
            slideY = root.startY
            if (width > 0 && height > 0)
                slideIn.restart()
        } else if (width > 0 && height > 0) {
            slideOut.restart()
        }
    }

    onWidthChanged: root.maybeRestartSlide()
    onHeightChanged: root.maybeRestartSlide()

    function maybeRestartSlide() {
        if (!active || slideIn.running || width <= 0 || height <= 0)
            return
        if (Math.abs(slideX - root.startX) < 0.5 && Math.abs(slideY - root.startY) < 0.5)
            slideIn.restart()
    }

    ParallelAnimation {
        id: slideIn
        NumberAnimation {
            target: root; property: "slideX"
            from: root.startX; to: 0
            duration: 260; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "slideY"
            from: root.startY; to: 0
            duration: 260; easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: slideOut
        NumberAnimation {
            target: root; property: "slideX"
            from: 0; to: root.startX
            duration: 180; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root; property: "slideY"
            from: 0; to: root.startY
            duration: 180; easing.type: Easing.InCubic
        }
        onStopped: root.exitFinished()
    }

    signal exitFinished()
}
