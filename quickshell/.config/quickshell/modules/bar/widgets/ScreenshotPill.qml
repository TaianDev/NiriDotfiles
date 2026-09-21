import QtQuick
import Quickshell
import "../../../components"
import "../../../core"

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../../assets/icons/")
    property int iconSize: 16

    implicitWidth: 28
    implicitHeight: 28

    SvgIcon {
        anchors.centerIn: parent
        source: root.iconsPath + "screenshot.svg"
        size: root.iconSize
        tint: Theme.inkSurf
        opacity: ma.containsMouse ? 0.65 : 1.0
        Behavior on opacity { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached([
                "bash", "-c",
                "grim -g \"$(slurp)\" -t ppm - | satty --filename -"
            ])
        }
    }
}
