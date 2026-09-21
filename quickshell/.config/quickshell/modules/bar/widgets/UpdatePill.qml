import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../core"
import "../../../components"

PillBase {
    id: root

    property int dnfCount: 0
    property int flatpakCount: 0
    property bool checking: false

    Timer {
        interval: 60000 * 30
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    function refresh() {
        checking = true
        dnfCheck.running = true
        flatpakCheck.running = true
    }

    onCheckingChanged: {
        if (!checking)
            root.opacity = 1.0
    }

    Process {
        id: dnfCheck
        command: ["bash", "-c", "dnf -q repoquery --upgrades 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.dnfCount = parseInt(this.text.trim()) || 0
        }
        onRunningChanged: {
            if (!running && !flatpakCheck.running)
                root.checking = false
        }
    }

    Process {
        id: flatpakCheck
        command: ["bash", "-c", "flatpak remote-ls --updates --app 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.flatpakCount = parseInt(this.text.trim()) || 0
        }
        onRunningChanged: {
            if (!running && !dnfCheck.running)
                root.checking = false
        }
    }

    SequentialAnimation {
        id: pulseAnim
        loops: Animation.Infinite
        running: root.checking
        PropertyAnimation { target: root; property: "opacity"; to: 0.45; duration: 400; easing.type: Easing.InOutQuad }
        PropertyAnimation { target: root; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
    }

    content: RowLayout {
        spacing: 6

        SvgIcon {
            source: AppPaths.iconsDir + "ghost.svg"
            size: 14
            tint: Theme.inkSurf
        }

        Text {
            text: root.dnfCount.toString()
            color: Theme.inkSurf
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }

        Rectangle {
            width: 1; height: 12
            color: Theme.alpha(Theme.outline, 0.4)
        }

        SvgIcon {
            source: AppPaths.iconsDir + "packages.svg"
            size: 14
            tint: Theme.inkSurf
        }

        Text {
            text: root.flatpakCount.toString()
            color: Theme.inkSurf
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.refresh()
    }
}
