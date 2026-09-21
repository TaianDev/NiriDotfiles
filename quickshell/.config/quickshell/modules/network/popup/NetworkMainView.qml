import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../../core"
import "../../../services"

Item {
    id: root
    width: 320
    height: 386

    property string iconsPath: AppPaths.iconsDir
    signal requestPage(int pageIndex)

    readonly property var status: NetworkStatusService

    readonly property bool wifiEnabled: status.wifiEnabled
    readonly property string wifiNetwork: status.wifiNetwork
    readonly property bool airplaneMode: status.airplaneMode
    readonly property bool dndMode: status.dndMode
    readonly property bool nightMode: status.nightMode
    readonly property real sysVol: AudioService.volume
    readonly property bool sysVolMute: AudioService.muted
    readonly property real sysMic: AudioService.micVolume
    readonly property bool sysMicMute: AudioService.micMuted
    readonly property real sysBright: status.sysBright
    readonly property var btAdapter: status.btAdapter
    readonly property bool btEnabled: status.btEnabled
    readonly property string btDeviceName: status.btDeviceName

    function refresh() {
        status.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            NetworkToggle {
                title: "Wi-Fi"
                subtitle: root.wifiEnabled
                    ? (root.wifiNetwork !== "" ? root.wifiNetwork : "On")
                    : "Off"
                isToggled: root.wifiEnabled
                iconSource: root.wifiEnabled
                    ? root.iconsPath + "wifi-full.svg"
                    : root.iconsPath + "no-wifi.svg"
                iconTint: root.wifiEnabled ? Theme.primary : Theme.inkSurf
                onToggleClicked: status.setWifiEnabled(!root.wifiEnabled)
                onArrowClicked: root.requestPage(1)
            }

            NetworkToggle {
                title: "Bluetooth"
                subtitle: root.btEnabled
                    ? (root.btDeviceName !== "" ? root.btDeviceName : "On")
                    : "Off"
                isToggled: root.btEnabled
                iconSource: root.btEnabled
                    ? root.iconsPath + "bluetooth.svg"
                    : root.iconsPath + "no-bluetooth.svg"
                iconTint: root.btEnabled ? Theme.primary : Theme.inkSurf
                onToggleClicked: {
                    if (!root.btAdapter)
                        return
                    if (root.airplaneMode)
                        status.setAirplaneMode(false)
                    root.btAdapter.enabled = !root.btAdapter.enabled
                    Qt.callLater(status.refresh)
                }
                onArrowClicked: root.requestPage(2)
            }
        }

        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 12
            Layout.alignment: Qt.AlignHCenter

            SmallToggle {
                iconSource: root.iconsPath + "airplane.svg"
                title: "Airplane"
                isToggled: root.airplaneMode
                activeColor: Theme.tertiary
                onClicked: status.setAirplaneMode(!root.airplaneMode)
            }

            SmallToggle {
                iconSource: root.iconsPath + "no-notification.svg"
                title: "Silent"
                isToggled: root.dndMode
                activeColor: Theme.secondary
                onClicked: status.setDndMode(!root.dndMode)
            }

            SmallToggle {
                iconSource: root.iconsPath + "night.svg"
                title: "Night"
                isToggled: root.nightMode
                activeColor: Theme.tertiary
                Layout.columnSpan: 2
                Layout.fillWidth: true
                onClicked: status.setNightMode(!root.nightMode)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.rightMargin: 15
            Layout.leftMargin: 15
            spacing: 14

            CustomSlider {
                id: brightSlider
                value: root.sysBright
                iconSource: root.iconsPath + "brightness.svg"
                activeColor: Theme.inkSurf
                onMoved: val => NetworkStatusService.runAction("bright", val.toString())
            }

            CustomSlider {
                id: volSlider
                value: root.sysVol
                iconSource: root.iconsPath + "volume.svg"
                activeColor: Theme.primary
                canMute: true
                isMuted: root.sysVolMute
                mutedIconSource: root.iconsPath + "no-volume.svg"
                onMoved: val => AudioService.setVolume(val)
                onToggleMuteClicked: AudioService.toggleMute()
            }

            CustomSlider {
                id: micSlider
                value: root.sysMic
                iconSource: root.iconsPath + "mic.svg"
                activeColor: Theme.err
                canMute: true
                isMuted: root.sysMicMute
                mutedIconSource: root.iconsPath + "no-mic.svg"
                onMoved: val => AudioService.setMicVolume(val)
                onToggleMuteClicked: AudioService.toggleMicMute()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            spacing: 18

            ListModel {
                id: powerModel
                ListElement { icon: "power"; action: "poweroff" }
                ListElement { icon: "sleep"; action: "sleep" }
                ListElement { icon: "logout"; action: "logout" }
                ListElement { icon: "lock"; action: "lock" }
            }

            Repeater {
                model: powerModel

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22

                    property color accentCol: {
                        switch (model.action) {
                        case "poweroff": return Theme.primary
                        case "sleep": return Theme.tertiary
                        case "logout": return Theme.secondary
                        case "lock": return Theme.err
                        default: return Theme.inkSurf
                        }
                    }

                    color: pwrMa.containsMouse
                           ? Theme.alpha(Theme.inkSurf, 0.15)
                           : Theme.alpha(Theme.surfaceVariant, 0.6)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        id: pwrIcn
                        anchors.centerIn: parent
                        source: root.iconsPath + model.icon + ".svg"
                        width: 20
                        height: 20
                        sourceSize: Qt.size(20, 20)
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: pwrIcn
                        source: pwrIcn
                        color: pwrMa.containsMouse ? accentCol : Theme.alpha(Theme.inkSurf, 0.8)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: pwrMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            switch (model.action) {
                            case "poweroff": SessionService.poweroff(); break
                            case "sleep":    SessionService.sleep(); break
                            case "logout":   SessionService.logout(); break
                            case "lock":     SessionService.lock(); break
                            }
                        }
                    }
                }
            }
        }
    }
}
