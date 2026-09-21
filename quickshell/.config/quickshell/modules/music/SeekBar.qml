import QtQuick
import "../../utils"
import "../../core"

Column {
    id: root
    spacing: 5

    property var player: null
    property bool playing: false
    property real progress: 0
    property real positionSecs: 0
    property real lengthSecs: 0

    width: parent ? parent.width : 260

    Item {
        id: row
        width: parent.width
        height: 18

        readonly property bool dragging: seekHover.dragging
        readonly property real dragProgress: seekHover.seekProgress

        readonly property real thumbX: (row.dragging ? row.dragProgress : root.progress) * width

        Rectangle {
            id: track
            width: parent.width
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.alpha(Theme.inkSurf, 0.14)

            Rectangle {
                id: fill
                width: track.width * (row.dragging ? row.dragProgress : root.progress)
                height: parent.height
                radius: 2
                color: Theme.primary
                Behavior on width {
                    enabled: !row.dragging
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            id: thumb
            width: seekHover.containsMouse || seekHover.dragging ? 14 : 8
            height: width
            radius: width / 2
            color: seekHover.containsMouse || seekHover.dragging
                ? Theme.primary
                : Theme.alpha(Theme.primary, 0.8)
            x: Math.max(0, Math.min(parent.width - width, row.thumbX - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on x {
                enabled: !row.dragging
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: seekHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            property bool dragging: false
            property real seekProgress: 0

            onPressed: mouse => {
                dragging = true
                seekProgress = Math.max(0, Math.min(1, mouse.x / width))
            }

            onPositionChanged: mouse => {
                if (!dragging) return
                seekProgress = Math.max(0, Math.min(1, mouse.x / width))
            }

            onReleased: mouse => {
                if (!dragging) return
                dragging = false
                if (root.player?.canSeek)
                    root.player.position = seekProgress * root.player.length
            }
        }
    }

    Item {
        width: parent.width
        height: 14

        Text {
            anchors.left: parent.left
            text: TimeUtils.formatMMSS(root.positionSecs)
            color: Theme.inkSurfVar
            font.pixelSize: 10
        }

        Text {
            anchors.right: parent.right
            text: TimeUtils.formatMMSS(root.lengthSecs)
            color: Theme.inkSurfVar
            font.pixelSize: 10
        }
    }
}