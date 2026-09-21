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

    readonly property var engines: [
        { id: "google", name: "Google", prefix: "", url: "https://www.google.com/search?q=%1" },
        { id: "ddg", name: "DuckDuckGo", prefix: "ddg", url: "https://duckduckgo.com/?q=%1" },
        { id: "yt", name: "YouTube", prefix: "yt", url: "https://www.youtube.com/results?search_query=%1" },
        { id: "gh", name: "GitHub", prefix: "gh", url: "https://github.com/search?q=%1" },
        { id: "fd", name: "Fedora Docs", prefix: "fd", url: "https://docs.fedoraproject.org/en-US/search/?q=%1" },
        { id: "wiki", name: "Wikipedia", prefix: "wiki", url: "https://en.wikipedia.org/w/index.php?search=%1" }
    ]

    function looksLikeUrl(value) {
        if (/\s/.test(value))
            return false
        return /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(value)
            || /^[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(value)
    }

    function normalizeUrl(value) {
        return /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(value) ? value : ("https://" + value)
    }

    function refresh() {
        const raw = root.query.trim()
        const out = []

        if (raw === "") {
            root.results = out
            root.currentIndex = -1
            return
        }

        let engine = root.engines[0]
        let term = raw
        const sp = raw.indexOf(" ")
        if (sp > 0) {
            const head = raw.substring(0, sp).toLowerCase()
            const found = root.engines.find(e => e.prefix !== "" && e.prefix === head)
            if (found) {
                engine = found
                term = raw.substring(sp + 1).trim()
            }
        }

        if (term === "") {
            root.results = out
            root.currentIndex = -1
            return
        }

        if (root.looksLikeUrl(term)) {
            const url = root.normalizeUrl(term)
            out.push({
                kind: "url",
                label: "Open " + url,
                sublabel: "Zen Browser",
                url: url,
                icon: AppPaths.iconsDir + "globe.svg"
            })
        }

        const ordered = [engine].concat(root.engines.filter(e => e !== engine))
        for (let i = 0; i < ordered.length; i++) {
            const e = ordered[i]
            out.push({
                kind: "search",
                label: "Search " + e.name + " for \u201c" + term + "\u201d",
                sublabel: e.url.split("/")[2],
                url: e.url.replace("%1", encodeURIComponent(term)),
                icon: AppPaths.iconsDir + "magnifying.svg"
            })
        }

        root.results = out
        root.currentIndex = 0
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

    function activateCurrent(isPrivate) {
        const result = root.results[root.currentIndex]
        if (!result)
            return
        Quickshell.execDetached(["zen-browser", isPrivate ? "--private-window" : "--new-tab", result.url])
        root.launched()
    }

    onQueryChanged: refresh()
    Component.onCompleted: refresh()

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
            height: 52
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

                SvgIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    source: modelData.icon
                    size: 20
                    tint: index === root.currentIndex ? Theme.primary : Theme.inkSurfVar
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: index === root.currentIndex ? Theme.primary : Theme.inkSurf
                        font.pixelSize: 13
                        font.bold: index === root.currentIndex
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.sublabel
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
                    root.activateCurrent(false)
                }
                onEntered: root.currentIndex = index
            }
        }
    }

    Column {
        anchors.centerIn: parent
        width: 280
        spacing: 6
        visible: root.results.length === 0

        SvgIcon {
            x: (parent.width - width) / 2
            source: AppPaths.iconsDir + "globe.svg"
            size: 30
            tint: Theme.inkSurfVar
            opacity: 0.35
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Type to search with Zen"
            color: Theme.inkSurfVar
            font.pixelSize: 13
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Prefixes: ddg \u00b7 yt \u00b7 gh \u00b7 fd \u00b7 wiki"
            color: Theme.inkSurfVar
            font.pixelSize: 10
            opacity: 0.6
        }
    }
}
