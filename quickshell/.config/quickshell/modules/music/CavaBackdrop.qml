import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import "../../core"

Item {
    id: root

    property bool  shown: true
    property bool  animating: true
    property real  radius: 14
    property int   barCount: 8
    property var   barHeights: []

    readonly property string configPath: {
        const url = Qt.resolvedUrl("../../assets/cava_bar.conf")
        return url.toString().replace(/^file:\/\//, "")
    }

    opacity: root.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    function idleBars() {
        const idle = []
        for (let i = 0; i < root.barCount; i++)
            idle.push(0)
        return idle
    }

    function parseLine(line) {
        const trimmed = line.trim().replace(/;$/, "")
        if (trimmed.length === 0)
            return

        const parts = trimmed.split(";")
        const next = []
        const max = 7

        for (let i = 0; i < root.barCount; i++) {
            const raw = i < parts.length ? parseInt(parts[i], 10) : 0
            next.push(isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / max)))
        }

        root.barHeights = next
    }

    Process {
        id: cavaProc
        running: root.shown && root.animating
        command: ["cava", "-p", root.configPath]

        stdout: SplitParser {
            onRead: data => {
                if (root.animating)
                    root.parseLine(data)
            }
        }

        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.shown && root.animating && !cavaProc.running)
                cavaProc.running = true
        }
    }

    onAnimatingChanged: {
        if (!root.animating)
            root.barHeights = root.idleBars()
    }

    onShownChanged: {
        if (!root.shown)
            root.barHeights = root.idleBars()
    }

    Component.onCompleted: {
        root.barHeights = root.idleBars()
    }

    Item {
        id: viz
        anchors.fill: parent
        clip: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: viz.width
                height: viz.height
                radius: root.radius
            }
        }

        Row {
            id: barRow
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 2
            opacity: root.animating ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Repeater {
                model: root.barCount

                Item {
                    required property int index
                    width: (barRow.width - barRow.spacing * (root.barCount - 1)) / root.barCount
                    height: barRow.height

                    readonly property real level: root.barHeights.length > index
                        ? root.barHeights[index]
                        : 0

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(2, parent.width * 0.72)
                        height: parent.height * parent.level
                        radius: width / 2
                        visible: parent.level > 0.01
                        color: Qt.rgba(
                            Theme.primary.r + (Theme.secondary.r - Theme.primary.r) * parent.level,
                            Theme.primary.g + (Theme.secondary.g - Theme.primary.g) * parent.level,
                            Theme.primary.b + (Theme.secondary.b - Theme.primary.b) * parent.level,
                            0.35 + parent.level * 0.45
                        )

                        Behavior on height {
                            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                        }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }
    }
}
