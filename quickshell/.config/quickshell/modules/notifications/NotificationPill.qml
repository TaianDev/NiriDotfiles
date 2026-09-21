import QtQuick
import Quickshell
import "../../core"
import "../../services"
import "../../components"

Item {
    id: root

    property string iconsPath: AppPaths.iconsDir
    property int iconSize: 16

    implicitWidth: 28
    implicitHeight: 28

    readonly property bool hasUnread: NotificationService.unreadCount > 0

    SvgIcon {
        anchors.centerIn: parent
        source: root.iconsPath + "notifications.svg"
        size: root.iconSize
        tint: Theme.inkSurf
        opacity: ma.containsMouse ? 0.65 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        width: 7
        height: 7
        radius: 3.5
        color: Theme.err
        visible: root.hasUnread
        scale: root.hasUnread ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.togglePanel()
    }
}
