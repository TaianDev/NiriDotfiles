pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MediaService — reproductor MPRIS activo compartido entre la barra y el hub.
// Así el selector del hub y la píldora de música quedan sincronizados.
Item {
    id: root
    visible: false

    property int activePlayerIndex: 0

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: players.length > 0
        ? players[Math.max(0, Math.min(root.activePlayerIndex, players.length - 1))]
        : null

    onPlayersChanged: {
        if (root.activePlayerIndex >= root.players.length)
            root.activePlayerIndex = Math.max(0, root.players.length - 1)
    }

    function count() { return root.players.length }

    function cycle(delta) {
        const n = root.players.length
        if (n <= 1)
            return
        root.activePlayerIndex = (root.activePlayerIndex + delta + n) % n
    }
}
