import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../core"
import "../../services"
import "../../components"

Item {
    id: root

    readonly property int _trayBind: SystemTray.items.values.length

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property int iconSize: 16
    property var hostWindow: null
    property bool isOpened: false

    onIsOpenedChanged: {
        if (!isOpened)
            PopupManager.notifyClosed(PopupManager.trayId)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.trayId)
                root.isOpened = false
        }
    }

    implicitWidth: 28
    implicitHeight: 28

    SvgIcon {
        anchors.centerIn: parent
        source: root.iconsPath + (root.isOpened ? "up.svg" : "down.svg")
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
            if (root.isOpened) {
                root.isOpened = false
            } else {
                PopupManager.openExclusive(PopupManager.trayId)
                Qt.callLater(() => root.isOpened = true)
            }
        }
    }
}
