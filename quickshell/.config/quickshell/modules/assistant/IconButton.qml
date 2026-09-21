import QtQuick
import "../../core"
import "../../components"

Item {
    id: root

    property string iconSource: ""
    property int iconSize: 14
    property color iconColor: Theme.inkSurfVar
    property int buttonSize: 32
    property color backgroundColor: Theme.alpha(Theme.surfaceVariant, 0.6)
    property color hoverColor: Theme.alpha(Theme.outlineVariant, 0.85)

    signal clicked()

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize

    Item {
        anchors.fill: parent
        scale: ma.pressed ? 0.88 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: ma.containsMouse ? root.hoverColor : root.backgroundColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        SvgIcon {
            anchors.centerIn: parent
            source: root.iconSource
            size: root.iconSize
            tint: ma.containsMouse ? Theme.inkSurf : root.iconColor
            Behavior on tint { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
