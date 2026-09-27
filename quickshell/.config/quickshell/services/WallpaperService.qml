import QtQuick
import Quickshell.Io

Item {
    id: service
    visible: false

    signal applied(string path)
    signal failed(string path, int exitCode)

    property string wallpaperPath: ""
    property string lastError: ""

    readonly property string applyScript: {
        const url = Qt.resolvedUrl("../scripts/apply_wallpaper.sh").toString()
        return url.startsWith("file://") ? url.slice(7) : url
    }

    Process {
        id: applyProc
        property string path: ""
        command: ["bash", service.applyScript, path]

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
        wallpaperPath = path
        applyProc.path = path
        applyProc.running = false
        applyProc.running = true
    }
}
