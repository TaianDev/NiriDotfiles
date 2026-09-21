pragma Singleton
import QtQuick
import Quickshell.Io
import "../core"

Item {
    id: root
    visible: false

    property var counts: ({})
    property bool loaded: false

    readonly property string storePath: AppPaths.homeDir !== ""
        ? AppPaths.homeDir + "/.config/quickshell/launcher_usage.json"
        : ""

    function parse(text) {
        try {
            const data = JSON.parse(text)
            root.counts = (data && typeof data === "object") ? data : ({})
        } catch (e) {
            root.counts = ({})
        }
        root.loaded = true
    }

    function score(id) {
        return (id && root.counts[id]) ? root.counts[id] : 0
    }

    function bump(id) {
        if (!id)
            return
        const next = Object.assign({}, root.counts)
        next[id] = (next[id] || 0) + 1
        root.counts = next
        if (root.storePath !== "")
            usageFile.setText(JSON.stringify(root.counts))
    }

    FileView {
        id: usageFile
        path: root.storePath
        printErrors: false
        onLoaded: root.parse(usageFile.text())
        onLoadFailed: {
            root.counts = ({})
            root.loaded = true
        }
    }
}
