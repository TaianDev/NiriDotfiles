import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool active: true
    property string configPath: ""

    readonly property color barLow: Qt.rgba(
        Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18
    )
    readonly property color barHigh: Qt.rgba(
        Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.45
    )

    property var levels: []
    property int count: 16

    function idle() {
        const a = []
        for (let i = 0; i < root.count; i++)
            a.push(0)
        return a
    }

    function parse(line) {
        const t = line.trim().replace(/;$/, "")
        if (t.length === 0) return
        const p = t.split(";")
        const n = []
        const max = 7
        for (let i = 0; i < root.count; i++) {
            const r = i < p.length ? parseInt(p[i], 10) : 0
            n.push(isNaN(r) ? 0 : Math.max(0, Math.min(1, r / max)))
        }
        root.levels = n
    }

    Process {
        id: cavaProc
        running: root.active && root.configPath !== ""
        command: ["cava", "-p", root.configPath]

        stdout: SplitParser {
            onRead: data => {
                if (root.active)
                    root.parse(data)
            }
        }
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.active && root.configPath !== "" && !cavaProc.running)
                cavaProc.running = true
        }
    }

    onActiveChanged: {
        if (!root.active)
            root.levels = root.idle()
    }

    Component.onCompleted: {
        root.levels = root.idle()
    }

    Row {
        id: barRow
        anchors.centerIn: parent
        height: parent.height - 20
        spacing: 5

        Repeater {
            model: root.count
            Rectangle {
                required property int index

                readonly property real level:
                    root.levels.length > index ? root.levels[index] : 0

                width: 6
                height: barRow.height
                color: "transparent"

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: Math.max(6, parent.height * parent.level)
                    radius: 3
                    visible: parent.level > 0.03
                    color: Qt.rgba(
                        root.barLow.r + (root.barHigh.r - root.barLow.r) * level,
                        root.barLow.g + (root.barHigh.g - root.barLow.g) * level,
                        root.barLow.b + (root.barHigh.b - root.barLow.b) * level,
                        root.barLow.a + (root.barHigh.a - root.barLow.a) * level
                    )
                    Behavior on height {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
