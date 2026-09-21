import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../components"
import "popup"

PillBase {
    gradient: true
    id: root

    property var hostWindow: null
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    property real rxSpeed: SystemMonitorService.rxSpeed
    property real txSpeed: SystemMonitorService.txSpeed

    content: RowLayout {
        id: contentRow
        spacing: 10

        WifiModule {
            iconsPath: root.iconsPath
            rxSpeed:   root.rxSpeed
            txSpeed:   root.txSpeed
        }

        Rectangle {
            width: 1; height: 14
            color: Theme.alpha(Theme.outline, 0.4)
        }

        BluetoothModule {
            iconsPath: root.iconsPath
        }
    }

    function togglePopup() {
        netPopup.toggle()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    NetworkPopup {
        id: netPopup
        hostWindow: root.hostWindow
        anchorItem: root
    }
}
