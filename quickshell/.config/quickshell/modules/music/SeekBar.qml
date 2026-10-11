import QtQuick
import "../../components"
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

    // Barra plana (mismo componente que el volumen).
    FlatSlider {
        width: parent.width
        enabled: root.player !== null
        value: root.progress
        onMoved: val => {
            if (root.player?.canSeek)
                root.player.position = val * root.player.length
        }
    }

    Item {
        width: parent.width
        height: 14

        AppText {
            anchors.left: parent.left
            text: TimeUtils.formatMMSS(root.positionSecs)
            color: Theme.inkSurfVar
            font.pixelSize: 10
        }

        AppText {
            anchors.right: parent.right
            text: TimeUtils.formatMMSS(root.lengthSecs)
            color: Theme.inkSurfVar
            font.pixelSize: 10
        }
    }
}
