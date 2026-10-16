import QtQuick
import Quickshell
import "../../../components"
import "../../../core"
import "../../../services"

Item {
    id: root

    property string iconsPath: AppPaths.iconsDir
    property int iconSize: 16

    // Active layout from NiriData (niri exposes names + current_idx).
    readonly property string activeLayout: {
        const name = NiriData.currentKeyboardLayout
        return name ? name.substring(0, 2).toUpperCase() : ""
    }

    implicitWidth: 28 + (layoutText.visible ? layoutText.implicitWidth + 2 : 0)
    implicitHeight: 28

    SvgIcon {
        id: svgIcon
        anchors.verticalCenter: parent.verticalCenter
        x: 6
        source: root.iconsPath + "keyboard.svg"
        size: root.iconSize
        tint: Theme.inkTerCont
        opacity: ma.containsMouse ? 0.65 : 1.0
        Behavior on opacity { ColorAnimation { duration: 150 } }
    }

    AppText {
        id: layoutText
        anchors.left: svgIcon.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.activeLayout
        color: Theme.inkTerCont
        font.pixelSize: 9
        font.bold: true
        visible: text !== ""
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NiriData.switchLayoutNext()
    }
}
