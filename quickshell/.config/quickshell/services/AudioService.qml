pragma Singleton

import QtQuick
import Quickshell.Io
import "../utils"

Item {
    id: root
    visible: false

    signal changed()

    property real volume: 0
    property bool muted: false
    property real micVolume: 0
    property bool micMuted: false

    function parsePercent(text, fallback) {
        const n = parseInt(text, 10)
        return isNaN(n) ? fallback : ColorUtils.clamp(n, 0, 100)
    }

    function applyFromParts(parts) {
        root.volume = root.parsePercent(parts[5], root.volume)
        root.muted = parts[6] === "true"
        root.micVolume = root.parsePercent(parts[7], root.micVolume)
        root.micMuted = parts[8] === "true"
        root.changed()
    }

    function setVolume(percent) {
        root.volume = ColorUtils.clamp(percent, 0, 100)
        volRunner.actionCmd = ["bash", "-c",
            "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (root.volume / 100)]
        volRunner.running = false
        volRunner.running = true
    }

    function toggleMute() {
        root.muted = !root.muted
        muteRunner.running = false
        muteRunner.running = true
    }

    function setMicVolume(percent) {
        root.micVolume = ColorUtils.clamp(percent, 0, 100)
        micRunner.actionCmd = ["bash", "-c",
            "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (root.micVolume / 100)]
        micRunner.running = false
        micRunner.running = true
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted
        micMuteRunner.running = false
        micMuteRunner.running = true
    }

    Process {
        id: volRunner
        property var actionCmd: ["true"]
        command: actionCmd
    }

    Process {
        id: muteRunner
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: micRunner
        property var actionCmd: ["true"]
        command: actionCmd
    }

    Process {
        id: micMuteRunner
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }
}
