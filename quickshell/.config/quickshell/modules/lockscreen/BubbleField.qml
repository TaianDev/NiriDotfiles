import QtQuick

Canvas {
    id: root

    property int bubbleCount: 12
    property real speed: 3
    property var palette: [
        Qt.rgba(0.506, 0.827, 0.867, 0.15),
        Qt.rgba(0.694, 0.796, 0.812, 0.15),
        Qt.rgba(0.722, 0.776, 0.918, 0.15),
        Qt.rgba(0.506, 0.827, 0.867, 0.15),
        Qt.rgba(0.694, 0.796, 0.812, 0.15),
    ]

    property var bubbles: []

    function initBubbles() {
        bubbles = []
        for (var i = 0; i < bubbleCount; i++) {
            var r = 40 + Math.random() * 40
            bubbles.push({
                x: r + Math.random() * (width - 2 * r),
                y: r + Math.random() * (height - 2 * r),
                vx: (Math.random() - 0.5) * speed,
                vy: (Math.random() - 0.5) * speed,
                r: r,
                color: palette[i % palette.length],
            })
        }
        requestPaint()
    }

    function updatePhysics() {
        var list = bubbles
        var w = width
        var h = height

        for (var i = 0; i < list.length; i++) {
            var b = list[i]

            b.x += b.vx
            b.y += b.vy

            if (b.x - b.r < 0) { b.x = b.r; b.vx = -b.vx }
            if (b.x + b.r > w) { b.x = w - b.r; b.vx = -b.vx }
            if (b.y - b.r < 0) { b.y = b.r; b.vy = -b.vy }
            if (b.y + b.r > h) { b.y = h - b.r; b.vy = -b.vy }
        }

        for (var i = 0; i < list.length; i++) {
            for (var j = i + 1; j < list.length; j++) {
                var a = list[i], b = list[j]
                var dx = b.x - a.x
                var dy = b.y - a.y
                var dist = Math.sqrt(dx * dx + dy * dy)
                var minDist = a.r + b.r

                if (dist < minDist && dist > 0.01) {
                    var nx = dx / dist, ny = dy / dist
                    var overlap = (minDist - dist) / 2

                    a.x -= nx * overlap; a.y -= ny * overlap
                    b.x += nx * overlap; b.y += ny * overlap

                    var dvx = a.vx - b.vx, dvy = a.vy - b.vy
                    var dot = dvx * nx + dvy * ny
                    if (dot > 0) {
                        a.vx -= dot * nx; a.vy -= dot * ny
                        b.vx += dot * nx; b.vy += dot * ny
                    }
                }
            }
        }

        requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d")
        if (!ctx) return

        ctx.clearRect(0, 0, width, height)

        var list = bubbles
        for (var i = 0; i < list.length; i++) {
            var b = list[i]
            ctx.beginPath()
            ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2)
            ctx.fillStyle = b.color
            ctx.fill()
        }
    }

    Timer {
        interval: 16
        repeat: true
        running: root.visible
        onTriggered: {
            if (width > 0 && height > 0 && bubbles.length === 0)
                initBubbles()
            updatePhysics()
        }
    }

    onWidthChanged: { if (bubbles.length > 0) { initBubbles() } }
    onHeightChanged: { if (bubbles.length > 0) { initBubbles() } }
}
