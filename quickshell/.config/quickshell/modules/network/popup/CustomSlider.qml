import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../../core"

Item {
    id: root
    height: 32
    Layout.fillWidth: true

    property string iconSource: ""
    property string mutedIconSource: ""
    property color activeColor: Theme.primary
    property real value: 0
    property real to: 100
    property bool isDragging: slider.pressed
    property bool canMute: false
    property bool isMuted: false

    signal moved(real val)
    signal toggleMuteClicked()

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Item {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18

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
                enabled: root.canMute
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.toggleMuteClicked()
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            from: 0
            to: root.to

            Binding on value {
                when: !slider.pressed
                value: root.value
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 6
                radius: 3
                color: Theme.alpha(Theme.outline, 0.35)

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.isMuted ? Theme.alpha(Theme.inkSurfVar, 0.5) : root.activeColor
                    radius: 3
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16
                height: 16
                radius: 8
                color: Theme.primaryContainer
                border.color: Theme.alpha(Theme.outline, 0.35)
                border.width: 1
            }

            Timer {
                id: throttle
                interval: 20
                property real pendingVal: -1
                onTriggered: {
                    if (pendingVal >= 0) {
                        root.moved(pendingVal)
                        pendingVal = -1
                    }
                }
            }

            onMoved: {
                throttle.pendingVal = value
                throttle.restart()
            }
        }
    }
}
