import QtQuick
import Quickshell.Io

Item {
    id: loader
    visible: false

    property string themePath: AppPaths.themeFilePath

    FileView {
        id: themeFile
        path: loader.themePath
        watchChanges: true
        onLoaded: {
            if (loader.themePath !== "")
                loader.parse(themeFile.text())
        }
        onFileChanged: debounce.restart()
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() {
            if (loader.themePath !== "") {
                themeFile.path = loader.themePath
                themeFile.reload()
            }
        }
    }

    onThemePathChanged: {
        if (themePath !== "")
            themeFile.reload()
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: {
            themeFile.reload()
            if (loader.themePath !== "")
                loader.parse(themeFile.text())
        }
    }

    function parse(text) {
        if (!text || text.length === 0)
            return

        const colors = {}
        const regex = /readonly property color (\w+):\s*"([#][0-9a-fA-F]{6,8})"/g
        let match
        while ((match = regex.exec(text)) !== null)
            colors[match[1]] = match[2]

        if (Object.keys(colors).length >= 10)
            Theme.applyFromParsed(colors)
    }
}
