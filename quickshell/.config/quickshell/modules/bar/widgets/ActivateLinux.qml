import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../components"

PanelWindow {
    id: activateLinuxWindow

    // Quickshell will automatically inject 'modelData' (the current monitor)
    // thanks to the Variants block in the main file.
    property var modelData
    screen: modelData

    anchors {
        right: true
        bottom: true
    }

    margins {
        right: 50
        bottom: 50
    }

    implicitWidth: content.width
    implicitHeight: content.height

    color: "transparent"

    // IMPORTANT: Empty mask so clicks pass through the letters
    // and do not block the desktop.
    mask: Region {}

    // The Overlay layer keeps it visible even above games
    // or fullscreen videos.
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: content

        AppText {
            text: "Activate Linux"
            color: "#50ffffff" // Blanco con transparencia
            font.pointSize: 22
        }

        AppText {
            text: "Go to Settings to activate Linux"
            color: "#50ffffff"
            font.pointSize: 14
        }
    }
}