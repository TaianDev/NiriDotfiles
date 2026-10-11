pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: root
    visible: false

    readonly property int maxEntries: 50

    property var entries: []
    property bool loaded: false
    property string signature: ""
    readonly property bool ready: AppPaths.homeDir !== ""

    readonly property string stateDir: AppPaths.homeDir !== ""
        ? AppPaths.homeDir + "/.local/state/quickshell/clipboard"
        : ""
    readonly property string storePath: stateDir !== "" ? stateDir + "/history.json" : ""
    readonly property string scriptPath: AppPaths.homeDir !== ""
        ? AppPaths.homeDir + "/.config/quickshell/scripts/clipboard-record.sh"
        : ""

    // ── History persistence ──────────────────────────────────────────────

    function parse(text) {
        if (typeof text !== "string" || text.trim() === "")
            return

        let data = null
        try {
            data = JSON.parse(text)
        } catch (e) {
            return
        }

        let list = []
        if (data && Array.isArray(data.entries))
            list = data.entries
        else if (Array.isArray(data))
            list = data

        const cleaned = list.filter(e => e && e.type && e.hash && e.file)
        const sig = cleaned.map(e => e.hash).join("|")
        if (sig === root.signature) {
            root.loaded = true
            return
        }
        root.signature = sig
        root.entries = cleaned
        root.loaded = true
    }

    function persist() {
        if (root.storePath !== "")
            historyFile.setText(JSON.stringify({ entries: root.entries }))
    }

    function addLine(line) {
        const trimmed = String(line ?? "").trim()
        if (trimmed === "")
            return

        let entry = null
        try {
            entry = JSON.parse(trimmed)
        } catch (e) {
            return
        }
        if (!entry || !entry.type || !entry.hash)
            return
        root.add(entry)
    }

    function add(entry) {
        const next = root.entries.filter(e => e.hash !== entry.hash)
        next.unshift(entry)
        while (next.length > root.maxEntries)
            root.removeFile(next.pop())
        root.signature = next.map(e => e.hash).join("|")
        root.entries = next
        root.persist()
    }

    function removeAt(index) {
        if (index < 0 || index >= root.entries.length)
            return
        const next = root.entries.slice()
        const removed = next.splice(index, 1)[0]
        root.removeFile(removed)
        root.signature = next.map(e => e.hash).join("|")
        root.entries = next
        root.persist()
    }

    function removeByHash(hash) {
        if (!hash)
            return
        const index = root.entries.findIndex(e => e.hash === hash)
        if (index >= 0)
            root.removeAt(index)
    }

    function clear() {
        for (let i = 0; i < root.entries.length; i++)
            root.removeFile(root.entries[i])
        root.signature = ""
        root.entries = []
        root.persist()
    }

    function removeFile(entry) {
        if (entry && entry.file)
            Quickshell.execDetached(["rm", "-f", "--", entry.file])
    }

    // ── Copy back to the Wayland clipboard ───────────────────────────────

    function copyEntry(entry) {
        if (!entry || !entry.file)
            return
        if (entry.type === "image" && entry.mime)
            Quickshell.execDetached(["bash", "-c",
                "exec wl-copy --type \"$1\" < \"$2\"", "_", entry.mime, entry.file])
        else
            Quickshell.execDetached(["bash", "-c",
                "exec wl-copy --type text/plain < \"$1\"", "_", entry.file])
    }

    // ── Clipboard monitoring (wl-clipboard) ──────────────────────────────

    property bool watchAllowed: false

    Process {
        id: watcher
        command: root.scriptPath !== "" ? ["wl-paste", "--watch", root.scriptPath] : []
        stdout: SplitParser {
            onRead: line => root.addLine(line)
        }
        onExited: restartTimer.restart()
    }

    // Mata los watchers obsoletos de ejecuciones anteriores: al reiniciar
    // quickshell matando el proceso, los hijos `wl-paste --watch` quedan
    // huérfanos. `pkill` nunca se señala a sí mismo, así que es seguro.
    Process {
        id: staleCleanup
        command: root.scriptPath !== "" ? ["pkill", "-f", "wl-paste --watch .*clipboard-record"] : []
        onExited: {
            root.watchAllowed = true
            if (root.ready && root.scriptPath !== "")
                watcher.running = true
        }
    }

    Process {
        id: seeder
        command: root.scriptPath !== "" ? [root.scriptPath] : []
        stdout: SplitParser {
            onRead: line => root.addLine(line)
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.ready && root.watchAllowed && root.scriptPath !== "")
                watcher.running = true
        }
    }

    onReadyChanged: {
        if (root.ready) {
            seeder.running = true
            staleCleanup.running = true
        }
    }

    Component.onCompleted: {
        if (root.ready) {
            seeder.running = true
            staleCleanup.running = true
        }
    }

    FileView {
        id: historyFile
        path: root.storePath
        printErrors: false
        onLoaded: root.parse(historyFile.text())
        onLoadFailed: root.loaded = true
    }
}
