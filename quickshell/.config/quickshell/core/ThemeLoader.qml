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
        // The generated file only exists after the first wallpaper is applied.
        // Suppress the "file does not exist" warning until it has loaded once.
        printErrors: themeFile.loaded
        onLoaded: {
            retry.stop()
            if (loader.themePath !== "")
                loader.parse(themeFile.text())
        }
        onFileChanged: debounce.restart()
        onLoadFailed: retry.start()
    }

    // watchChanges cannot observe a file that does not exist yet, so poll until
    // matugen creates it (then stop).
    Timer {
        id: retry
        interval: 2000
        repeat: true
        onTriggered: {
            themeFile.reload()
            if (themeFile.loaded)
                retry.stop()
        }
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
