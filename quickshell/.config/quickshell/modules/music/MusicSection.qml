import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../core"
import "../../services"
import "../../components"

// Player de música embebible para la sección Home.
Item {
    id: root

    readonly property string iconsPath: AppPaths.iconsDir
    readonly property string defaultArtPath: Qt.resolvedUrl("../../assets/music-disc.jpg")

    readonly property var playerList: MediaService.players
    readonly property var player: MediaService.activePlayer
    readonly property int activePlayerIndex: MediaService.activePlayerIndex

    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""

    readonly property bool positionValid: player?.positionSupported ?? false
    readonly property real positionSecs: player?.position ?? 0
    readonly property real lengthSecs: player?.length ?? 0
    readonly property bool lengthValid: player?.lengthSupported ?? false
    readonly property bool seekable: player?.canSeek ?? false
    readonly property bool showSeek: player !== null && lengthValid && positionValid && seekable
    readonly property real progress: showSeek && lengthSecs > 0
        ? Math.min(1, positionSecs / lengthSecs) : 0

    readonly property bool volumeSupported: player?.volumeSupported ?? false
    readonly property real playerVolume: player?.volume ?? 0
    property bool muted: (player?.volume ?? 1) <= 0.001
    property real lastVolume: 0.6

    function toggleMute() {
        if (!root.player || !root.volumeSupported)
            return
        if (root.muted) {
            root.player.volume = Math.max(0, Math.min(1, root.lastVolume))
            root.muted = false
        } else {
            root.lastVolume = root.player.volume ?? 0
            root.player.volume = 0
            root.muted = true
        }
    }

    Timer {
        running: root.playing && root.positionValid
        interval: 250; repeat: true
        onTriggered: if (root.player) root.player.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // ── Selector de reproductor (arriba) ──
        PlayerRow {
            Layout.alignment: Qt.AlignHCenter
            playerList: root.playerList
            activeIndex: root.activePlayerIndex
            iconsPath: root.iconsPath
            onPlayerChanged: (index, direction) => MediaService.activePlayerIndex = index
        }

        AppText {
            Layout.fillWidth: true
            text: root.playerList.length === 0 ? "No media playing" : ""
            color: Theme.inkSurfVar
            font.pixelSize: 11
            opacity: 0.6
            horizontalAlignment: Text.AlignHCenter
            visible: root.playerList.length === 0
        }

        // ── Carátula (redondeada, dentro del contenedor) ──
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 140
            Layout.preferredHeight: 140

            Image {
                id: artImg
                anchors.fill: parent
                source: root.artUrl !== "" ? root.artUrl : root.defaultArtPath
                sourceSize.width: 280
                sourceSize.height: 280
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 140; height: 140; radius: 18 }
                }
            }
        }

        AppText {
            Layout.fillWidth: true
            text: root.title !== "" ? root.title : "No title"
            color: Theme.inkSurf
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
        }

        AppText {
            Layout.fillWidth: true
            text: [root.artist, root.album].filter(p => p !== "").join(" · ")
            color: Theme.inkSurfVar
            font.pixelSize: 10
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            visible: text !== ""
        }

        // ── Barra de progreso (Material) + tiempos ──
        SeekBar {
            Layout.fillWidth: true
            visible: root.showSeek
            player: root.player
            playing: root.playing
            progress: root.progress
            positionSecs: root.positionSecs
            lengthSecs: root.lengthSecs
        }

        // ── Transporte ──
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            MusicSvgButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                iconPath: root.iconsPath + "rewind.svg"
                btnEnabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }
            MusicSvgButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 38
                kind: "fab"
                iconPath: root.playing
                    ? root.iconsPath + "pause.svg"
                    : root.iconsPath + "play.svg"
                btnEnabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player?.togglePlaying()
            }
            MusicSvgButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                iconPath: root.iconsPath + "rewind.svg"
                iconRot: 180
                btnEnabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }
        }

        // ── Volumen (píldora compacta) ──
        VolumePill {
            Layout.alignment: Qt.AlignHCenter
            volume: root.playerVolume
            muted: root.muted
            enabled: root.volumeSupported && root.player !== null
            onMuteToggled: root.toggleMute()
            onMoved: val => { if (root.player && root.volumeSupported) root.player.volume = val }
        }

        // ── Cava (plano, centrado y abajo) ──
        PlainCava {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            active: HubService.opened && root.playing
            barColor: Theme.primary
            barCount: 32
        }
    }
}
