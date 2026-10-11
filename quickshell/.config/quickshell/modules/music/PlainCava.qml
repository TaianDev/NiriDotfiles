import QtQuick
import Quickshell.Io
import "../../core"

// Cava simple tipo terminal: barras de un solo color, centradas y abajo.
Item {
    id: root

    property bool active: true
    property int barCount: 32
    property color barColor: Theme.primary
    property var levels: []

    readonly property string configPath: Qt.resolvedUrl("../../assets/cava_plain.conf")
        .toString().replace(/^file:\/\//, "")

    function idleBars() {
        const a = []
        for (let i = 0; i < root.barCount; i++) a.push(0)
        return a
    }

    function parseLine(line) {
        const trimmed = line.trim().replace(/;$/, "")
        if (trimmed === "")
            return
        const parts = trimmed.split(";")
        const max = 7
        const next = []
        for (let i = 0; i < root.barCount; i++) {
            const raw = i < parts.length ? parseInt(parts[i], 10) : 0
            next.push(isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / max)))
        }
        root.levels = next
    }

    Process {
        id: cavaProc
        running: root.active
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: data => { if (root.active) root.parseLine(data) }
        }
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 1500; repeat: false
        onTriggered: if (root.active && !cavaProc.running) cavaProc.running = true
    }

    onActiveChanged: if (!root.active) root.levels = root.idleBars()
    Component.onCompleted: root.idleBars()

    Row {
        id: bars
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                width: Math.max(1, (bars.width - bars.spacing * (root.barCount - 1)) / root.barCount)
                height: Math.max(1, bars.height * (root.levels.length > index ? root.levels[index] : 0))
                anchors.bottom: parent.bottom
                color: root.barColor
            }
        }
    }
}
