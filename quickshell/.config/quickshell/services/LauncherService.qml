pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    readonly property int modeApps: 0
    readonly property int modeWallpapers: 1
    readonly property int modeWeb: 2

    property int mode: modeApps
    property string query: ""
    property bool isOpened: false

    function modeFromName(name) {
        const n = String(name ?? "").toLowerCase()
        if (n === "wallpapers" || n === "wallpaper" || n === "theme" || n === "1")
            return modeWallpapers
        if (n === "web" || n === "search" || n === "2")
            return modeWeb
        return modeApps
    }

    function setMode(m) {
        if (root.mode === m)
            return
        root.mode = m
        root.query = ""
    }

    function cycleMode(delta) {
        root.setMode((root.mode + delta + 3) % 3)
    }

    function open(m) {
        if (m !== undefined && m !== null)
            root.mode = m
        PopupManager.openExclusive(PopupManager.launcherId)
        Qt.callLater(() => { root.isOpened = true })
    }

    function toggle(m) {
        if (root.isOpened && (m === undefined || m === null || m === root.mode)) {
            root.close()
            return
        }
        root.open(m)
    }

    function close() {
        root.isOpened = false
    }

    onIsOpenedChanged: {
        if (!root.isOpened)
            PopupManager.notifyClosed(PopupManager.launcherId)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.launcherId)
                root.isOpened = false
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(mode: string): void { root.toggle(root.modeFromName(mode)) }
        function open(mode: string): void { root.open(root.modeFromName(mode)) }
        function close(): void { root.close() }
    }

    IpcHandler {
        target: "app_launcher"
        function toggle(): void { root.toggle(root.modeApps) }
    }

    IpcHandler {
        target: "theme_panel"
        function toggle(): void { root.toggle(root.modeWallpapers) }
    }
}
