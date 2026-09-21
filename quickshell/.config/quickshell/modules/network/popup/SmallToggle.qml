import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../components"

Rectangle {
    id: root
    width: 154
    height: 44
    radius: 12
    color: Theme.alpha(Theme.surfaceVariant, 0.85)

    property string iconText: ""
    property string iconSource: ""
    property string title: ""
    property bool isToggled: false
    property color activeColor: Theme.primary

    signal clicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        SvgIcon {
            visible: root.iconSource !== ""
            source: root.iconSource
            size: 16
            tint: root.isToggled ? root.activeColor : Theme.inkSurf
        }
        Text {
            visible: root.iconSource === "" && root.iconText !== ""
            text: root.iconText
            color: root.isToggled ? root.activeColor : Theme.inkSurf
            font.pixelSize: 16
        }
        Text {
            text: root.title
            color: Theme.inkSurf
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
        }

        Rectangle {
            width: 36
            height: 20
            radius: 10
            color: root.isToggled ? root.activeColor : Theme.alpha(Theme.outline, 1)
            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: Theme.inkPrim
                y: 2
                x: root.isToggled ? 18 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
