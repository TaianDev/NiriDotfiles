import QtQuick
import QtQuick.Controls
import "../../services"

Item {
    id: root

    required property bool active
    required property string popupId

    default property alias content: contentHost.data

    anchors.fill: parent

    Shortcut {
        sequences: ["Escape"]
        onActivated: PopupManager.closeActive()
        enabled: root.active
        context: Qt.ApplicationShortcut
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
