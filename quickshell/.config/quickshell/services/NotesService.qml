pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: root
    visible: false

    property var notes: []
    property int revision: 0
    property bool _loaded: false
    property int tagMax: 6

    readonly property var defaultTags: [
        { name: "Work", color: "#5C6BC0" },
        { name: "Home", color: "#66BB6A" },
        { name: "Personal", color: "#AB47BC" },
        { name: "Study", color: "#FFA726" },
        { name: "Health", color: "#EF5350" },
        { name: "Finance", color: "#26A69A" },
        { name: "Urgent", color: "#F06292" },
        { name: "Ideas", color: "#5C6BC0" },
        { name: "Shopping", color: "#8D6E63" },
        { name: "Travel", color: "#29B6F6" }
    ]

    readonly property string storePath: AppPaths.homeDir + "/.config/quickshell/notes.json"
    readonly property var todoNotes: (root.revision, root.notesFor("todo"))
    readonly property var ongoingNotes: (root.revision, root.notesFor("ongoing"))
    readonly property var doneNotes: (root.revision, root.notesFor("done"))
    readonly property var existingTags: (root.revision, root.allTags())

    FileView {
        id: store
        preload: true
        atomicWrites: true
        printErrors: true
        onLoaded: {
            const txt = store.text().trim()
            if (txt === "") {
                root.notes = []
            } else {
                try {
                    const parsed = JSON.parse(txt)
                    if (Array.isArray(parsed)) root.notes = parsed
                    else root.notes = []
                } catch (e) {
                    console.warn("notes: failed to parse notes.json", e)
                    root.notes = []
                }
            }
            console.log("notes loaded:", root.notes.length)
            root._loaded = true
            root.revision++
            root.notesChanged()
        }
        onLoadFailed: {
            root.notes = []
            if (AppPaths.homeDir !== "")
                root._loaded = true
            root.notesChanged()
        }
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() { root.load() }
    }

    Timer {
        interval: 450
        running: true
        repeat: false
        onTriggered: root.load()
    }

    function load() {
        if (AppPaths.homeDir === "") return
        store.path = root.storePath
    }

    function commit() {
        if (!root._loaded) { root.load(); return }
        store.setText(root.serialize())
        root.revision++
        root.notesChanged()
    }

    function serialize() {
        return JSON.stringify(root.notes.map(n => ({
            id: n.id,
            title: n.title ?? "",
            body: n.body ?? "",
            status: n.status ?? "todo",
            importance: n.importance ?? "none",
            difficulty: n.difficulty ?? "none",
            tags: (n.tags ?? []).filter(t => t && String(t.name ?? "").trim() !== "")
                .map(t => ({
                    name: String(t.name).trim().slice(0, 20),
                    color: String(t.color ?? "#42A5F5")
                })),
            created: n.created ?? 0,
            modified: n.modified ?? 0
        })), null, 2)
    }

    function notesFor(status) {
        const out = []
        for (let i = 0; i < root.notes.length; i++)
            if (root.notes[i].status === status) out.push(root.notes[i])
        return out
    }

    function allTags() {
        const seen = {}
        const out = []
        for (let i = 0; i < root.defaultTags.length; i++) {
            const t = root.defaultTags[i]
            const key = String(t.name ?? "").trim().toLowerCase()
            if (!key || seen[key]) continue
            seen[key] = true
            out.push({ name: String(t.name).trim().slice(0, 20), color: String(t.color ?? "#42A5F5") })
        }
        for (let i = root.notes.length - 1; i >= 0; i--) {
            const tags = root.notes[i].tags ?? []
            for (let j = 0; j < tags.length; j++) {
                const t = tags[j]
                const key = String(t.name ?? "").trim().toLowerCase()
                if (!key || seen[key]) continue
                seen[key] = true
                out.push({ name: String(t.name).trim().slice(0, 20), color: String(t.color ?? "#42A5F5") })
            }
        }
        return out
    }

    function findNote(id) {
        if (!id) return null
        for (let i = 0; i < root.notes.length; i++)
            if (root.notes[i].id === id) return root.notes[i]
        return null
    }

    function addNote(title, body, status, importance, difficulty, tags) {
        const now = Date.now()
        const n = {
            id: "n" + Date.now().toString(36) + Math.floor(Math.random() * 999),
            title: title ?? "",
            body: body ?? "",
            status: (status === "todo" || status === "ongoing" || status === "done") ? status : "todo",
            importance: (importance === "low" || importance === "medium" || importance === "high") ? importance : "none",
            difficulty: (difficulty === "easy" || difficulty === "medium" || difficulty === "hard") ? difficulty : "none",
            tags: (tags ?? []).filter(t => t && String(t.name ?? "").trim() !== "")
                .map(t => ({
                    name: String(t.name).trim().slice(0, 20),
                    color: String(t.color ?? "#42A5F5")
                }))
                .slice(0, root.tagMax),
            created: now,
            modified: now
        }
        root.notes = root.notes.concat([n])
        root.commit()
        return n.id
    }

    function updateNote(id, patch) {
        const now = Date.now()
        root.notes = root.notes.map(n => n.id === id
            ? Object.assign({}, n, patch, { modified: now })
            : n)
        root.commit()
    }

    function moveNote(id, dir) {
        const order = ["todo", "ongoing", "done"]
        const n = root.findNote(id)
        if (!n) return
        const i = order.indexOf(n.status)
        const j = i + dir
        if (j < 0 || j >= order.length) return
        root.notes = root.notes.map(n2 => n2.id === id
            ? Object.assign({}, n2, { status: order[j], modified: Date.now() })
            : n2)
        root.commit()
    }

    function removeNote(id) {
        root.notes = root.notes.filter(n => n.id !== id)
        root.commit()
    }

    Component.onCompleted: Qt.callLater(root.load)
}
