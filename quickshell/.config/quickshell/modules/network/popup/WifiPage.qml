import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../../core"

Item {
    id: root
    anchors.fill: parent

    property string iconsPath: AppPaths.iconsDir

    property string connectingSsid: ""
    property string errorSsid:      ""
    property var    savedNetworks:  []
    property bool   refreshing:    false

    function forceRefresh() {
        refreshing = true
        savedScanner.running = true
        scanner.running = true
    }

    ListModel { id: wifiModel }

    // ── 1. Smart scanner ───────────────────────────────────────
    Process {
        id: scanner
        command: [
            "bash", "-c",
            "LC_ALL=C nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n').filter(l => l !== "")
                // 🔒 If there are no lines, leave the model untouched (avoids disappearing)
                if (lines.length === 0) {
                    root.refreshing = false
                    return
                }

                let activeNet = null
                let otherMap  = {}

                for (const line of lines) {
                    const idx1     = line.indexOf(':')
                    if (idx1 < 0) continue
                    const inUse    = line.substring(0, idx1)
                    const rest1    = line.substring(idx1 + 1)
                    const signal   = parseInt(rest1.substring(rest1.lastIndexOf(':') + 1))
                    const rest2    = rest1.substring(0, rest1.lastIndexOf(':'))
                    const secIdx   = rest2.lastIndexOf(':')
                    const security = rest2.substring(secIdx + 1)
                    const ssid     = rest2.substring(0, secIdx)

                    if (!ssid || ssid === "") continue

                    const isActive = inUse === "*"
                    const entry = {
                        ssid:     ssid,
                        security: security,
                        active:   isActive,
                        signal:   isNaN(signal) ? 0 : signal,
                        saved:    root.savedNetworks.includes(ssid)
                    }

                    if (isActive) {
                        activeNet = entry
                    } else {
                        if (!otherMap[ssid] || otherMap[ssid].signal < entry.signal)
                            otherMap[ssid] = entry
                    }
                }

                const others = Object.values(otherMap).sort((a, b) => b.signal - a.signal)
                const newList = []
                if (activeNet) newList.push(activeNet)
                for (const net of others) newList.push(net)

                // 🌟 Diff inteligente
                for (let i = 0; i < Math.min(newList.length, wifiModel.count); i++) {
                    const n = newList[i]
                    wifiModel.setProperty(i, "ssid",     n.ssid)
                    wifiModel.setProperty(i, "security", n.security)
                    wifiModel.setProperty(i, "active",   n.active)
                    wifiModel.setProperty(i, "signal",   n.signal)
                    wifiModel.setProperty(i, "saved",    n.saved)
                }
                for (let i = wifiModel.count; i < newList.length; i++)
                    wifiModel.append(newList[i])
                while (wifiModel.count > newList.length)
                    wifiModel.remove(wifiModel.count - 1)

                root.refreshing = false
            }
        }
    }

    // ── 2. Saved networks scanner ─────────────────────────────
    Process {
        id: savedScanner
        command: ["bash", "-c", "LC_ALL=C nmcli -t -f NAME connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = this.text.trim().split('\n').map(l => l.trim())
                for (let i = 0; i < wifiModel.count; i++) {
                    let s = wifiModel.get(i).ssid
                    wifiModel.setProperty(i, "saved", root.savedNetworks.includes(s))
                }
            }
        }
    }

    // 🔄 Soft start: only enable running
    onVisibleChanged: {
        if (visible) {
            savedScanner.running = true
            scanner.running = true
        }
    }

    // ⏱ Periodic refresh without harsh restarts
    Timer {
        interval: 8000
        running: root.visible
        repeat: true
        onTriggered: {
            scanner.running = true
        }
    }

    // ── 3. Connect ────────────────────────────────────────────
    Process {
        id: connector
        property string targetSsid: ""
        command: ["nmcli", "dev", "wifi", "connect", targetSsid]

        onExited: (code) => {
            if (code === 0) {
                root.errorSsid = ""
            } else {
                root.errorSsid = root.connectingSsid
            }
            root.connectingSsid = ""
            // Refresh data after the action
            savedScanner.running = true
            scanner.running = true
        }
    }

    // ── 4. Olvidar ────────────────────────────────────────────
    Process {
        id: forgetter
        property string targetSsid: ""
        command: ["nmcli", "connection", "delete", targetSsid]

        onExited: {
            savedScanner.running = true
            scanner.running = true
        }
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
            model: wifiModel
            spacing: 4

            delegate: Item {
                width: listView.width
                height: 48

                readonly property bool isConnecting:  root.connectingSsid === model.ssid
                readonly property bool hasError:      root.errorSsid      === model.ssid
                readonly property bool needsPassword: model.security !== "" && !model.saved && !model.active

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: model.active
                        ? Qt.rgba(0.2, 0.6, 1.0, 0.2)
                        : (bgMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")

                    MouseArea {
                        id: bgMa
                        anchors.fill: parent
                        hoverEnabled: !root.refreshing
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.refreshing || model.active || isConnecting) return
                            root.errorSsid = ""
                            root.connectingSsid = model.ssid
                            connector.targetSsid = model.ssid
                            connector.running = true
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Image {
                                id: wifiIcn
                                anchors.fill: parent
                                source: model.signal > 75
                                        ? root.iconsPath + "wifi-full.svg"
                                        : model.signal > 40
                                            ? root.iconsPath + "wifi-medium.svg"
                                            : root.iconsPath + "wifi-low.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: wifiIcn; source: wifiIcn
                                color: model.active ? Theme.primary : Theme.inkSurf
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                text:  model.ssid
                                color: model.active ? Theme.primary : Theme.inkSurf
                                font.pixelSize: 13
                                font.bold: model.active
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                visible: isConnecting || hasError || model.active || model.saved
                                text: isConnecting   ? "Authenticating..."
                                      : hasError     ? "Authentication failed"
                                      : model.active ? "Connected"
                                      : model.saved  ? "Saved"
                                      : ""
                                color: hasError      ? Theme.err
                                       : model.active? Theme.primary
                                       : Qt.rgba(1,1,1,0.5)
                                font.pixelSize: 11
                            }
                        }

                        Item {
                            visible: needsPassword && !isConnecting
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            Image {
                                id: lockIcn; anchors.fill: parent
                                source: root.iconsPath + "lock.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcn; source: lockIcn
                                color: Qt.rgba(1,1,1,0.35)
                            }
                        }

                        Rectangle {
                            visible: model.saved && !isConnecting
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
                                    forgetter.targetSsid = model.ssid
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

