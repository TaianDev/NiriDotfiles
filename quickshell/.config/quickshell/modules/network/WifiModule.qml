import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../core"
import "../../components"

Item {
    id: root
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property real rxSpeed: 0
    property real txSpeed: 0

    function formatSpeed(bps) {
        if (bps < 1024)    return Math.round(bps) + "B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + "K/s"
        return (bps / 1048576).toFixed(1) + "M/s"
    }

    readonly property var wifiDevice: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i]
        return null
    }

    readonly property bool enabled:   wifiDevice !== null
    readonly property bool connected: wifiDevice?.connected ?? false

    readonly property var activeNetwork: {
        if (!wifiDevice) return null
        const nets = wifiDevice.networks.values
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i]
        return null
    }

    readonly property string ssid:     activeNetwork?.name           ?? ""
    readonly property real   strength: activeNetwork?.signalStrength ?? 0.0

    readonly property string icon: {
        if (!enabled)         return iconsPath + "no-wifi.svg"
        if (!connected)       return iconsPath + "wifi-none.svg"
        if (strength >= 0.66) return iconsPath + "wifi-full.svg"
        if (strength >= 0.33) return iconsPath + "wifi-medium.svg"
        return iconsPath + "wifi-low.svg"
    }

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 5

        SvgIcon { source: root.icon; size: 13 }

        ScrollingText {
            text: root.connected ? root.ssid
                : (root.enabled ? "No network" : "WiFi Off")
            Layout.preferredWidth: 52
            maxWidth: 52
            fontSize: 11
            color: root.connected ? Theme.inkSurf : Theme.alpha(Theme.inkSurfVar, 0.7)
        }

        Row {
            spacing: 8
            visible: root.connected

            Row {
                spacing: 8
                SvgIcon {
                    source: root.iconsPath + "receive.svg"
                    size: 10; tint: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: 38
                    text:  root.formatSpeed(root.rxSpeed)
                    color: Theme.primary
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                spacing: 8
                SvgIcon {
                    source: root.iconsPath + "transmit.svg"
                    size: 10; tint: Theme.secondary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: 38
                    text:  root.formatSpeed(root.txSpeed)
                    color: Theme.secondary
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
