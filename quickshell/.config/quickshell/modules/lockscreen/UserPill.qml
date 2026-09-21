import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: pill.width
    implicitHeight: pill.height

    property string iconsPath: ""
    property string userName: ""
    property string uptimeText: ""
    property bool menuOpen: false

    property int batCapacity: -1
    property string batStatus: ""
    property string wifiSsid: ""
    property string btDevice: ""

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }

    readonly property int batIconIndex: batCapacity < 0 ? 0 : Math.min(5, Math.floor(batCapacity / 100 * 6))

    // ── PILL ─────────────────────────────────────────────────
    Rectangle {
        id: pill
        height: 44
        radius: 12
        color: alpha(Theme.surface, 0.8)
        border.width: 1
        border.color: alpha(Theme.outline, 0.3)
        width: userRow.width + 24
        z: 10

        Row {
            id: userRow
            anchors.centerIn: parent
            spacing: 10

            Image {
                id: userIcon
                anchors.verticalCenter: parent.verticalCenter
                source: root.iconsPath + "user.svg"
                width: 16; height: 16
                sourceSize.width: 16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                cache: true
                layer.enabled: true
                layer.effect: ColorOverlay { color: alpha(Theme.onBackground, 0.7) }
            }

            Text {
                id: userNameText
                anchors.verticalCenter: parent.verticalCenter
                text: root.userName !== "" ? root.userName : "..."
                color: nameMa.containsMouse ? Theme.primary : Theme.onBackground
                font.pixelSize: 13
                font.weight: Font.Medium
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: nameMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuOpen = !root.menuOpen
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 18
                color: alpha(Theme.outline, 0.25)
            }

            Text {
                id: uptimeLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.uptimeText
                color: alpha(Theme.onBackground, 0.6)
                font.pixelSize: 12
                font.weight: Font.Normal
            }
        }
    }

    // ── MENU ─────────────────────────────────────────────────
    Item {
        id: menuContainer
        anchors.right: parent.right
        anchors.bottom: pill.top
        anchors.bottomMargin: 8
        width: 200
        clip: true
        height: root.menuOpen ? 132 : 0

        Behavior on height {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: menuShadow
            anchors.fill: menuBox
            anchors.leftMargin: 4
            anchors.topMargin: 4
            anchors.rightMargin: -4
            anchors.bottomMargin: -6
            radius: menuBox.radius + 4
            color: alpha("#000000", 0.25)
            visible: root.menuOpen
            z: -1

            layer.enabled: root.menuOpen
            layer.effect: FastBlur {
                radius: 8
                cached: true
            }
        }

        Rectangle {
            id: menuBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height
            radius: 16
            enabled: root.menuOpen
            color: Theme.surface
            border.width: 1
            border.color: alpha(Theme.outline, 0.3)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Battery
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8; rightMargin: 8
                        }
                        spacing: 10

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: root.batCapacity >= 0
                                ? root.iconsPath + "battery-" + root.batIconIndex + ".svg"
                                : root.iconsPath + "battery-0.svg"
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            cache: true
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: root.batCapacity >= 0 && root.batCapacity <= 10
                                    ? Theme.error : alpha(Theme.onBackground, 0.7)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 55
                            Layout.alignment: Qt.AlignVCenter
                            text: "Battery"
                            color: alpha(Theme.onBackground, 0.7)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.batCapacity >= 0
                                ? root.batCapacity + "% " + root.batStatus
                                : "N/A"
                            color: alpha(Theme.onBackground, 0.85)
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }

                // WiFi
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8; rightMargin: 8
                        }
                        spacing: 10

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: root.iconsPath + (root.wifiSsid !== "" ? "wifi-full.svg" : "no-wifi.svg")
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            cache: true
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: root.wifiSsid !== ""
                                    ? Theme.primary : alpha(Theme.onBackground, 0.4)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 55
                            Layout.alignment: Qt.AlignVCenter
                            text: "Wi-Fi"
                            color: alpha(Theme.onBackground, 0.7)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.wifiSsid !== "" ? root.wifiSsid : "Disconnected"
                            color: root.wifiSsid !== ""
                                ? alpha(Theme.onBackground, 0.85)
                                : alpha(Theme.onBackground, 0.4)
                            font.pixelSize: 12
                            font.weight: root.wifiSsid !== "" ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }

                // Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8; rightMargin: 8
                        }
                        spacing: 10

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            source: root.iconsPath + (root.btDevice !== "" ? "bluetooth.svg" : "no-bluetooth.svg")
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            cache: true
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: root.btDevice !== ""
                                    ? Theme.primary : alpha(Theme.onBackground, 0.4)
                            }
                        }

                        Text {
                            Layout.preferredWidth: 55
                            Layout.alignment: Qt.AlignVCenter
                            text: "Bluetooth"
                            color: alpha(Theme.onBackground, 0.7)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.btDevice !== "" ? root.btDevice : "No devices"
                            color: root.btDevice !== ""
                                ? alpha(Theme.onBackground, 0.85)
                                : alpha(Theme.onBackground, 0.4)
                            font.pixelSize: 12
                            font.weight: root.btDevice !== "" ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // ── DATA COLLECTION ──────────────────────────────────────
    Process {
        id: uptimeResolver
        command: ["bash", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim()
                root.uptimeText = text !== "" ? text : "..."
            }
        }
    }

    Process {
        id: infoCollector
        command: ["bash", "-c", "echo \"cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)\nstatus=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)\nssid=$(nmcli -t -f IN-USE,SSID dev wifi list 2>/dev/null | grep '^\\*' | cut -d: -f2)\nbt=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.indexOf("cap=") === 0) {
                        root.batCapacity = parseInt(line.substring(4))
                    } else if (line.indexOf("status=") === 0) {
                        root.batStatus = line.substring(7)
                    } else if (line.indexOf("ssid=") === 0) {
                        root.wifiSsid = line.substring(5)
                    } else if (line.indexOf("bt=") === 0) {
                        root.btDevice = line.substring(3)
                    }
                }
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: {
            uptimeResolver.running = true
            infoCollector.running = true
        }
    }

    Component.onCompleted: {
        uptimeResolver.running = true
        infoCollector.running = true
    }
}
