import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../components"
import "../../../core"

Item {
    id: root

    property string iconsPath: AppPaths.iconsDir
    property int iconSize: 17

    implicitWidth: 22
    implicitHeight: 28

    SvgIcon {
        id: fedoraGlow
        anchors.centerIn: parent
        source: root.iconsPath + "fedora.svg"
        size: root.iconSize + 6
        tint: Theme.primary
        opacity: ma.containsMouse ? 0.55 : 0.38
        Behavior on opacity { ColorAnimation { duration: 180 } }
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 8
            transparentBorder: true
        }
    }

    SvgIcon {
        anchors.centerIn: parent
        source: root.iconsPath + "fedora.svg"
        size: root.iconSize
        tint: Theme.inkSurf
        opacity: ma.containsMouse ? 0.82 : 1.0
        Behavior on opacity { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
