import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../utils"
import "../../components"

Item {
    id: root

    property string query: ""
    property int currentIndex: 0
    property var results: []

    signal copied()

    readonly property var currentEntry: root.results[root.currentIndex]?.entry ?? null

    function oneLine(value) {
        return String(value ?? "").replace(/\s+/g, " ").trim()
    }

    function formatBytes(n) {
        if (!n || n <= 0)
            return ""
        if (n < 1024)
            return n + " B"
        if (n < 1024 * 1024)
            return (n / 1024).toFixed(1) + " KB"
        return (n / (1024 * 1024)).toFixed(1) + " MB"
    }

    function refresh() {
        const q = root.query.trim()
        const src = ClipboardService.entries
        const out = []

        for (let i = 0; i < src.length; i++) {
            const entry = src[i]
            if (q === "") {
                out.push({ entry: entry, srcIndex: i, score: 0 })
                continue
            }

            if (entry.type === "image") {
                const match = Fuzzy.match(q.toLowerCase(), ("image " + (entry.mime ?? "")).toLowerCase())
                if (match)
                    out.push({ entry: entry, srcIndex: i, score: match.score })
            } else {
                const match = Fuzzy.match(q, entry.preview ?? "")
                if (match)
                    out.push({ entry: entry, srcIndex: i, score: match.score })
            }
        }

        if (q !== "")
            out.sort((a, b) => b.score - a.score)

        root.results = out
        root.currentIndex = out.length > 0 ? 0 : -1
        list.positionViewAtBeginning()
    }

    function moveSelection(delta) {
        if (root.results.length === 0)
            return
        let idx = root.currentIndex + delta
        if (idx < 0)
            idx = 0
        if (idx >= root.results.length)
            idx = root.results.length - 1
        root.currentIndex = idx
        list.positionViewAtIndex(idx, ListView.Contain)
    }

    function copyCurrent() {
        const result = root.results[root.currentIndex]
        if (!result)
            return
        ClipboardService.copyEntry(result.entry)
        root.copied()
    }

    function removeCurrent() {
        const result = root.results[root.currentIndex]
        if (!result)
            return
        if (result.srcIndex !== undefined && result.srcIndex >= 0)
            ClipboardService.removeAt(result.srcIndex)
        else
            ClipboardService.removeByHash(result.entry ? result.entry.hash : "")
    }

    function clearAll() {
        ClipboardService.clear()
    }

    onQueryChanged: refresh()
    Component.onCompleted: refresh()

    Connections {
        target: ClipboardService
        function onEntriesChanged() { root.refresh() }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Item {
            id: listHost
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 4
                model: root.results
                interactive: false
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property var entry: modelData.entry

                    width: list.width
                    height: entry.type === "image" ? 72 : 56
                    radius: 12
                    color: index === root.currentIndex
                        ? Theme.alpha(Theme.primary, 0.18)
                        : (rowMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.06) : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 8
                            color: Theme.alpha(Theme.surfaceVariant, 0.4)
                            clip: true

                            Image {
                                anchors.fill: parent
                                visible: entry.type === "image"
                                source: entry.type === "image" ? ("file://" + entry.file) : ""
                                sourceSize: Qt.size(96, 96)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            SvgIcon {
                                anchors.centerIn: parent
                                visible: entry.type !== "image"
                                source: AppPaths.iconsDir + "clipboard-attachment.svg"
                                size: 20
                                tint: Theme.inkSurfVar
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            AppText {
                                Layout.fillWidth: true
                                text: entry.type === "image"
                                    ? "Image \u00b7 " + root.oneLine(entry.mime ?? "").replace("image/", "").toUpperCase()
                                    : root.oneLine(entry.preview ?? "")
                                color: Theme.inkSurf
                                font.pixelSize: entry.type === "image" ? 12 : 13
                                font.bold: index === root.currentIndex
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: Qt.formatDateTime(new Date((entry.ts ?? 0) * 1000), "HH:mm")
                                    + (entry.type === "image"
                                        ? (root.formatBytes(entry.size) !== "" ? " \u00b7 " + root.formatBytes(entry.size) : "")
                                        : (entry.length ? " \u00b7 " + entry.length + " chars" : ""))
                                color: Theme.inkSurfVar
                                font.pixelSize: 10
                                opacity: 0.6
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = index
                            root.copyCurrent()
                        }
                        onEntered: root.currentIndex = index
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: ClipboardService.entries.length === 0 ? "Clipboard history is empty" : "No matches"
                color: Theme.inkSurfVar
                font.pixelSize: 13
            }
        }

        ClipboardPreview {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            entry: root.currentEntry
        }
    }
}
