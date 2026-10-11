pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// PrivacyService — quién está capturando audio (micrófono) o vídeo (cámara).
// Micrófono: `pw-dump | jq` (Stream/Input/Audio). Cámara: `fuser /dev/video*`.
// Solo mientras el hub está abierto.
Item {
    id: root
    visible: false

    property bool active: false
    property var audio: []   // [{ name, pid, binary }]  (micrófono)
    property var video: []   // [{ name, pid, binary }]  (cámara)

    function refresh() {
        if (!root.active)
            return
        if (!audioScanner.running) {
            audioScanner.running = false
            audioScanner.running = true
        }
        if (!videoScanner.running) {
            videoScanner.running = false
            videoScanner.running = true
        }
    }

    function parseAudio(text) {
        let list = []
        try {
            list = JSON.parse(text)
        } catch (e) {
            return
        }
        if (!Array.isArray(list))
            list = []

        const a = []
        const seen = {}
        for (let i = 0; i < list.length; i++) {
            const it = list[i]
            const pid = parseInt(it.pid, 10) || 0
            const name = it.name && it.name !== "" ? it.name : "Unknown"
            const binary = it.binary ?? ""
            const key = (name + "|" + binary).toLowerCase()
            if (!seen[key]) {
                seen[key] = true
                a.push({ name: name, pid: pid, binary: binary })
            }
        }
        root.audio = a
    }

    function parseVideo(text) {
        const v = []
        const seen = {}
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("|")
            if (parts.length < 2)
                continue
            const pid = parseInt(parts[0], 10) || 0
            const name = parts[1] !== "" ? parts[1] : "Unknown"
            const binary = parts[2] ?? ""
            if (pid <= 0)
                continue
            if (seen[pid])
                continue
            seen[pid] = true
            v.push({ name: name, pid: pid, binary: binary })
        }
        root.video = v
    }

    function killPid(pid) {
        const p = parseInt(pid, 10)
        if (!p || p <= 1)
            return
        Quickshell.execDetached(["kill", String(p)])
    }

    Process {
        id: audioScanner
        // Excluye capturas del sink (p. ej. cava) para no marcarlas como micrófono.
        command: ["bash", "-c",
            "pw-dump | jq -c '[.[] " +
            "| select(((.info.props[\"media.class\"] // \"\") == \"Stream/Input/Audio\")) " +
            "| select(((.info.props[\"stream.capture.sink\"] // false) | tostring) != \"true\") " +
            "| {name: (.info.props[\"application.name\"] // .info.props[\"node.name\"] // \"Unknown\"), " +
            "binary: (.info.props[\"application.process.binary\"] // \"\"), " +
            "pid: (.info.props[\"application.process.id\"] // 0)}]'"]
        stdout: StdioCollector {
            onStreamFinished: root.parseAudio(this.text)
        }
    }

    Process {
        id: videoScanner
        // Cámara: `fuser /dev/video*` (PIDs) + nombre/exe vía /proc. Mucho más
        // ligero que pw-dump para el caso de vídeo.
        command: ["bash", "-c",
            "for p in $(fuser /dev/video* 2>/dev/null); do " +
            "exe=$(readlink -f /proc/$p/exe 2>/dev/null); " +
            "name=$(cat /proc/$p/comm 2>/dev/null); " +
            "[ -n \"$name\" ] && printf '%s|%s|%s\\n' \"$p\" \"$name\" \"$exe\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.parseVideo(this.text)
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onActiveChanged: {
        if (root.active) {
            root.refresh()
        } else {
            root.audio = []
            root.video = []
        }
    }
}
