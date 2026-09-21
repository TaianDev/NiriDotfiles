pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../core"
import "../utils"

Item {
    id: root
    visible: false

    signal listChanged()
    signal popupHideRequested(var notif)

    property bool panelOpen: false
    property int unreadCount: 0
    property int listVersion: 0
    property int popupVersion: 0
    property var timestamps: ({})
    property var popups: []
    property int maxPopups: 5
    property int defaultPopupMs: 7000

    readonly property var notifications: notifServer.trackedNotifications
    readonly property int count: notifications?.values?.length ?? 0

    Process {
        id: alarmNotifier
        property var onSnooze: null
        property var onDismiss: null
        stdout: StdioCollector {
            onStreamFinished: {
                const res = this.text.trim()
                if (res === "snooze" && alarmNotifier.onSnooze) alarmNotifier.onSnooze()
                else if (res === "dismiss" && alarmNotifier.onDismiss) alarmNotifier.onDismiss()
                else if (alarmNotifier.onDismiss) alarmNotifier.onDismiss()
                alarmNotifier.onSnooze = null
                alarmNotifier.onDismiss = null
            }
        }
    }

    IpcHandler {
        target: "notifications_panel"
        function toggle(): void { root.togglePanel() }
    }

    function createAlarmNotification(summary, body, onSnooze, onDismiss) {
        const args = ["notify-send", "-u", "critical", "-a", "Alarm",
            "-i", AppPaths.iconsDir + "alarm-clock.svg",
            "-A", "snooze=Snooze 10m", "-A", "dismiss=Dismiss"]
        if (body && body !== "") args.push(body)
        args.push(summary ?? "Alarm")
        alarmNotifier.onSnooze = onSnooze
        alarmNotifier.onDismiss = onDismiss
        alarmNotifier.command = args
        alarmNotifier.running = true
    }

    function togglePanel() {
        root.panelOpen ? root.closePanel() : root.openPanel()
    }

    function openPanel() {
        PopupManager.openExclusive(PopupManager.notificationsId)
        Qt.callLater(() => { root.panelOpen = true; root.unreadCount = 0 })
    }

    function closePanel() { root.panelOpen = false }

    onPanelOpenChanged: {
        if (!root.panelOpen) PopupManager.notifyClosed(PopupManager.notificationsId)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.notificationsId) root.panelOpen = false
        }
    }

    function dismiss(notif) { if (notif) notif.dismiss() }

    function dismissAll() {
        const list = root.notifications.values.slice()
        for (let i = 0; i < list.length; i++) list[i].dismiss()
    }

    function invokeAction(notif, action) {
        if (notif && action) action.invoke()
    }

    function receivedAt(notif) { return root.timestamps[notif?.id] ?? 0 }

    function formatTimeAgo(ms) { return TimeUtils.formatTimeAgo(ms) }

    function sanitizePathText(text) {
        if (!text) return ""
        let out = text.replace(/`/g, "").replace(/([^:])\/{2,}/g, "$1/")
        const home = AppPaths.homeDir
        if (home !== "" && out.indexOf(home) === 0) out = "~" + out.slice(home.length)
        return out
    }

    function formatBody(body) { return root.sanitizePathText(body ?? "") }

    function resolveImage(notif) {
        const raw = notif?.image ?? ""
        if (raw === "") return ""
        if (raw.startsWith("file://") || raw.startsWith("http://") || raw.startsWith("https://")
                || raw.startsWith("data:"))
            return raw
        if (raw.startsWith("/")) return "file://" + raw
        return raw
    }

    function resolveIcon(notif) { return IconResolver.notificationIcon(notif) }

    function bumpList() {
        Qt.callLater(() => { root.listVersion++; root.listChanged() })
    }

    function applyPopups(next) {
        Qt.callLater(() => {
            root.popups.splice(0, root.popups.length)
            for (let i = 0; i < next.length; i++) root.popups.push(next[i])
            root.popupVersion++
        })
    }

    function pushPopupNow(notif) {
        if (!notif) return
        const idx = root.popups.findIndex(n => n.id === notif.id)
        if (idx >= 0) root.popups.splice(idx, 1)
        root.popups.unshift(notif)
        while (root.popups.length > root.maxPopups) root.popups.pop()
        root.popupVersion++
    }

    function popupDuration(notif) {
        const timeout = notif?.expireTimeout ?? -1
        if (timeout === 0) return 0
        return timeout > 0 ? timeout : root.defaultPopupMs
    }

    function pushPopup(notif) {
        if (!notif) return
        const filtered = root.popups.filter(n => n.id !== notif.id)
        applyPopups([notif].concat(filtered).slice(0, root.maxPopups))
    }

    function popPopup(notif) {
        if (!notif) return
        applyPopups(root.popups.filter(n => n.id !== notif.id))
    }

    function hidePopup(notif) {
        if (!notif) return
        root.popupHideRequested(notif)
    }

    function registerNotification(notif) {
        const next = Object.assign({}, root.timestamps)
        next[notif.id] = Date.now()
        root.timestamps = next

        if (!root.panelOpen) root.unreadCount++

        notif.closed.connect(function () {
            const copy = Object.assign({}, root.timestamps)
            delete copy[notif.id]
            root.timestamps = copy
            root.hidePopup(notif)
            Qt.callLater(() => root.bumpList())
        })
    }

    NotificationServer {
        id: notifServer
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: false

        onNotification: notif => {
            notif.tracked = true
            root.registerNotification(notif)
            Qt.callLater(() => {
                if (!NetworkStatusService.dndMode) root.pushPopupNow(notif)
                root.listVersion++; root.listChanged()
            })
        }

        onTrackedNotificationsChanged: Qt.callLater(() => root.bumpList())
    }
}
