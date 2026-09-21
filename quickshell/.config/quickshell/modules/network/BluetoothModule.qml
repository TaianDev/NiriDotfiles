import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../core"
import "../../components"

Item {
    id: root
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    readonly property var  adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    readonly property var connectedDevice: {
        if (!adapter) return null
        const devList = adapter.devices.values
        for (let i = 0; i < devList.length; i++)
            if (devList[i].connected) return devList[i]
        return null
    }
    readonly property string deviceName: connectedDevice?.name ?? ""

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Row {
        id: row
        spacing: 5

        SvgIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: root.enabled
                ? root.iconsPath + "bluetooth.svg"
                : root.iconsPath + "no-bluetooth.svg"
            size: 13
        }

        ScrollingText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.enabled && root.deviceName !== ""
            text:    root.deviceName
            maxWidth: 52
            fontSize: 11
            color: Theme.inkSurf
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.enabled || root.deviceName === ""
            text:    root.enabled ? "No device" : "BT Off"
            font.pixelSize: 11
            color:   Qt.rgba(1,1,1,0.4)
        }
    }
}
