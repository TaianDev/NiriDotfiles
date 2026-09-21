pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: paths
    visible: false

    property string homeDir: ""
    readonly property string wallpapersPath: homeDir + "/Pictures/Wallpapers"
    readonly property string iconsDir: Qt.resolvedUrl("../assets/icons/")
    readonly property string themeFilePath: homeDir !== ""
        ? homeDir + "/.config/quickshell/Theme.qml"
        : ""

    Component.onCompleted: homeResolver.running = true

    Process {
        id: homeResolver
        command: ["bash", "-c", "echo -n \"$HOME\""]
        stdout: StdioCollector {
            onStreamFinished: paths.homeDir = this.text.trim()
        }
    }
}
