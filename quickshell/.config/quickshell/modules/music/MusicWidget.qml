import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import "../../core"
import "../../services"
import "../../components"

PillBase {
    id: root

    property int capsuleHeight: 28
    property int buttonSize:    20
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    implicitHeight: capsuleHeight
    implicitWidth: pillRow.implicitWidth + 24

    // ── Players ───────────────────────────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = Math.max(0, playerList.length - 1)
    }

    readonly property var    player:      playerList.length > 0 ? playerList[activePlayerIndex] : null
    readonly property string trackTitle:  player?.trackTitle  ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property bool   playing:     player?.isPlaying   ?? false

    // ════════════════════════════════════════════════════════════
    // GLOBAL ARTWORK CACHE
    // Watches ALL players at all times, not just the active one.
    // Key: playerName (stable per session, does not change per track)
    // Value: last non-empty artUrl seen for that player
    // ════════════════════════════════════════════════════════════
    property var artCache: ({})

    // Dynamic watchers — one per player in the list
    Repeater {
        model: root.playerList

        Item {
            required property var modelData
            readonly property string pkey: modelData.playerName
                ?? modelData.identity ?? "unknown"

            readonly property string watchedArtUrl: modelData.trackArtUrl ?? ""

            onWatchedArtUrlChanged: {
                if (watchedArtUrl !== "") {
                    const updated = Object.assign({}, root.artCache)
                    updated[pkey] = watchedArtUrl
                    root.artCache = updated
                }
            }

            Component.onCompleted: {
                if (watchedArtUrl !== "") {
                    const updated = Object.assign({}, root.artCache)
                    updated[pkey] = watchedArtUrl
                    root.artCache = updated
                }
            }
        }
    }

    readonly property string activePkey: player?.playerName
        ?? player?.identity ?? "unknown"

    readonly property string stableArtUrl: artCache[activePkey] ?? ""

    property bool popupOpen: false

    function togglePopup() {
        if (root.player === null)
            return
        if (root.popupOpen) {
            root.popupOpen = false
        } else {
            PopupManager.openExclusive(PopupManager.musicId)
            Qt.callLater(() => root.popupOpen = true)
        }
    }

    onPopupOpenChanged: {
        if (!popupOpen)
            PopupManager.notifyClosed(PopupManager.musicId)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.musicId)
                root.popupOpen = false
        }
    }

    property string defaultArtPath: Qt.resolvedUrl("../../assets/music-disc.jpg")

    content: RowLayout {
        id: pillRow
        spacing: 8
        opacity: 1
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            width: 20; height: 20; radius: 10
            color: "transparent"
            clip: true
            Image {
                anchors.fill: parent
                source: root.stableArtUrl !== ""
                    ? root.stableArtUrl
                    : root.defaultArtPath
                fillMode: Image.PreserveAspectCrop
                cache: true; asynchronous: true
                opacity: root.player !== null ? 1.0 : 0.35
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: 20; height: 20; radius: 10 }
            }
        }

        Row {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            opacity: root.player !== null ? 1 : 0.45
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MusicSvgButton {
                size: root.buttonSize + 4
                iconPath: root.iconsPath + "rewind.svg"
                btnEnabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }
            MusicSvgButton {
                size: root.buttonSize + 4
                iconPath: root.playing
                    ? root.iconsPath + "pause.svg"
                    : root.iconsPath + "play.svg"
                btnEnabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player?.togglePlaying()
            }
            MusicSvgButton {
                size: root.buttonSize + 4
                iconPath: root.iconsPath + "rewind.svg"
                iconRot: 180
                btnEnabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            if (root.player === null)
                return
            if (root.popupOpen) {
                root.popupOpen = false
            } else {
                PopupManager.openExclusive(PopupManager.musicId)
                Qt.callLater(() => root.popupOpen = true)
            }
        }
    }

    WheelHandler {
        onWheel: event => {
            if (!root.player) return
            const d = event.angleDelta.y / 120 * 0.05
            root.player.volume = Math.max(0, Math.min(1, (root.player.volume ?? 0) + d))
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
