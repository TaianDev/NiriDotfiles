pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell.Bluetooth
import "../core"
import "../utils"

Item {
    id: root
    visible: false

    signal updated()

    property int scanGeneration: 0
    property bool pendingRefresh: false

    property bool wifiEnabled: false
    property string wifiNetwork: ""
    property bool airplaneMode: false
    property bool dndMode: false
    property bool nightMode: false

    property real sysVol: 0
    property bool sysVolMute: false
    property real sysMic: 0
    property bool sysMicMute: false
    property real sysBright: 0

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: {
        if (root.airplaneMode) return false
        return btAdapter?.enabled ?? false
    }

    readonly property string btDeviceName: {
        if (!btAdapter || !btAdapter.enabled || root.airplaneMode) return ""
        const devs = btAdapter.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i].name
        }
        return ""
    }

    readonly property string statusScript: {
        const url = Qt.resolvedUrl("../scripts/network_status.sh").toString()
        return url.startsWith("file://") ? url.slice(7) : url
    }

    function refresh() {
        if (statusScanner.running) { root.pendingRefresh = true; return }
        statusScanner.running = false
        statusScanner.running = true
    }

    function parseBool(text) { return text === "true" || text === "1" || text === "yes" }

    function parsePercent(text, fallback) {
        const n = parseInt(text, 10)
        return isNaN(n) ? fallback : ColorUtils.clamp(n, 0, 100)
    }

    function applyScanLine(line) {
        if (!line || !line.includes("|")) return false

        const parts = line.trim().split("|")
        if (parts.length < 10) return false

        root.airplaneMode = root.parseBool(parts[2])
        root.wifiEnabled = parts[0] === "enabled" && !root.airplaneMode
        root.wifiNetwork = root.wifiEnabled ? (parts[1] ?? "") : ""

        root.sysVol = root.parsePercent(parts[5], root.sysVol)
        root.sysVolMute = root.parseBool(parts[6])
        root.sysMic = root.parsePercent(parts[7], root.sysMic)
        root.sysMicMute = root.parseBool(parts[8])
        root.sysBright = root.parsePercent(parts[9], root.sysBright)

        AudioService.applyFromParts(parts)

        root.scanGeneration++
        root.updated()
        return true
    }

    function finishScan() {
        if (root.pendingRefresh) { root.pendingRefresh = false; Qt.callLater(root.refresh) }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusScanner
        command: ["bash", root.statusScript]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(line => line.includes("|"))
                if (lines.length > 0) root.applyScanLine(lines[lines.length - 1])
                root.finishScan()
            }
        }

        onExited: root.finishScan()
    }

    Process {
        id: actionRunner
        property string actionType: ""
        property string actionValue: ""

        command: {
            switch (actionType) {
            case "airplane_on":
                return ["bash", "-c", "rfkill block wifi; rfkill block bluetooth; nmcli radio wifi off 2>/dev/null; true"]
            case "airplane_off":
                return ["bash", "-c", "rfkill unblock wifi; rfkill unblock bluetooth; true"]
            case "wifi_on":
                return ["bash", "-c", "rfkill unblock wifi 2>/dev/null; nmcli radio wifi on"]
            case "wifi_off":
                return ["nmcli", "radio", "wifi", "off"]
            case "dnd_on":
                return ["bash", "-c",
                    "if command -v dunstctl >/dev/null; then dunstctl set-paused true; " +
                    "elif command -v makoctl >/dev/null; then makoctl mode -a dnd; fi; true"]
            case "dnd_off":
                return ["bash", "-c",
                    "if command -v dunstctl >/dev/null; then dunstctl set-paused false; " +
                    "elif command -v makoctl >/dev/null; then makoctl mode -r dnd; fi; true"]
            case "night_on":
                return ["bash", "-c", "wlsunset -t 4000 -T 6500 &"]
            case "night_off":
                return ["pkill", "wlsunset"]
            case "vol":
                return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (parseInt(actionValue) / 100)]
            case "mic":
                return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (parseInt(actionValue) / 100)]
            case "bright":
                return ["brightnessctl", "set", actionValue + "%"]
            case "mute_vol":
                return ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
            case "mute_mic":
                return ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
            default:
                return ["true"]
            }
        }

        onExited: Qt.callLater(root.refresh)
    }

    Process {
        id: sunsetRunner
        property var actionCmd: ["true"]
        command: actionCmd
    }

    function setWifiEnabled(enabled) {
        if (enabled) { root.airplaneMode = false; root.wifiEnabled = true; root.runAction("wifi_on") }
        else { root.wifiEnabled = false; root.wifiNetwork = ""; root.runAction("wifi_off") }
    }

    function setAirplaneMode(enabled) {
        root.airplaneMode = enabled
        if (enabled) {
            root.wifiEnabled = false; root.wifiNetwork = ""
            if (root.btAdapter) root.btAdapter.enabled = false
            root.runAction("airplane_on")
        } else { root.runAction("airplane_off") }
    }

    function setDndMode(enabled) { root.dndMode = enabled }
    function setNightMode(enabled) {
        root.nightMode = enabled
        sunsetRunner.actionCmd = enabled ? ["bash", "-c", "wlsunset -t 5000 -T 6500"] : ["pkill", "wlsunset"]
        sunsetRunner.running = false
        sunsetRunner.running = true
    }

    function runAction(type, value) {
        actionRunner.actionType = type
        actionRunner.actionValue = value ?? ""
        actionRunner.running = false
        actionRunner.running = true
    }

    Connections {
        target: Theme
        function onThemeUpdated() { Qt.callLater(root.refresh) }
    }

    Component.onCompleted: Qt.callLater(root.refresh)
}
