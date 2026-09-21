import QtQuick
import Quickshell
import "../../../components"
import "../../../core"

Item {
    id: root

    property string iconsPath: AppPaths.iconsDir
    property int iconSize: 16

    implicitWidth: 28
    implicitHeight: 28

    SvgIcon {
        anchors.centerIn: parent
        source: root.iconsPath + "note-music.svg"
        size: root.iconSize
        tint: Theme.inkSurf
        opacity: ma.containsMouse ? 0.65 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([
            "kitty", "--class", "kitty-floating", "cava"
        ])
    }
}
