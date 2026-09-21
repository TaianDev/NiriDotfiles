pragma Singleton

import QtQuick
import Quickshell.Io
import "../core"

Item {
    id: root
    visible: false

    signal updated()

    property int cpuUsage: 0
    property int ramUsage: 0
    property int tempValue: 0
    property int _lastTotal: 0
    property int _lastIdle: 0

    property int capacity: 0
    property string status: "Unknown"
    property bool acOnline: false

    property string netInterface: ""
    property real rxSpeed: 0
    property real txSpeed: 0
    property real _lastRx: 0
    property real _lastTx: 0

    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: netFile
        path: "/proc/net/dev"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT0/capacity"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: acFile
        path: "/sys/class/power_supply/ADP1/online"
        blockLoading: true
        watchChanges: false
    }

    function refresh() {
        memFile.reload()
        cpuFile.reload()
        tempFile.reload()
        netFile.reload()
        capacityFile.reload()
        statusFile.reload()
        acFile.reload()
        applyReadings()
    }

    function applyReadings() {
        const memLines = memFile.text().split('\n')
        var memTotal = 1, memAvail = 0
        for (var i = 0; i < memLines.length; i++) {
            const l = memLines[i]
            if (l.startsWith("MemTotal:"))
                memTotal = parseInt(l.replace(/[^0-9]/g, ''))
            else if (l.startsWith("MemAvailable:"))
                memAvail = parseInt(l.replace(/[^0-9]/g, ''))
        }
        root.ramUsage = Math.round(((memTotal - memAvail) / memTotal) * 100)

        const cpuLine = cpuFile.text().split('\n')[0]
        const parts = cpuLine.match(/\d+/g)
        if (parts && parts.length >= 4) {
            const idle = parseInt(parts[3])
            var total = 0
            for (var j = 0; j < parts.length; j++) total += parseInt(parts[j])
            if (root._lastTotal > 0) {
                const diffIdle = idle - root._lastIdle
                const diffTotal = total - root._lastTotal
                root.cpuUsage = diffTotal > 0
                    ? Math.round((1 - diffIdle / diffTotal) * 100)
                    : 0
            }
            root._lastTotal = total
            root._lastIdle = idle
        }

        const tempRaw = tempFile.text().trim()
        if (tempRaw.length > 0)
            root.tempValue = Math.round(parseInt(tempRaw) / 1000)

        const cap = parseInt(capacityFile.text().trim(), 10)
        if (!isNaN(cap))
            root.capacity = Math.max(0, Math.min(100, cap))
        const st = statusFile.text().trim()
        if (st.length > 0)
            root.status = st
        const ac = acFile.text().trim()
        root.acOnline = ac === "1"

        const netLines = netFile.text().split('\n')
        if (root.netInterface === "") {
            for (let i = 2; i < netLines.length; i++) {
                const iface = netLines[i].trim().split(':')[0].trim()
                if (iface.startsWith('w')) { root.netInterface = iface; break }
            }
        }
        if (root.netInterface !== "") {
            for (let i = 2; i < netLines.length; i++) {
                const netParts = netLines[i].trim().split(/\s+/)
                if (netParts[0] === root.netInterface + ":") {
                    const rx = parseFloat(netParts[1])
                    const tx = parseFloat(netParts[9])
                    if (root._lastRx > 0) {
                        root.rxSpeed = Math.max(0, (rx - root._lastRx) / 2)
                        root.txSpeed = Math.max(0, (tx - root._lastTx) / 2)
                    }
                    root._lastRx = rx
                    root._lastTx = tx
                    break
                }
            }
        }

        root.updated()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
