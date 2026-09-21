import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }

    property string homeDir: ""
    readonly property string iconsPath: homeDir !== ""
        ? "file://" + homeDir + "/.config/quickshell/assets/icons/"
        : ""
    readonly property string defaultArtPath: homeDir !== ""
        ? "file://" + homeDir + "/.config/quickshell/assets/music-disc.jpg"
        : ""
    readonly property string cavaConfigPath: homeDir !== ""
        ? homeDir + "/.config/quickshell/modules/lockscreen/cava_bar.conf"
        : ""

    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = Math.max(0, playerList.length - 1)
    }

    readonly property var player: playerList.length > 0 ? playerList[activePlayerIndex] : null
    readonly property string trackTitle: player?.trackTitle ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property bool canPrev: player?.canGoPrevious ?? false
    readonly property bool canNext: player?.canGoNext ?? false
    readonly property bool canPlayPause: player?.canTogglePlaying ?? false
    readonly property bool hasPlayer: player !== null && (trackTitle !== "" || trackArtist !== "")
    readonly property string playerName: player?.identity ?? player?.playerName ?? ""

    // ── ART CACHE (from MusicWidget) ─────────────────────────
    property var artCache: ({})
    readonly property string activePkey:
        player?.playerName ?? player?.identity ?? "unknown"
    readonly property string stableArtUrl: artCache[activePkey] ?? ""
    readonly property string liveArtUrl: player?.trackArtUrl ?? ""
    readonly property string resolvedArtUrl: stableArtUrl !== ""
        ? stableArtUrl
        : (liveArtUrl !== "" ? liveArtUrl : "")

    Repeater {
        model: root.playerList
        Item {
            required property var modelData
            readonly property string pkey:
                modelData.playerName ?? modelData.identity ?? "unknown"
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

    // ── PLAYER ICON (from MusicPopup) ───────────────────────
    property string playerIconSrc: ""

    function resolveIconPath(names) {
        for (let i = 0; i < names.length; i++) {
            const name = names[i]
            if (!name || name === "" || name === "zen" || name.includes(" "))
                continue
            if (Quickshell.hasThemeIcon(name)) {
                const path = Quickshell.iconPath(name)
                if (path !== "") return path
            }
            const path = Quickshell.iconPath(name)
            if (path !== "") return path
        }
        return ""
    }

    function playerIconCandidates(mprisPlayer) {
        const out = []
        const seen = {}
        function add(name) {
            if (!name || seen[name]) return
            seen[name] = true
            out.push(name)
        }
        const playerName = mprisPlayer.playerName ?? ""
        const desktopId  = mprisPlayer.desktopEntry ?? ""
        const identity   = mprisPlayer.identity ?? ""
        const baseName   = playerName.split(".")[0]
        const aliases = {
            "zen":           ["zen-browser", "io.github.zen_browser.zen"],
            "firefox":       ["firefox"],
            "spotify":       ["spotify"],
            "vlc":           ["vlc"],
            "mpv":           ["mpv"],
            "chromium":      ["chromium", "google-chrome"],
            "google-chrome": ["google-chrome"],
            "tidal":         ["tidal", "com.tidal.Tidal"],
        }
        const aliasKey = baseName.toLowerCase()
        for (const id of [desktopId, baseName]) {
            if (!id) continue
            try {
                const entry = DesktopEntries.byId(id)
                if (entry?.icon) add(entry.icon)
            } catch (e) {}
            if (id.toLowerCase() !== aliasKey || !aliases[aliasKey])
                add(id)
        }
        if (aliases[aliasKey]) {
            for (let i = 0; i < aliases[aliasKey].length; i++)
                add(aliases[aliasKey][i])
        } else {
            add(playerName)
            add(baseName)
            add(baseName.toLowerCase())
        }
        if (identity !== "" && !aliases[aliasKey]) {
            add(identity.replace(/\s+/g, "-").toLowerCase())
            add(identity.replace(/\s+/g, "").toLowerCase())
        }
        if (!aliases[aliasKey]) {
            try {
                const heuristic = DesktopEntries.heuristicLookup(
                    desktopId || playerName || identity)
                if (heuristic?.icon && heuristic.icon !== aliasKey)
                    add(heuristic.icon)
            } catch (e) {}
        }
        return out
    }

    function playerIcon(mprisPlayer) {
        if (!mprisPlayer) return ""
        return resolveIconPath(playerIconCandidates(mprisPlayer))
    }

    function updatePlayerIcon() {
        const icon = root.playerIcon(root.player)
        if (icon !== "") {
            root.playerIconSrc = icon
            return
        }
        if (root.iconsPath !== "") {
            root.playerIconSrc = root.iconsPath + "no-music.svg"
        }
    }

    onPlayerChanged: root.updatePlayerIcon()
    onIconsPathChanged: root.updatePlayerIcon()

    // ── Player switch slide animation ──────────────────────
    property int _prevIndex: -1
    property bool _switchReady: false

    onActivePlayerIndexChanged: {
        if (!root._switchReady || _prevIndex < 0) {
            _prevIndex = activePlayerIndex
            return
        }
        const dir = activePlayerIndex > _prevIndex ? 1 : -1
        slideTrans.x = dir * 50
        slideIn.restart()
        _prevIndex = activePlayerIndex
    }

    NumberAnimation {
        id: slideIn
        target: slideTrans
        property: "x"
        to: 0
        duration: 280
        easing.type: Easing.OutCubic
    }

    visible: hasPlayer
    implicitWidth: 380
    implicitHeight: 196

    Component.onCompleted: {
        root.updatePlayerIcon()
        root._switchReady = true
    }

    // ── PILL ─────────────────────────────────────────────────
    Rectangle {
        id: card
        width: parent.width
        height: 196
        radius: 28
        clip: true
        color: alpha(Theme.surface, 0.55)
        border.width: 1.5
        border.color: alpha(Theme.outline, 0.2)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── LEFT: Album Art ──────────────────────────────
            Item {
                Layout.preferredWidth: 180
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 140
                    height: 140
                    radius: 22
                    color: "transparent"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.resolvedArtUrl !== ""
                            ? root.resolvedArtUrl
                            : root.defaultArtPath
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                        asynchronous: true
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 140; height: 140; radius: 22
                        }
                    }
                }
            }

            // ── RIGHT: Info Area ─────────────────────────────
            Item {
                id: infoArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                LockCava {
                    anchors.fill: parent
                    active: root.isPlaying
                    configPath: root.cavaConfigPath
                    z: 0
                }

                Item {
                    id: slideWrapper
                    anchors.fill: parent
                    z: 1
                    clip: true

                    transform: Translate {
                        id: slideTrans
                        x: 0
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 5

                    Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle !== "" ? root.trackTitle : "No title"
                        color: Theme.onBackground
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackArtist !== "" ? root.trackArtist : "Unknown Artist"
                        color: Theme.onBackgroundMuted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                    }

                    Item { Layout.preferredHeight: 6 }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            opacity: root.canPrev ? (prevMa.containsMouse ? 0.55 : 1.0) : 0.25
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                source: root.iconsPath + "rewind.svg"
                                width: 18; height: 18
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.onBackground }
                            }
                            MouseArea {
                                id: prevMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.canPrev ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (root.canPrev) root.player.previous()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 21
                            color: root.canPlayPause ? Theme.primary : alpha(Theme.outline, 0.25)
                            opacity: ppMa.containsMouse && root.canPlayPause ? 0.8 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                source: root.isPlaying
                                    ? root.iconsPath + "pause.svg"
                                    : root.iconsPath + "play.svg"
                                width: 18; height: 18
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.onPrimary }
                            }
                            MouseArea {
                                id: ppMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.canPlayPause ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (root.canPlayPause) root.player.togglePlaying()
                            }
                        }

                        Item {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            opacity: root.canNext ? (nextMa.containsMouse ? 0.55 : 1.0) : 0.25
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                source: root.iconsPath + "rewind.svg"
                                width: 18; height: 18
                                fillMode: Image.PreserveAspectFit
                                rotation: 180
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.onBackground }
                            }
                            MouseArea {
                                id: nextMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.canNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: if (root.canNext) root.player.next()
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 6 }

                    // Player row: ← capsule →
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6
                        visible: root.playerName !== ""

                        Item {
                            Layout.preferredWidth: root.playerList.length > 1 ? 20 : 0
                            Layout.preferredHeight: 20
                            visible: root.playerList.length > 1
                            opacity: plPrevMa.containsMouse ? 0.6 : 0.85
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                source: root.iconsPath + "up.svg"
                                width: 12; height: 12
                                rotation: -90
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.onBackgroundMuted }
                            }
                            MouseArea {
                                id: plPrevMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activePlayerIndex = root.activePlayerIndex > 0
                                        ? root.activePlayerIndex - 1
                                        : root.playerList.length - 1
                                }
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: playerRow.width + 16
                            Layout.preferredHeight: 24
                            radius: 12
                            color: alpha(Theme.primaryContainer, 0.45)
                            border.width: 1
                            border.color: alpha(Theme.outline, 0.2)

                            Row {
                                id: playerRow
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    id: iconImg
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.playerIconSrc
                                    width: 14; height: 14
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    cache: false
                                    visible: status === Image.Ready
                                }

                                Text {
                                    id: playerLabel
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.playerName
                                    color: Theme.onPrimaryContainer
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: root.playerList.length > 1 ? 20 : 0
                            Layout.preferredHeight: 20
                            visible: root.playerList.length > 1
                            opacity: plNextMa.containsMouse ? 0.6 : 0.85
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                source: root.iconsPath + "up.svg"
                                width: 12; height: 12
                                rotation: 90
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.onBackgroundMuted }
                            }
                            MouseArea {
                                id: plNextMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activePlayerIndex = root.activePlayerIndex < root.playerList.length - 1
                                        ? root.activePlayerIndex + 1
                                        : 0
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }
                }
                }
            }
        }
    }
}
