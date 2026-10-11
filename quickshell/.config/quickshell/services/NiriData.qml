pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils"

// ============================================================================
// NiriData — niri compositor state via IPC (event-stream)
// ============================================================================
// Replaces HyprlandData. Connects to the niri socket ($NIRI_SOCKET),
// requests the event-stream and keeps workspaces/windows/outputs/keyboard layout
// in real time. Actions are sent with `niri msg action`.
//
// The event-stream delivers the full state on connect, so polling is not needed.
// See: https://niri-wm.github.io/niri/IPC.html

Item {
    id: root
    visible: false

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""

    // ========================================================================
    // State
    // ========================================================================
    property var workspaces: []
    property var windows: []
    property var outputs: ({})
    property bool inOverview: false
    property var keyboardLayoutNames: []
    property int currentKeyboardLayoutIndex: 0
    property bool connected: false

    // ========================================================================
    // Derived
    // ========================================================================
    readonly property var focusedWorkspace: {
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].is_focused)
                return workspaces[i]
        }
        return null
    }

    readonly property string focusedOutput: focusedWorkspace?.output ?? ""

    // Last known focused output. niri may report no focused workspace briefly
    // (notably right after resuming from suspend); keeping the previous value
    // stops date/network popups from opening on every monitor at once.
    property string lastFocusedOutput: ""
    onFocusedOutputChanged: {
        if (root.focusedOutput !== "")
            root.lastFocusedOutput = root.focusedOutput
    }
    readonly property string activeOutput: focusedOutput !== "" ? focusedOutput : lastFocusedOutput

    readonly property var focusedWindow: {
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].is_focused)
                return windows[i]
        }
        return null
    }

    readonly property string currentKeyboardLayout: {
        if (currentKeyboardLayoutIndex >= 0 && currentKeyboardLayoutIndex < keyboardLayoutNames.length)
            return keyboardLayoutNames[currentKeyboardLayoutIndex]
        return ""
    }

    // Only numeric workspaces ("1".."10"): hides the empty workspace that
    // niri keeps at the end of each monitor and any unnamed workspace.
    // Sorted by number so the bar always shows 1-5 / 6-10.
    function workspacesForOutput(outputName) {
        return workspaces
            .filter(ws => ws.output === outputName && /^\d+$/.test(ws.name ?? ""))
            .sort((a, b) => parseInt(a.name, 10) - parseInt(b.name, 10))
    }

    function allWorkspacesForOutput(outputName) {
        return workspaces
            .filter(ws => ws.output === outputName)
            .sort((a, b) => a.idx - b.idx)
    }

    function windowsForWorkspace(workspaceId) {
        return windows.filter(win => win.workspace_id === workspaceId)
    }

    function iconsForWorkspace(workspaceId) {
        return windowsForWorkspace(workspaceId)
            .map(win => IconResolver.iconForWindow(win))
            .filter(path => path !== "")
    }

    function iconForWindow(win) { return IconResolver.iconForWindow(win) }

    // ========================================================================
    // Event stream
    // ========================================================================
    Socket {
        id: eventSocket
        path: root.socketPath

        onConnectionStateChanged: {
            root.connected = eventSocket.connected
            if (eventSocket.connected) {
                eventSocket.write("\"EventStream\"\n")
                eventSocket.flush()
            }
        }

        onError: error => console.warn("[NiriData] socket error:", error)

        parser: SplitParser {
            onRead: line => root.handleEvent(line)
        }
    }

    // Request socket (raw JSON actions). Needed to refer to workspaces by
    // Id/Name without the index/name ambiguity of the CLI.
    Socket {
        id: requestSocket
        path: root.socketPath

        onError: error => console.warn("[NiriData] request socket error:", error)

        // We consume the responses ("Handled"/"Ok"/"Err") so they do not pile up.
        parser: SplitParser {
            onRead: line => {}
        }
    }

    // Reconnection: if niri restarts, the sockets drop and must be reconnected.
    Timer {
        interval: 3000
        repeat: true
        running: root.socketPath !== "" && (!eventSocket.connected || !requestSocket.connected)
        onTriggered: {
            if (!eventSocket.connected)
                eventSocket.connected = true
            if (!requestSocket.connected)
                requestSocket.connected = true
        }
    }

    Component.onCompleted: {
        if (root.socketPath !== "") {
            eventSocket.connected = true
            requestSocket.connected = true
        }
    }

    function handleEvent(line) {
        if (!line || line.trim() === "")
            return
        let event
        try {
            event = JSON.parse(line)
        } catch (e) {
            console.warn("[NiriData] parse error:", e, line)
            return
        }

        const type = Object.keys(event)[0]
        const data = event[type]

        switch (type) {
        case "WorkspacesChanged":
            root.workspaces = data.workspaces ?? []
            break
        case "WorkspaceUrgencyChanged":
            root.updateWorkspace(data.id, { is_urgent: data.urgent })
            break
        case "WorkspaceActivated":
            root.handleWorkspaceActivated(data)
            break
        case "WorkspaceActiveWindowChanged":
            root.updateWorkspace(data.workspace_id, { active_window_id: data.active_window_id })
            break
        case "WindowsChanged":
            root.windows = data.windows ?? []
            break
        case "WindowOpenedOrChanged":
            root.upsertWindow(data.window)
            break
        case "WindowClosed":
            root.windows = root.windows.filter(win => win.id !== data.id)
            break
        case "WindowFocusChanged":
            root.handleWindowFocusChanged(data.id)
            break
        case "WindowUrgencyChanged":
            root.updateWindow(data.id, { is_urgent: data.urgent })
            break
        case "WindowLayoutsChanged":
            root.handleWindowLayoutsChanged(data.changes)
            break
        case "KeyboardLayoutsChanged":
            root.keyboardLayoutNames = data.keyboard_layouts?.names ?? []
            root.currentKeyboardLayoutIndex = data.keyboard_layouts?.current_idx ?? 0
            break
        case "KeyboardLayoutSwitched":
            root.currentKeyboardLayoutIndex = data.idx
            break
        case "OverviewOpenedOrClosed":
            root.inOverview = data.is_open
            break
        case "OutputsChanged":
            root.outputs = data.outputs ?? ({})
            break
        case "ConfigLoaded":
            if (data.failed)
                console.warn("[NiriData] niri config failed to load")
            break
        default:
            break
        }
    }

    // ========================================================================
    // State mutators
    // ========================================================================
    function updateWorkspace(id, changes) {
        const idx = root.workspaces.findIndex(ws => ws.id === id)
        if (idx < 0)
            return
        const ws = root.workspaces[idx]
        const keys = Object.keys(changes)
        if (keys.every(k => ws[k] === changes[k]))
            return
        const next = root.workspaces.slice()
        next[idx] = Object.assign({}, ws, changes)
        root.workspaces = next
    }

    function updateWindow(id, changes) {
        const idx = root.windows.findIndex(win => win.id === id)
        if (idx < 0)
            return
        const win = root.windows[idx]
        const keys = Object.keys(changes)
        if (keys.every(k => win[k] === changes[k]))
            return
        const next = root.windows.slice()
        next[idx] = Object.assign({}, win, changes)
        root.windows = next
    }

    function upsertWindow(win) {
        if (!win)
            return
        const idx = root.windows.findIndex(w => w.id === win.id)
        const next = root.windows.slice()
        if (idx >= 0)
            next[idx] = win
        else
            next.push(win)
        root.windows = next
    }

    function handleWorkspaceActivated(data) {
        const target = root.workspaces.find(ws => ws.id === data.id)
        if (!target)
            return
        const output = target.output
        root.workspaces = root.workspaces.map(ws => {
            let updated = ws
            // is_active es por output.
            if (ws.output === output)
                updated = Object.assign({}, updated, { is_active: ws.id === data.id })
            // is_focused es global: al enfocar un workspace hay que limpiar el
            // flag en TODOS los demás (si no, focusedOutput puede devolver el
            // workspace enfocado de otro monitor).
            if (data.focused)
                updated = Object.assign({}, updated, { is_focused: ws.id === data.id })
            return updated
        })
    }

    function handleWindowFocusChanged(focusedId) {
        let changed = false
        const next = root.windows.map(win => {
            const isFocused = win.id === focusedId
            if (win.is_focused === isFocused)
                return win
            changed = true
            return Object.assign({}, win, { is_focused: isFocused })
        })
        if (changed)
            root.windows = next
    }

    function handleWindowLayoutsChanged(changes) {
        if (!changes)
            return
        const map = {}
        for (const change of changes)
            map[change[0]] = change[1]
        root.windows = root.windows.map(win => {
            if (!(win.id in map))
                return win
            return Object.assign({}, win, { layout: map[win.id] })
        })
    }

    // ========================================================================
    // Actions (niri msg action)
    // ========================================================================
    Process {
        id: actionProc
        command: ["true"]
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("[NiriData] action failed, exit code:", exitCode)
        }
    }

    function runAction(args) {
        actionProc.command = ["niri", "msg", "action"].concat(args)
        actionProc.running = false
        actionProc.running = true
    }

    function sendRequest(request) {
        if (!requestSocket.connected) {
            console.warn("[NiriData] request socket no conectado")
            return
        }
        requestSocket.write(JSON.stringify(request) + "\n")
        requestSocket.flush()
    }

    // IMPORTANT: `niri msg action focus-workspace 1` treats the number as an
    // INDEX, not as a name. For numerically named workspaces ("1".."10")
    // the raw JSON request is sent by Id (unique and stable).
    function focusWorkspaceById(id) {
        if (id === undefined || id === null)
            return
        root.sendRequest({ "Action": { "FocusWorkspace": { "reference": { "Id": id } } } })
    }

    function focusWorkspaceByName(name) {
        if (!name)
            return
        root.sendRequest({ "Action": { "FocusWorkspace": { "reference": { "Name": name } } } })
    }

    // Compatibility: by name (avoid numeric names if the CLI is used).
    function focusWorkspace(reference) {
        if (reference === undefined || reference === null)
            return
        root.focusWorkspaceByName(String(reference))
    }

    function focusOutput(name) {
        if (!name)
            return
        root.runAction(["focus-monitor", String(name)])
    }

    function closeFocusedWindow() { root.runAction(["close-window"]) }
    function toggleFloating() { root.runAction(["toggle-window-floating"]) }
    function quit() { root.runAction(["quit"]) }
    function switchLayoutNext() { root.runAction(["switch-layout", "next"]) }
    function switchLayoutPrev() { root.runAction(["switch-layout", "prev"]) }
}
