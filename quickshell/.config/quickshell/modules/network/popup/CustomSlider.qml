import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../../core"
import "../../../components"

// Slider en píldora pálida (estilo del volumen de música) con icono + %.
Item {
    id: root
    height: 28
    Layout.fillWidth: true

    property string iconSource: ""
    property string mutedIconSource: ""
    property color activeColor: Theme.primary
    property real value: 0
    property real to: 100
    property bool canMute: false
    property bool isMuted: false
    readonly property bool isDragging: track.dragging

    signal moved(real val)
    signal toggleMuteClicked()

    readonly property real _pos: root.to > 0
        ? Math.max(0, Math.min(1, root.value / root.to))
        : 0

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.alpha(Theme.surfaceVariant, 0.5)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.25)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16

            Image {
                id: icn
                anchors.fill: parent
                source: (root.isMuted && root.mutedIconSource !== "") ? root.mutedIconSource : root.iconSource
                visible: false
            }

            ColorOverlay {
                anchors.fill: icn
                source: icn
                color: root.isMuted ? Theme.alpha(Theme.inkSurfVar, 0.5) : root.activeColor
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.canMute
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.toggleMuteClicked()
            }
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool dragging: false
            property real dragPos: 0
            readonly property real shownPos: track.dragging ? track.dragPos : root._pos

            Rectangle {
                id: base
                width: parent.width
                height: 4
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(Theme.inkSurf, 0.14)

                Rectangle {
                    width: base.width * track.shownPos
                    height: parent.height
                    radius: 2
                    color: root.isMuted ? Theme.alpha(Theme.inkSurfVar, 0.5) : root.activeColor
                }
            }

            Rectangle {
                id: thumb
                width: (track.dragging || trackMa.containsMouse) ? 14 : 8
                height: width
                radius: width / 2
                color: root.isMuted ? Theme.alpha(Theme.inkSurfVar, 0.5) : root.activeColor
                x: Math.max(0, Math.min(parent.width - width, parent.width * track.shownPos - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            Timer {
                id: throttle
                interval: 80
                property real pendingVal: -1
                onTriggered: {
                    if (pendingVal >= 0) {
                        root.moved(pendingVal)
                        pendingVal = -1
                    }
                }
            }

            MouseArea {
                id: trackMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function clamp(v) { return Math.max(0, Math.min(1, v)) }

                onPressed: {
                    track.dragging = true
                    track.dragPos = clamp(mouse.x / width)
                }
                onPositionChanged: {
                    if (!track.dragging)
                        return
                    track.dragPos = clamp(mouse.x / width)
                    throttle.pendingVal = track.dragPos * root.to
                    throttle.restart()
                }
                onReleased: {
                    if (!track.dragging)
                        return
                    // Aplicar antes de soltar el drag para no pintar el valor viejo.
                    root.moved(track.dragPos * root.to)
                    track.dragging = false
                    throttle.stop()
                    throttle.pendingVal = -1
                }
                onCanceled: {
                    track.dragging = false
                    throttle.stop()
                    throttle.pendingVal = -1
                }
            }
        }

        AppText {
            Layout.preferredWidth: 32
            text: Math.round(root.value) + "%"
            color: Theme.inkSurfVar
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
        }
    }
}
