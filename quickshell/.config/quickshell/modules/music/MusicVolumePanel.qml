import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../../components"
import "../../core"

Item {
    id: root

    property var    player: null
    property int    radius: 16

    readonly property bool supported: root.player?.volumeSupported ?? false
    readonly property real volumePct: Math.round((root.player?.volume ?? 0) * 100)

    implicitWidth: 52
    implicitHeight: 164

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: root.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)
        clip: true

        Column {
            anchors.centerIn: parent
            spacing: 10

            Slider {
                id: volSlider
                width: 28
                height: 112
                orientation: Qt.Vertical
                from: 0
                to: 100
                value: root.volumePct
                enabled: root.player !== null

                background: Rectangle {
                    x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                    y: volSlider.topPadding
                    width: 4
                    height: volSlider.availableHeight
                    radius: 2
                    color: Theme.alpha(Theme.inkSurf, 0.14)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: volSlider.position * parent.height
                        radius: 2
                        color: Theme.primary
                    }
                }

                handle: Rectangle {
                    x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                    y: volSlider.topPadding + (1 - volSlider.position) * (volSlider.availableHeight - height)
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.primary
                }

                onMoved: {
                    if (root.player)
                        root.player.volume = value / 100
                }
            }

            AppText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.volumePct + "%"
                color: Theme.inkSurfVar
                font.pixelSize: 10
            }
        }
    }
}