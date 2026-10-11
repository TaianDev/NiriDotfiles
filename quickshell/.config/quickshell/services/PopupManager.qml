pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    readonly property string dateId: "date"
    readonly property string musicId: "music"
    readonly property string trayId: "tray"
    readonly property string networkId: "network"
    readonly property string notificationsId: "notifications"
    readonly property string launcherId: "launcher"
    readonly property string assistantId: "assistant"
    property string activeId: ""

    signal closeRequested(string id)

    readonly property bool hasOpen: activeId !== ""

    IpcHandler {
        target: "bar_popup"
        function close(): void {
            root.closeActive()
        }
    }

    // niri does not allow injecting binds at runtime (hyprctl keyword).
    // Escape-to-close is handled by PopupEscCapture (Shortcut) while the
    // popup has keyboard focus; Super+Escape remains as a guaranteed close.
    function openExclusive(id) {
        if (id === "")
            return

        if (activeId !== "" && activeId !== id)
            root.closeRequested(activeId)

        root.activeId = id
    }

    function notifyClosed(id) {
        if (root.activeId === id)
            root.activeId = ""
    }

    function closeActive() {
        if (root.activeId === "")
            return
        root.closeRequested(root.activeId)
    }

    function requestOpen(id) {
        root.openExclusive(id)
    }

    function requestClose(id) {
        if (root.activeId === id)
            root.closeRequested(id)
    }
}
