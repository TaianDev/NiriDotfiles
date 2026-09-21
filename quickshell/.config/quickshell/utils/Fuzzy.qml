pragma Singleton
import QtQuick

QtObject {
    id: root

    function isBoundary(text, index) {
        if (index === 0)
            return true
        const c = text.charCodeAt(index - 1)
        return c === 32 || c === 45 || c === 95 || c === 46 || c === 47
            || c === 40 || c === 91 || c === 44 || c === 58
    }

    function match(query, text) {
        if (!query)
            return { score: 0, indices: [] }
        if (!text)
            return null

        const q = String(query).toLowerCase()
        const t = String(text).toLowerCase()
        const indices = []

        let qi = 0
        let score = 0
        let consecutive = 0

        for (let i = 0; i < t.length && qi < q.length; i++) {
            if (t[i] === q[qi]) {
                indices.push(i)
                consecutive++
                score += 10 + consecutive * 3
                if (root.isBoundary(text, i))
                    score += 8
                if (i === 0)
                    score += 12
                qi++
            } else {
                consecutive = 0
                score -= 1
            }
        }

        if (qi < q.length)
            return null

        score += Math.max(0, 24 - text.length)
        if (t.startsWith(q))
            score += 30

        return { score: score, indices: indices }
    }

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
    }

    function highlight(text, indices, color) {
        const value = String(text ?? "")
        if (!indices || indices.length === 0)
            return root.escapeHtml(value)

        const set = {}
        for (let i = 0; i < indices.length; i++)
            set[indices[i]] = true

        const colorStr = String(color ?? "")
        let out = ""
        for (let i = 0; i < value.length; i++) {
            const ch = root.escapeHtml(value[i])
            if (set[i])
                out += "<font color=\"" + colorStr + "\"><b>" + ch + "</b></font>"
            else
                out += ch
        }
        return out
    }
}
