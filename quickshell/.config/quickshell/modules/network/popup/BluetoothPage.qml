import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../../../core"

Item {
    id: root
    anchors.fill: parent

    property string iconsPath: AppPaths.iconsDir

    property string connectingMac: ""
    property string errorMac:      ""
    property bool   refreshing:   false

    // API Nativa de Quickshell
    property var adapter: Bluetooth.defaultAdapter

    function forceRefresh() {
        refreshing = true
        btScanner.running = false
        btScanner.running = true
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 2000
        onTriggered: {
            syncDevices()
            refreshing = false
        }
    }

    ListModel { id: btModel }

    // ── 1. Sync engine (ultra-fast native read) ──
    function syncDevices() {
        if (!adapter || !adapter.enabled) {
            btModel.clear()
            return
        }

        const devs = adapter.devices.values
        let connectedDevs = []
        let pairedDevs = []
        let otherDevs = []

        for (let i = 0; i < devs.length; i++) {
            let d = devs[i]
            // Skip nameless devices (usually low-power noise)
            if (!d.name || d.name === "") continue

            let entry = {
                mac:       d.address ?? "",
                name:      d.name,
                connected: d.connected ?? false,
                paired:    d.paired ?? false
            }

            if (entry.connected) connectedDevs.push(entry)
            else if (entry.paired) pairedDevs.push(entry)
            else otherDevs.push(entry)
        }

        // Secondary alphabetical order
        pairedDevs.sort((a, b) => a.name.localeCompare(b.name))
        otherDevs.sort((a, b) => a.name.localeCompare(b.name))

        let newList = [].concat(connectedDevs, pairedDevs, otherDevs)

        // 🌟 Smart diff (no flicker)
        for (let i = 0; i < Math.min(newList.length, btModel.count); i++) {
            const n = newList[i]
            btModel.setProperty(i, "mac",       n.mac)
            btModel.setProperty(i, "name",      n.name)
            btModel.setProperty(i, "connected", n.connected)
            btModel.setProperty(i, "paired",    n.paired)
        }
        for (let i = btModel.count; i < newList.length; i++)
            btModel.append(newList[i])
        while (btModel.count > newList.length)
            btModel.remove(btModel.count - 1)
    }

    // ── 2. Force background scanning ──
    // Keeps the antenna scanning for new devices while the window is open
    Process {
        id: btScanner
        command: ["bluetoothctl", "scan", "on"]
        running: root.visible && adapter && adapter.enabled
    }

    onVisibleChanged: {
        if (visible) syncDevices()
    }

    Timer {
        interval: 3000 // Faster refresh because reading from memory does not use CPU
        running: root.visible
        repeat: true
        onTriggered: syncDevices()
    }

    // ── 3. Conectar / Desconectar ─────────────────────────────
    Process {
        id: connector
        property string targetMac: ""
        property bool   isDisconnecting: false
        
        command: isDisconnecting 
                 ? ["bluetoothctl", "disconnect", targetMac]
                 : ["bluetoothctl", "connect", targetMac]

        onExited: (code) => {
            if (code === 0) {
                root.errorMac = ""
            } else {
                root.errorMac = root.connectingMac
            }
            root.connectingMac = ""
            syncDevices()
        }
    }

    // ── 4. Olvidar (Desvincular) ──────────────────────────────
    Process {
        id: forgetter
        property string targetMac: ""
        command: ["bluetoothctl", "remove", targetMac]

        onExited: syncDevices()
    }

    // ── 5. Interfaz Visual ─────────────────────────────────────
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        enabled: !root.refreshing
        layer.enabled: root.refreshing
        layer.effect: FastBlur {
            radius: 32
        }

        ListView {
            id: listView
            anchors.fill: parent
            model: btModel
            spacing: 4

            delegate: Item {
                width: listView.width
                height: 48

                readonly property bool isConnecting:  root.connectingMac === model.mac
                readonly property bool hasError:      root.errorMac      === model.mac

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: model.connected
                        ? Qt.rgba(0.2, 0.6, 1.0, 0.2)
                        : (bgMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")

                    MouseArea {
                        id: bgMa
                        anchors.fill: parent
                        hoverEnabled: !root.refreshing
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.refreshing || isConnecting) return
                            root.errorMac = ""
                            root.connectingMac = model.mac
                            
                            connector.targetMac = model.mac
                            // If connected, clicking disconnects it (iOS style)
                            connector.isDisconnecting = model.connected
                            connector.running = false
                            connector.running = true
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Bluetooth icon
                        Item {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Image {
                                id: btIcn
                                anchors.fill: parent
                                source: root.iconsPath + "bluetooth.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: btIcn; source: btIcn
                                color: model.connected ? Theme.primary : Theme.inkSurf
                            }
                        }

                        // Text column
                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                text:  model.name
                                color: model.connected ? Theme.primary : Theme.inkSurf
                                font.pixelSize: 13
                                font.bold: model.connected
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                visible: isConnecting || hasError || model.connected || model.paired
                                text: isConnecting     ? (model.connected ? "Disconnecting..." : "Connecting...")
                                      : hasError       ? "Connection failed"
                                      : model.connected? "Connected"
                                      : model.paired   ? "Paired"
                                      : ""
                                color: hasError        ? Theme.err
                                       : model.connected ? Theme.primary
                                       : Qt.rgba(1,1,1,0.5)
                                font.pixelSize: 11
                            }
                        }

                        // "Forget" button (visible on paired devices)
                        Rectangle {
                            visible: model.paired && !isConnecting
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 24
                            radius: 12
                            color: Qt.rgba(1, 0.2, 0.2, 0.15)

                            Text {
                                text: "Forget"
                                color: Theme.err
                                font.pixelSize: 11
                                font.bold: true
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    forgetter.targetMac = model.mac
                                    forgetter.running = false
                                    forgetter.running = true
                                }
                            }
                        }
                    }
                }
                        }
        }
    }

    Item {
        anchors.centerIn: parent
        visible: root.refreshing
        z: 10

        Column {
            anchors.centerIn: parent
            spacing: 12

            Item {
                width: 32
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: refreshIcn
                    anchors.fill: parent
                    source: root.iconsPath + "refresh.svg"
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: refreshIcn
                    source: refreshIcn
                    color: Theme.primary
                }
                RotationAnimation on rotation {
                    running: root.refreshing
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            Text {
                text: "Searching..."
                color: Theme.primary
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}

