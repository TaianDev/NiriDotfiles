import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../services"
import "../../utils"
import "../../components"

Item {
    id: root

    property string query: ""
    property int currentIndex: 0
    property var results: []

    signal launched()

    function refresh() {
        const q = root.query.trim().toLowerCase()
        const apps = DesktopEntries.applications.values
        const out = []

        for (let i = 0; i < apps.length; i++) {
            const entry = apps[i]
            if (!entry || entry.noDisplay)
                continue

            let best = null
            let nameIndices = []

            if (q === "") {
                best = { score: 0, indices: [] }
            } else {
                const nameMatch = Fuzzy.match(q, entry.name ?? "")
                const genericMatch = Fuzzy.match(q, entry.genericName ?? "")
                const keywordsMatch = Fuzzy.match(q, (entry.keywords ?? []).join(" "))
                const commentMatch = Fuzzy.match(q, entry.comment ?? "")

                const candidates = [nameMatch, genericMatch, keywordsMatch, commentMatch]
                    .filter(m => m !== null)
                if (candidates.length === 0)
                    continue

                best = candidates.reduce((a, b) => b.score > a.score ? b : a)
                if (nameMatch)
                    nameIndices = nameMatch.indices
            }

            out.push({
                entry: entry,
                name: entry.name ?? "",
                score: best.score,
                indices: nameIndices
            })
        }

        out.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name))
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

    function activateCurrent(inTerminal) {
        const result = root.results[root.currentIndex]
        if (!result)
            return

        const entry = result.entry
        const cmd = entry.command ?? []
        if (cmd.length === 0)
            return

        LauncherUsage.bump(entry.id)

        if (inTerminal || entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty", "-e"].concat(cmd),
                workingDirectory: entry.workingDirectory ?? ""
            })
        } else {
            entry.execute()
        }

        root.launched()
    }

    function iconFor(entry) {
        const name = entry.icon ?? ""
        if (name === "")
            return IconResolver.fallbackAppIcon()
        if (name.startsWith("/"))
            return "file://" + name
        return "image://icon/" + name
    }

    onQueryChanged: refresh()
    Component.onCompleted: refresh()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refresh()
            // Some entries settle a moment after the signal; refresh again.
            refreshDebounce.restart()
        }
    }

    Connections {
        target: LauncherService
        function onIsOpenedChanged() {
            if (LauncherService.isOpened)
                root.refresh()
        }
    }

    Timer {
        id: refreshDebounce
        interval: 300
        repeat: false
        onTriggered: root.refresh()
    }

    onVisibleChanged: if (root.visible) root.refresh()

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

            width: list.width
            height: 56
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

                Image {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    source: root.iconFor(modelData.entry)
                    sourceSize: Qt.size(28, 28)
                    fillMode: Image.PreserveAspectFit
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    AppText {
                        Layout.fillWidth: true
                        textFormat: Text.StyledText
                        text: Fuzzy.highlight(modelData.name, modelData.indices, Theme.primary)
                        color: Theme.inkSurf
                        font.pixelSize: 14
                        font.bold: index === root.currentIndex
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    AppText {
                        Layout.fillWidth: true
                        text: modelData.entry.comment || modelData.entry.genericName || ""
                        color: Theme.inkSurfVar
                        font.pixelSize: 11
                        opacity: 0.7
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
                    root.activateCurrent(false)
                }
                onEntered: root.currentIndex = index
            }
        }
    }

    AppText {
        anchors.centerIn: parent
        visible: root.results.length === 0
        text: "No applications found"
        color: Theme.inkSurfVar
        font.pixelSize: 13
    }
}
