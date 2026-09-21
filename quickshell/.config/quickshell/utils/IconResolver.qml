pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property var windowAliases: ({
        "Spotify": ["spotify", "com.spotify.Client"],
        "spotify": ["spotify", "com.spotify.Client"],
        "zen": ["zen-browser", "io.github.zen_browser.zen"],
        "cursor": ["cursor", "co.anysphere.cursor", "visual-studio-code", "code"],
        "code": ["code", "visual-studio-code"],
        "Code": ["code", "visual-studio-code"],
        "firefox": ["firefox"],
        "chromium": ["chromium", "google-chrome"],
        "google-chrome": ["google-chrome"],
        "kitty": ["kitty"],
        "foot": ["foot"],
        "alacritty": ["Alacritty", "alacritty"]
    })

    readonly property var playerAliases: ({
        "zen": ["zen-browser", "io.github.zen_browser.zen"],
        "firefox": ["firefox"],
        "spotify": ["spotify"],
        "vlc": ["vlc"],
        "mpv": ["mpv"],
        "chromium": ["chromium", "google-chrome"],
        "google-chrome": ["google-chrome"],
        "tidal": ["tidal", "com.tidal.Tidal"]
    })

    function resolveThemeIcon(name) {
        if (!name || typeof name !== "string" || name.trim() === "")
            return ""
        if (!Quickshell.hasThemeIcon(name))
            return ""
        const path = Quickshell.iconPath(name)
        return path !== "" ? path : ""
    }

    function addCandidate(list, seen, name) {
        if (!name || typeof name !== "string")
            return
        name = name.trim()
        if (name === "" || seen[name])
            return
        seen[name] = true
        list.push(name)
    }

    function windowIconCandidates(win) {
        const out = []
        const seen = {}
        // niri exposes `app_id`; Hyprland used `class`/`initialClass`.
        const cls = win?.app_id ?? win?.class ?? ""
        const initial = win?.initialClass ?? ""

        addCandidate(out, seen, cls)
        addCandidate(out, seen, initial)
        addCandidate(out, seen, cls.toLowerCase())
        addCandidate(out, seen, initial.toLowerCase())

        const keys = [cls, initial, cls.toLowerCase(), initial.toLowerCase()]
        for (let k = 0; k < keys.length; k++) {
            const mapped = root.windowAliases[keys[k]]
            if (!mapped)
                continue
            for (let i = 0; i < mapped.length; i++)
                addCandidate(out, seen, mapped[i])
        }

        const lookupId = cls || initial
        if (lookupId !== "") {
            const entry = DesktopEntries.byId(lookupId)
            if (entry?.icon)
                addCandidate(out, seen, entry.icon)

            const heuristic = DesktopEntries.heuristicLookup(lookupId)
            if (heuristic?.icon)
                addCandidate(out, seen, heuristic.icon)
            if (heuristic?.id) {
                const hEntry = DesktopEntries.byId(heuristic.id)
                if (hEntry?.icon)
                    addCandidate(out, seen, hEntry.icon)
            }
        }

        return out
    }

    function playerIconCandidates(mprisPlayer) {
        const out = []
        const seen = {}

        const playerName = mprisPlayer.playerName ?? ""
        const desktopId = mprisPlayer.desktopEntry ?? ""
        const identity = mprisPlayer.identity ?? ""
        const baseName = playerName.split(".")[0]
        const aliasKey = baseName.toLowerCase()

        for (const id of [desktopId, baseName]) {
            if (!id)
                continue
            const entry = DesktopEntries.byId(id)
            if (entry?.icon)
                addCandidate(out, seen, entry.icon)
            if (id.toLowerCase() !== aliasKey || !root.playerAliases[aliasKey])
                addCandidate(out, seen, id)
        }

        if (root.playerAliases[aliasKey]) {
            for (let i = 0; i < root.playerAliases[aliasKey].length; i++)
                addCandidate(out, seen, root.playerAliases[aliasKey][i])
        } else {
            addCandidate(out, seen, playerName)
            addCandidate(out, seen, baseName)
            addCandidate(out, seen, baseName.toLowerCase())
        }

        if (identity !== "" && !root.playerAliases[aliasKey]) {
            addCandidate(out, seen, identity.replace(/\s+/g, "-").toLowerCase())
            addCandidate(out, seen, identity.replace(/\s+/g, "").toLowerCase())
        }

        if (!root.playerAliases[aliasKey]) {
            const heuristic = DesktopEntries.heuristicLookup(
                desktopId || playerName || identity)
            if (heuristic?.icon && heuristic.icon !== aliasKey)
                addCandidate(out, seen, heuristic.icon)
        }

        return out
    }

    function resolveIconFromCandidates(candidates) {
        for (let i = 0; i < candidates.length; i++) {
            const name = candidates[i]
            if (!name || name === "" || name === "zen" || name.includes(" "))
                continue
            const path = root.resolveThemeIcon(name)
            if (path !== "")
                return path
        }
        return ""
    }

    function fallbackAppIcon() {
        const names = [
            "application-x-executable",
            "application-default-icon",
            "preferences-system-windows",
            "window-new"
        ]
        for (let i = 0; i < names.length; i++) {
            const path = root.resolveThemeIcon(names[i])
            if (path !== "")
                return path
        }
        return ""
    }

    function iconForWindow(win) {
        if (!win)
            return ""

        const candidates = root.windowIconCandidates(win)
        const result = root.resolveIconFromCandidates(candidates)
        return result !== "" ? result : root.fallbackAppIcon()
    }

    function notificationIcon(notif) {
        if (!notif)
            return ""

        const names = []
        const seen = {}

        addCandidate(names, seen, notif.appIcon)
        addCandidate(names, seen, notif.desktopEntry)
        if (notif.appName)
            addCandidate(names, seen, notif.appName.toLowerCase().replace(/\s+/g, "-"))

        return resolveIconFromCandidates(names)
    }
}
