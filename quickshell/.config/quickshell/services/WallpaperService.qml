import QtQuick
import Quickshell.Io

Item {
    id: service
    visible: false

    signal applied(string path)

    property string wallpaperPath: ""

    readonly property string applyScript: {
        const url = Qt.resolvedUrl("../scripts/apply_wallpaper.sh").toString()
        return url.startsWith("file://") ? url.slice(7) : url
    }

    Process {
        id: applyProc
        property string path: ""
        command: ["bash", service.applyScript, path]
        onExited: service.applied(service.wallpaperPath)
    }

    function apply(path) {
        wallpaperPath = path
        applyProc.path = path
        applyProc.running = false
        applyProc.running = true
    }
}
