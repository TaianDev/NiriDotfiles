import QtQuick
import "../../core"

// Slider fino y plano (estilo Material) compartido por progreso y volumen.
// Al arrastrar no rompe el binding de `value`: usa un valor interno de drag y
// emite `moved` al soltar.
Item {
    id: root

    property real value: 0          // en [from, to]
    property real from: 0
    property real to: 1
    property color accentColor: Theme.primary
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 18

    readonly property real _pos: (root.to > root.from)
        ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
        : 0
    readonly property real shownPos: mouse.dragging ? mouse.dragPos : _pos

    Rectangle {
        id: track
        width: parent.width
        height: 4
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.alpha(Theme.inkSurf, 0.14)

        Rectangle {
            width: track.width * root.shownPos
            height: parent.height
            radius: 2
            color: root.enabled ? root.accentColor : Theme.alpha(Theme.inkSurf, 0.25)
        }
    }

    Rectangle {
        id: thumb
        width: (mouse.containsMouse || mouse.dragging) ? 14 : 8
        height: width
        radius: width / 2
        color: root.enabled ? root.accentColor : Theme.alpha(Theme.inkSurf, 0.3)
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.shownPos - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on x {
            enabled: !mouse.dragging
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        property bool dragging: false
        property real dragPos: 0

        function clamp(v) { return Math.max(0, Math.min(1, v)) }

        onPressed: {
            dragging = true
            dragPos = clamp(mouse.x / width)
        }
        onPositionChanged: {
            if (dragging)
                dragPos = clamp(mouse.x / width)
        }
        onReleased: {
            if (!dragging)
                return
            dragging = false
            root.moved(root.from + dragPos * (root.to - root.from))
        }
    }
}
