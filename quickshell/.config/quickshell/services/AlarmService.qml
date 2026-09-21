pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: root
    visible: false

    property var alarms: []
    property int revision: 0
    property string ringingId: ""
    property var _fired: ({})
    property bool _loaded: false

    readonly property bool ringing: root.ringingId !== ""
    readonly property var ringingAlarm: root.findAlarm(root.ringingId)
    readonly property string storePath: AppPaths.homeDir + "/.config/quickshell/alarms.json"
    readonly property string alarmSound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    readonly property var nextAlarm: (root.revision, root.computeNext())

    FileView {
        id: store
        preload: true
        atomicWrites: true
        printErrors: true
        onLoaded: {
            const txt = store.text().trim()
            if (txt === "") {
                root.alarms = []
            } else {
                try {
                    const parsed = JSON.parse(txt)
                    if (Array.isArray(parsed)) root.alarms = parsed
                    else root.alarms = []
                } catch (e) {
                    console.warn("alarms: failed to parse alarms.json", e)
                    root.alarms = []
                }
            }
            console.log("alarms loaded:", root.alarms.length)
            root._loaded = true
            root.alarmsChanged()
        }
        onLoadFailed: {
            root.alarms = []
            if (AppPaths.homeDir !== "")
                root._loaded = true
            root.alarmsChanged()
        }
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() {
            root.load()
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: false
        onTriggered: root.load()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.checkAlarms()
    }

    function load() {
        if (AppPaths.homeDir === "")
            return
        store.path = root.storePath
    }

    function commit() {
        if (!root._loaded) {
            root.load()
            return
        }
        store.setText(root.serialize())
        root.revision++
        root.alarmsChanged()
    }

    function serialize() {
        return JSON.stringify(root.alarms.map(a => ({
            id: a.id,
            hour: a.hour,
            minute: a.minute,
            enabled: !!a.enabled,
            days: Array.isArray(a.days) ? a.days : [true, true, true, true, true, true, true],
            label: a.label ?? "",
            oneShot: !!a.oneShot
        })), null, 2)
    }

    function findAlarm(id) {
        if (!id) return null
        for (let i = 0; i < root.alarms.length; i++)
            if (root.alarms[i].id === id) return root.alarms[i]
        return null
    }

    function dayMatches(alarm) {
        const d = new Date().getDay()
        const days = Array.isArray(alarm.days) ? alarm.days : [true, true, true, true, true, true, true]
        return !!days[d]
    }

    function formatTime(alarm) {
        const h = (alarm.hour ?? 0)
        const m = (alarm.minute ?? 0)
        const period = h >= 12 ? "PM" : "AM"
        const h12 = h % 12 === 0 ? 12 : h % 12
        return h12 + ":" + String(m).padStart(2, "0") + " " + period
    }

    function computeNext() {
        let best = null
        const now = new Date()
        for (const a of root.alarms) {
            if (!a.enabled || (a.snoozeUntil ?? 0) > now.getTime())
                continue
            if (!root.dayMatches(a)) continue
            const t = new Date(now)
            t.setHours(a.hour, a.minute, 0, 0)
            if (t <= now) t.setDate(t.getDate() + 1)
            if (!best || t < best) best = t
        }
        return best
    }

    function checkAlarms() {
        const now = new Date()
        const h = now.getHours()
        const m = now.getMinutes()
        for (const a of root.alarms) {
            if (!a.enabled || (a.snoozeUntil ?? 0) > now.getTime())
                continue
            if (a.hour !== h || a.minute !== m)
                continue
            if (!root.dayMatches(a))
                continue
            const key = a.id + ":" + now.toDateString() + ":" + h + ":" + m
            if (root._fired[key])
                continue
            root._fired[key] = true
            root.fireAlarm(a)
        }
    }

    function fireAlarm(alarm) {
        root.ringingId = alarm.id
        root.ringingChanged()

        NotificationService.createAlarmNotification(
            "Alarm  " + root.formatTime(alarm),
            alarm.label ?? "",
            () => root.snooze(alarm, 10),
            () => root.dismiss(alarm)
        )

        Quickshell.execDetached(["paplay", root.alarmSound])

        if (alarm.oneShot) {
            root.alarms = root.alarms.map(a => a.id === alarm.id ? Object.assign({}, a, { enabled: false }) : a)
            root.commit()
        }
    }

    function snooze(alarm, minutes) {
        const target = alarm.id
        root.alarms = root.alarms.map(a => a.id === target
            ? Object.assign({}, a, { snoozeUntil: Date.now() + minutes * 60000 }) : a)
        root.ringingId = ""
        root.ringingChanged()
        root.commit()
    }

    function dismiss(alarm) {
        if (alarm && alarm.oneShot) {
            const target = alarm.id
            root.alarms = root.alarms.map(a => a.id === target ? Object.assign({}, a, { enabled: false }) : a)
        }
        root.ringingId = ""
        root.ringingChanged()
        root.commit()
    }

    function addAlarm(hour, minute, days, label) {
        const a = {
            id: "a" + Date.now().toString(36) + Math.floor(Math.random() * 999),
            hour: Math.max(0, Math.min(23, hour)),
            minute: Math.max(0, Math.min(59, minute)),
            enabled: true,
            days: days.length === 7 ? days : [true, true, true, true, true, true, true],
            label: label ?? "",
            oneShot: false,
            snoozeUntil: 0
        }
        root.alarms = root.alarms.concat([a])
        root.commit()
    }

    function updateAlarm(id, patch) {
        root.alarms = root.alarms.map(a => a.id === id ? Object.assign({}, a, patch) : a)
        root.commit()
    }

    function removeAlarm(id) {
        root.alarms = root.alarms.filter(a => a.id !== id)
        if (root.ringingId === id) {
            root.ringingId = ""
            root.ringingChanged()
        }
        root.commit()
    }

    function setEnabled(id, enabled) {
        for (let i = 0; i < root.alarms.length; i++) {
            if (root.alarms[i].id === id) {
                root.alarms[i].enabled = enabled
                break
            }
        }
        root.commit()
    }

    Component.onCompleted: Qt.callLater(root.load)
}