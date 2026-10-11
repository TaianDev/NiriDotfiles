pragma Singleton

import QtQuick
import Quickshell.Io

// HubService — estado/`IPC` del menú unificado (Home/Date/Task).
// Los popups de red/música/date dejan de abrir su propia ventana y piden el hub.
Item {
    id: root
    visible: false

    readonly property string id: "hub"
    property int section: 0
    property int dateTab: 0
    property bool opened: false

    signal openRequested(int section, var anchorItem)
    signal closeRequested()

    function sectionFromName(name) {
        const n = String(name ?? "").toLowerCase()
        if (n === "date" || n === "1") return 1
        if (n === "task" || n === "tasks" || n === "notes" || n === "2") return 2
        return 0
    }

    function open(section, anchorItem) {
        PopupManager.openExclusive(root.id)
        root.section = section
        root.openRequested(section, anchorItem ?? null)
        root.opened = true
    }

    function toggle(section, anchorItem) {
        if (root.opened && root.section === section) {
            root.close()
        } else {
            root.open(section, anchorItem ?? null)
        }
    }

    function close() {
        if (!root.opened)
            return
        root.opened = false
        root.closeRequested()
        PopupManager.notifyClosed(root.id)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === root.id && root.opened) {
                root.opened = false
                root.closeRequested()
            }
        }
    }

    IpcHandler {
        target: "hub"
        function toggle(section: string): void { HubService.toggle(HubService.sectionFromName(section), null) }
        function open(section: string): void { HubService.open(HubService.sectionFromName(section), null) }
        function close(): void { HubService.close() }
    }

    IpcHandler {
        target: "task_popup"
        function toggle(): void { HubService.toggle(2, null) }
    }
}
