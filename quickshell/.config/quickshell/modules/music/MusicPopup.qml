import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"
import "../../utils"

PopupWindow {
    id: popup

    required property var widgetRef
    required property var parentWindow

    readonly property bool open: widgetRef?.popupOpen ?? false

    grabFocus: open

    readonly property int mainWidth: 300
    readonly property int volumePanelWidth: 52
    readonly property int volumeGap: 8
    readonly property bool volumeSupported: popup.player?.volumeSupported ?? false

    property bool volumeOpen: false
    property bool isMuted: false
    property real lastVolume: 0.6
    property bool _slideBackward: false

    readonly property bool muted: (popup.player?.volume ?? 1) <= 0.001

    function toggleMute() {
        if (!popup.player) return
        if (popup.isMuted) {
            popup.player.volume = Math.max(0, Math.min(1, popup.lastVolume))
            popup.isMuted = false
        } else {
            popup.lastVolume = popup.player?.volume ?? 0
            popup.player.volume = 0
            popup.isMuted = true
            if (popup.volumeOpen) { popup.volumeOpen = false; Qt.callLater(popup.reposition) }
        }
    }

    function toggleVolumePanel() {
        if (popup.isMuted) return
        popup.volumeOpen = !popup.volumeOpen
        Qt.callLater(popup.reposition)
    }

    Connections {
        target: popup.player
        function onVolumeChanged() {
            popup.isMuted = (popup.player?.volume ?? 0) <= 0.001
        }
    }

    // ── Layout heights (M3 "Now Playing") ──
    readonly property real headerH: 30
    readonly property real artH: 170
    readonly property real seekH: 37
    readonly property real transportH: 48
    readonly property real chipsH: 34
    readonly property real contentSpacing: 12

    visible: open || shell.exitRunning || volumeFade.shown || volumeFade.exitRunning
    color: "transparent"
    implicitWidth: popup.mainWidth
        + (popup.volumeOpen && popup.volumeSupported
            ? popup.volumeGap + popup.volumePanelWidth : 0)
    implicitHeight: 28 + popup.headerH + popup.artH + popup.seekH
        + popup.transportH + popup.chipsH + popup.contentSpacing * 4

    function reposition() {
        if (!widgetRef || !parentWindow) return
        const totalW = Math.max(popup.mainWidth, implicitWidth)
        const h = Math.max(1, implicitHeight)
        const pos = widgetRef.mapToItem(parentWindow.contentItem, 0, widgetRef.height)
        const ax = pos.x + widgetRef.width / 2 - popup.mainWidth / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, totalW, h)
        anchor.updateAnchor()
    }

    onOpenChanged: {
        if (open) {
            popup.isMuted = popup.muted
            reposition()
            shell.active = true
            Qt.callLater(() => popup.contentItem.forceActiveFocus())
        }
        else { shell.active = false; popup.volumeOpen = false }
    }

    // ════════════════════════════════════════════════════════════
    // PROPIEDADES DEL PLAYER
    // ════════════════════════════════════════════════════════════
    readonly property var    player:      widgetRef?.player      ?? null
    readonly property bool   playing:     widgetRef?.playing     ?? false
    readonly property string trackTitle:  widgetRef?.trackTitle  ?? ""
    readonly property string trackArtist: widgetRef?.trackArtist ?? ""
    readonly property string trackAlbum:  player?.trackAlbum     ?? ""
    readonly property string iconsPath:   widgetRef?.iconsPath   ?? ""
    readonly property var    playerList:  widgetRef?.playerList  ?? []

    readonly property string stableArtUrl: widgetRef?.stableArtUrl ?? ""

    readonly property string selectedPkey: {
        const p = playerList.length > 0
            ? playerList[widgetRef?.activePlayerIndex ?? 0] : null
        return p?.playerName ?? p?.identity ?? "unknown"
    }
    readonly property string selectedArtUrl: widgetRef?.artCache?.[selectedPkey] ?? ""
    readonly property string displayArtUrl: selectedArtUrl !== "" ? selectedArtUrl : stableArtUrl

    // ── Loop / shuffle (toggles M3) ──
    readonly property bool loopSupported: popup.player?.loopSupported ?? false
    readonly property bool shuffleOn:     popup.player?.shuffle      ?? false

    readonly property string repeatIcon: {
        const s = popup.player?.loopState ?? MprisLoopState.None
        return s === MprisLoopState.Track ? "repeat-once.svg"
            : s === MprisLoopState.Playlist ? "repeat-all.svg"
            : "repeat-none.svg"
    }

    readonly property string artistAndAlbum: [
        popup.trackArtist, popup.trackAlbum
    ].filter(part => part !== "").join(" · ")

    function cycleRepeat() {
        if (!popup.loopSupported || !popup.player) return
        const s = popup.player.loopState
        if (s === MprisLoopState.None)
            popup.player.loopState = MprisLoopState.Track
        else if (s === MprisLoopState.Track)
            popup.player.loopState = MprisLoopState.Playlist
        else
            popup.player.loopState = MprisLoopState.None
    }

    function toggleShuffle() {
        if (popup.player?.shuffleSupported)
            popup.player.shuffle = !popup.player.shuffle
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.musicId)
                widgetRef.popupOpen = false
        }
    }

    onVisibleChanged: {
        if (visible) reposition()
        else if (popup.open && !shell.exitRunning && !volumeFade.shown && !volumeFade.exitRunning)
            widgetRef.popupOpen = false
    }

    onVolumeOpenChanged: Qt.callLater(reposition)
    onImplicitWidthChanged: Qt.callLater(reposition)

    // ── Track vs. live-stream state ──
    // A player is treated as a live stream only when it genuinely lacks length
    // support and cannot seek, and only after the track-change settle window
    // has elapsed. This stops the LIVE pill from flashing on transitions.
    property var lengthCache: ({})     // playerKey -> last known length (s)
    property var lengthPlayers: ({})   // playerKey -> length support observed

    readonly property string playerKey: player?.playerName
        ?? player?.identity ?? ""

    readonly property bool hasLengthSupport: player?.lengthSupported ?? false
    readonly property bool lengthSupportKnown: popup.hasLengthSupport
        || popup.lengthPlayers[popup.playerKey] === true

    function rememberLengthSupport() {
        if (!popup.hasLengthSupport || popup.player === null
                || popup.playerKey === ""
                || popup.lengthPlayers[popup.playerKey] === true)
            return
        const next = Object.assign({}, popup.lengthPlayers)
        next[popup.playerKey] = true
        popup.lengthPlayers = next
    }

    function rememberLength() {
        if (!popup.hasLengthSupport || popup.lengthSecs <= 0
                || popup.player === null || popup.playerKey === ""
                || popup.lengthCache[popup.playerKey] === popup.lengthSecs)
            return
        const next = Object.assign({}, popup.lengthCache)
        next[popup.playerKey] = popup.lengthSecs
        popup.lengthCache = next
    }

    // Keep the last known duration while metadata settles mid-transition.
    readonly property real effectiveLengthSecs: popup.hasLengthSupport
            && popup.lengthSecs > 0
        ? popup.lengthSecs
        : (popup.lengthCache[popup.playerKey] ?? popup.lengthSecs)

    readonly property bool positionValid: player?.positionSupported ?? false
    readonly property real positionSecs:  player?.position ?? 0
    readonly property real lengthSecs:    player?.length ?? 0
    readonly property bool seekable:      player?.canSeek ?? false

    readonly property bool isLiveStream: player !== null
        && !popup.lengthSupportKnown
        && !(player?.canSeek ?? false)
        && popup.transitionSettled

    readonly property bool showSeekbar: player !== null
        && !popup.isLiveStream
        && popup.effectiveLengthSecs > 0
        && positionValid && seekable

    readonly property real progress: (popup.showSeekbar && popup.effectiveLengthSecs > 0)
        ? Math.min(1, positionSecs / popup.effectiveLengthSecs) : 0

    Timer {
        id: transitionTimer
        interval: 800; repeat: false
    }

    readonly property bool transitionSettled: !transitionTimer.running

    onHasLengthSupportChanged: popup.rememberLengthSupport()
    onLengthSecsChanged: popup.rememberLength()
    onPlayerChanged: {
        popup.rememberLengthSupport()
        popup.rememberLength()
    }

    Component.onCompleted: {
        popup.rememberLengthSupport()
        popup.rememberLength()
    }

    Connections {
        target: popup.player
        function onUniqueIdChanged() { transitionTimer.restart() }
    }

    Timer {
        running: popup.playing && popup.visible
            && (popup.positionValid || !popup.transitionSettled)
        interval: 250; repeat: true
        onTriggered: if (popup.player) popup.player.positionChanged()
    }

    PopupEscCapture {
        active: popup.open
        popupId: PopupManager.musicId

        Row {
            id: popupRow
            anchors.fill: parent
            spacing: popup.volumeGap

            Item {
                width: popup.mainWidth
                height: popupRow.height

                PopupEnterExit {
                    id: shell
                    anchors.fill: parent
                    active: popup.open
                    cornerRadius: 16
                    panelColor: Theme.surface

                    Column {
                        id: contentCol
                        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 14; leftMargin: 14; rightMargin: 14 }
                        spacing: popup.contentSpacing

                        // ── Cabecera: equalizer + NOW PLAYING + volumen ──
                        RowLayout {
                            width: parent.width
                            height: popup.headerH
                            spacing: 8

                            Item {
                                id: eqBox
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: popup.headerH

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            required property int index
                                            width: 3
                                            height: 7
                                            radius: 1.5
                                            color: Theme.primary
                                            opacity: popup.playing ? 1 : 0.4
                                            Behavior on opacity { NumberAnimation { duration: 200 } }

                                            readonly property bool eqActive: popup.playing && popup.open

                                            SequentialAnimation on height {
                                                running: eqActive
                                                loops: Animation.Infinite
                                                PropertyAnimation { to: 14; duration: 220 + index * 80; easing.type: Easing.InOutSine }
                                                PropertyAnimation { to: 7; duration: 220 + index * 80; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }
                                }
                            }

                            AppText {
                                text: "NOW PLAYING"
                                color: Theme.inkSurfVar
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.5
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

MusicSvgButton {
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        size: 30
        iconPath: popup.iconsPath
            + (popup.muted ? "no-volume.svg" : "volume.svg")
        toggled: popup.muted
        acceptRight: true
        btnEnabled: popup.volumeSupported && popup.player !== null && !popup.isMuted
        onClicked: popup.toggleVolumePanel()
        onRightClicked: popup.toggleMute()
    }
                        }

                        // ── Full-bleed artwork with title/artist ──
                        Item {
                            id: artBlock
                            width: parent.width
                            height: popup.artH
                            clip: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: artBlock.width
                                    height: artBlock.height
                                    radius: 20
                                }
                            }

                            Image {
                                id: artOut
                                width: parent.width
                                height: parent.height
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                opacity: 0
                                sourceSize.width: 360
                                sourceSize.height: 360
                            }

                            Image {
                                id: artIn
                                width: parent.width
                                height: parent.height
                                source: popup.displayArtUrl
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                                asynchronous: true
                                sourceSize.width: 360
                                sourceSize.height: 360

                                onSourceChanged: {
                                    artOut.source = artIn.source
                                    artOut.x = 0; artOut.opacity = 1
                                    artIn.x = popup._slideBackward ? -artIn.width : artIn.width
                                    artIn.opacity = 1
                                    slideAnim.from = popup._slideBackward ? -artIn.width : artIn.width
                                    slideAnim.to = 0
                                    slideOutAnim.from = 0
                                    slideOutAnim.to = popup._slideBackward ? artOut.width : -artOut.width
                                    slideAnim.restart(); slideOutAnim.restart()
                                }

                                NumberAnimation on x {
                                    id: slideAnim
                                    from: artIn.width; to: 0; duration: 280
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: Theme.surfaceVariant
                                visible: popup.displayArtUrl === "" || artIn.status === Image.Error
                                AppText {
                                    anchors.centerIn: parent
                                    text: "\u266A"
                                    font.pixelSize: 48
                                    color: Theme.alpha(Theme.inkSurf, 0.35)
                                }
                            }

                            Rectangle {
                                id: scrim
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 90
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.55) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
                                }
                            }

                            Column {
                                id: textGroup
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                anchors.bottomMargin: 12
                                spacing: 2
                                opacity: 1; y: 0

                                Behavior on opacity { id: textGroupOpB; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on y { id: textGroupYB; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                                Connections {
                                    target: popup
                                    function onTrackTitleChanged() {
                                        textGroupOpB.enabled = false; textGroupYB.enabled = false
                                        textGroup.opacity = 0; textGroup.y = 5
                                        textGroupOpB.enabled = true; textGroupYB.enabled = true
                                        Qt.callLater(function() { textGroup.opacity = 1; textGroup.y = 0 })
                                    }
                                }

                                AppText {
                                    id: titleText
                                    width: parent.width
                                    text: popup.trackTitle || "No title"
                                    color: "#ffffff"
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                AppText {
                                    id: artistText
                                    width: parent.width
                                    text: popup.artistAndAlbum
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            NumberAnimation {
                                id: slideOutAnim
                                target: artOut; property: "x"
                                from: 0; to: -artOut.width; duration: 280
                                easing.type: Easing.OutCubic
                                onStopped: artOut.opacity = 0
                            }
                        }

                        // ── Seekbar M3 ──
                        SeekBar {
                            id: seekBar
                            width: parent.width
                            player: popup.player
                            playing: popup.playing
                            visible: popup.showSeekbar
                            progress: popup.progress
                            positionSecs: popup.positionSecs
                            lengthSecs: popup.effectiveLengthSecs
                        }

                        // ── LIVE pill (for live streams) ──
                        Item {
                            width: parent.width
                            height: popup.seekH
                            visible: popup.isLiveStream

                            Rectangle {
                                anchors.centerIn: parent
                                width: liveRow.width + 20
                                height: 22
                                radius: 11
                                color: Theme.alpha(Theme.err, 0.14)

                                Row {
                                    id: liveRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: Theme.err
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    AppText {
                                        text: "LIVE"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Theme.err
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        // ── Transporte M3 ──
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10
                            height: popup.transportH

                            MusicSvgButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 40
                                iconPath: popup.iconsPath + "shuffle-off.svg"
                                toggled: popup.shuffleOn
                                kind: "ghost"
                                btnEnabled: popup.player?.shuffleSupported ?? false
                                onClicked: popup.toggleShuffle()
                            }
                            MusicSvgButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 40
                                iconPath: popup.iconsPath + "rewind.svg"
                                btnEnabled: popup.player?.canGoPrevious ?? false
                                onClicked: {
                                    popup._slideBackward = true
                                    popup.player?.previous()
                                }
                            }
                            MusicSvgButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 48
                                kind: "fab"
                                iconPath: popup.playing
                                    ? popup.iconsPath + "pause.svg"
                                    : popup.iconsPath + "play.svg"
                                btnEnabled: popup.player?.canTogglePlaying ?? false
                                onClicked: popup.player?.togglePlaying()
                            }
                            MusicSvgButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 40
                                iconPath: popup.iconsPath + "rewind.svg"
                                iconRot: 180
                                btnEnabled: popup.player?.canGoNext ?? false
                                onClicked: {
                                    popup._slideBackward = false
                                    popup.player?.next()
                                }
                            }
                            MusicSvgButton {
                                anchors.verticalCenter: parent.verticalCenter
                                size: 40
                                iconPath: popup.iconsPath + popup.repeatIcon
                                toggled: popup.player?.loopState !== MprisLoopState.None
                                       && popup.loopSupported
                                kind: "ghost"
                                btnEnabled: popup.loopSupported
                                onClicked: popup.cycleRepeat()
                            }
                        }

                        // ── Chips de jugador (M3) ──
                        PlayerRow {
                            anchors.horizontalCenter: parent.horizontalCenter
                            playerList: popup.playerList
                            activeIndex: popup.widgetRef?.activePlayerIndex ?? 0
                            iconsPath: popup.iconsPath
                            onPlayerChanged: (index, direction) => {
                                popup._slideBackward = direction < 0
                                if (popup.widgetRef)
                                    popup.widgetRef.activePlayerIndex = index
                            }
                        }
                    }
                }
            }

            Item {
                width: volumeFade.width
                height: popupRow.height

                MusicFadePanel {
                    id: volumeFade
                    anchors.verticalCenter: parent.verticalCenter
                    panelWidth: popup.volumePanelWidth
                    height: volumePanel.implicitHeight
                    shown: popup.volumeOpen && popup.volumeSupported

                    MusicVolumePanel {
                        id: volumePanel
                        player: popup.player
                    }
                }
            }
        }
    }
}