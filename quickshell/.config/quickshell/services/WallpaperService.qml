import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

// WallpaperService — aplica el fondo y genera el tema (pywal + matugen + awww).
// Guarda los parámetros (esquema/modo/contraste/transición) en wallpaper.json.
Item {
    id: service
    visible: false

    signal applied(string path)
    signal failed(string path, int exitCode)

    property string wallpaperPath: ""
    property string lastError: ""

    // ── Parámetros (matugen / awww) ──
    property string scheme: "scheme-tonal-spot"
    property string mode: "dark"
    property real contrast: 0
    property int sourceIndex: 0
    property string transition: "wave"

    property bool _loaded: false

    readonly property string storePath: AppPaths.homeDir + "/.config/quickshell/wallpaper.json"

    readonly property string applyScript: {
        const url = Qt.resolvedUrl("../scripts/apply_wallpaper.sh").toString()
        return url.startsWith("file://") ? url.slice(7) : url
    }

    FileView {
        id: store
        preload: true
        atomicWrites: true
        printErrors: true
        onLoaded: {
            const txt = store.text().trim()
            if (txt !== "") {
                try {
                    const p = JSON.parse(txt)
                    if (typeof p.scheme === "string" && p.scheme !== "") service.scheme = p.scheme
                    if (typeof p.mode === "string" && p.mode !== "") service.mode = p.mode
                    if (typeof p.contrast === "number") service.contrast = p.contrast
                    if (typeof p.sourceIndex === "number") service.sourceIndex = p.sourceIndex
                    if (typeof p.transition === "string" && p.transition !== "") service.transition = p.transition
                } catch (e) {
                    console.warn("wallpaper: failed to parse wallpaper.json", e)
                }
            }
            service._loaded = true
        }
        onLoadFailed: if (AppPaths.homeDir !== "") service._loaded = true
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() { service.load() }
    }

    Timer {
        interval: 450
        running: true
        repeat: false
        onTriggered: service.load()
    }

    function load() {
        if (AppPaths.homeDir === "") return
        store.path = service.storePath
    }

    function save() {
        if (!service._loaded) return
        store.setText(JSON.stringify({
            scheme: service.scheme,
            mode: service.mode,
            contrast: service.contrast,
            sourceIndex: service.sourceIndex,
            transition: service.transition
        }, null, 2))
    }

    Process {
        id: applyProc
        property string path: ""
        command: ["bash", service.applyScript, path,
            "--scheme", service.scheme,
            "--mode", service.mode,
            "--contrast", String(service.contrast),
            "--source-index", String(service.sourceIndex),
            "--transition", service.transition]

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const text = this.text.trim()
                if (text !== "")
                    service.lastError = text
            }
        }

        onExited: (code) => {
            if (code !== 0) {
                console.warn(`[WallpaperService] apply_wallpaper.sh failed (${code}): ${service.lastError}`)
                service.failed(service.wallpaperPath, code)
            } else {
                service.lastError = ""
                service.applied(service.wallpaperPath)
            }
        }
    }

    function apply(path) {
        service.save()
        wallpaperPath = path
        applyProc.path = path
        applyProc.running = false
        applyProc.running = true
    }
}
