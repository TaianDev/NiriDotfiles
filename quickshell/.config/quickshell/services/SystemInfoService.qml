pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

// SystemInfoService — datos tipo fastfetch para la sección Home del hub.
// Estático (una vez): distro, kernel, cpu, gpu, terminal, usuario, avatar.
// Dinámico: uptime y almacenamiento disponible.
Item {
    id: root
    visible: false

    // ── Estático ──
    property string distro: ""
    property string kernel: ""
    property string cpu: ""
    property string gpu: ""
    property string terminal: "kitty"
    property string user: Quickshell.env("USER") ?? ""
    property string avatarPath: ""

    // ── Dinámico ──
    property string osAge: ""
    property string uptime: ""
    property string diskFree: ""

    readonly property string avatarSource: root.avatarPath !== ""
        ? "file://" + root.avatarPath
        : AppPaths.iconsDir + "user.svg"

    function parseUptime(text) {
        const secs = Math.floor(parseFloat(text))
        if (isNaN(secs) || secs <= 0)
            return ""
        const d = Math.floor(secs / 86400)
        const h = Math.floor((secs % 86400) / 3600)
        const m = Math.floor((secs % 3600) / 60)
        if (d > 0) return d + "d " + h + "h " + m + "m"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function parseOsAge(birth) {
        const b = parseInt(String(birth).trim(), 10)
        if (isNaN(b) || b <= 0)
            return ""
        const days = Math.floor((Date.now() / 1000 - b) / 86400)
        if (days < 1) return "today"
        if (days < 30) return days + "d"
        const months = Math.floor(days / 30)
        if (months < 12) return months + "mo"
        return Math.floor(months / 12) + "y " + (months % 12) + "mo"
    }

    function refreshDynamic() {
        uptimeReader.running = false
        uptimeReader.running = true
        diskReader.running = false
        diskReader.running = true
    }

    Process {
        id: distroProc
        command: ["bash", "-c", "grep -m1 '^PRETTY_NAME' /etc/os-release | cut -d= -f2- | tr -d '\"'"]
        stdout: StdioCollector { onStreamFinished: root.distro = this.text.trim() }
        Component.onCompleted: running = true
    }
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: root.kernel = this.text.trim() }
        Component.onCompleted: running = true
    }
    Process {
        id: cpuProc
        command: ["bash", "-c", "lscpu | sed -n 's/^Model name: *//p' | head -1 | sed 's/ @.*//'"]
        stdout: StdioCollector { onStreamFinished: root.cpu = this.text.trim() }
        Component.onCompleted: running = true
    }
    Process {
        id: gpuProc
        command: ["bash", "-c",
            "s=\"$(lspci | grep -iE 'vga|3d|display' | sed 's/.*: //' | head -1)\"; " +
            "if [[ \"$s\" == *\"[\"* ]]; then s=\"${s#*[}\"; s=\"${s%]*}\"; " +
            "else s=\"${s#Intel Corporation }\"; s=\"${s% (rev*}\"; fi; printf '%s' \"$s\""]
        stdout: StdioCollector { onStreamFinished: root.gpu = this.text.trim() }
        Component.onCompleted: running = true
    }
    Process {
        id: avatarProc
        command: ["bash", "-c",
            "for f in \"$HOME/.face\" \"$HOME/.face.icon\"; do [ -f \"$f\" ] && printf %s \"$f\" && break; done"]
        stdout: StdioCollector { onStreamFinished: root.avatarPath = this.text.trim() }
        Component.onCompleted: running = true
    }
    Process {
        id: osAgeProc
        command: ["bash", "-c", "stat -c %W /"]
        stdout: StdioCollector { onStreamFinished: root.osAge = root.parseOsAge(this.text) }
        Component.onCompleted: running = true
    }

    Process {
        id: uptimeReader
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.uptime = root.parseUptime(this.text.split(" ")[0]) }
    }
    Process {
        id: diskReader
        command: ["bash", "-c", "df -h --output=avail / | tail -1 | tr -d ' '"]
        stdout: StdioCollector { onStreamFinished: root.diskFree = this.text.trim() }
    }

    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refreshDynamic()
    }

    Component.onCompleted: root.refreshDynamic()
}
