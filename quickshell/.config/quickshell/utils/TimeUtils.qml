pragma Singleton
import QtQuick

QtObject {
    id: root

    function padZero(n, width) {
        return n.toString().padStart(width, '0')
    }

    function formatTimeAgo(ms) {
        if (!ms || ms <= 0)
            return ""

        const diff = Math.max(0, Date.now() - ms)
        const mins = Math.floor(diff / 60000)
        if (mins < 1)
            return "now"
        if (mins < 60)
            return mins + "m"
        const hrs = Math.floor(mins / 60)
        if (hrs < 24)
            return hrs + "h"
        return Math.floor(hrs / 24) + "d"
    }

    function formatMSS(ms) {
        const m = Math.floor(ms / 60000)
        const s = Math.floor((ms % 60000) / 1000)
        return padZero(m, 2) + ":" + padZero(s, 2)
    }

    function formatHMSSecs(secs) {
        const h = Math.floor(secs / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const s = Math.floor(secs % 60)
        if (h > 0)
            return h + ":" + padZero(m, 2) + ":" + padZero(s, 2)
        return padZero(m, 2) + ":" + padZero(s, 2)
    }

    function formatMMSS(secs) {
        const s = Math.floor(secs) % 60
        const m = Math.floor(secs / 60)
        return m + ":" + padZero(s, 2)
    }
}
