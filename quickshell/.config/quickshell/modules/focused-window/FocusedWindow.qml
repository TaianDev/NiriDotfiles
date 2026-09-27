import QtQuick
import Quickshell
import "../../core"
import "../../components"
import "../../services"

Item {
    id: root

    // Focused window from NiriData (niri uses `app_id`).
    readonly property var win: NiriData.focusedWindow
    readonly property string windowTitle: win?.title ?? ""
    readonly property string windowAppId: win?.app_id ?? ""

    function formatAppId(raw) {
        if (!raw) return "niri"
        const parts = raw.split(".")
        const last = parts[parts.length - 1]
        return last.charAt(0).toUpperCase() + last.slice(1) + " - niri"
    }

    function formatTitle(raw) {
        if (!raw) return "Desktop - niri"
        if (raw.length > 37) return raw.substring(0, 25) + "..."
        return raw
    }

    readonly property string displayAppId: formatAppId(windowAppId)
    readonly property string displayTitle: formatTitle(windowTitle)

    property bool _inited: false

    onDisplayTitleChanged: {
        if (!_inited) return
        fadeAnim.restart()
    }

    SequentialAnimation {
        id: fadeAnim
        PropertyAnimation { target: textColumn; property: "opacity"; to: 0.4; duration: 60 }
        PropertyAnimation { target: textColumn; property: "opacity"; to: 1.0; duration: 100 }
    }

    Component.onCompleted: {
        Qt.callLater(() => _inited = true)
    }

    implicitHeight: 28
    implicitWidth: Math.min(textRow.implicitWidth, 260)

    Row {
        id: textRow
        height: parent.height
        spacing: 6

        SvgIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: AppPaths.iconsDir + "fedora.svg"
            size: 16
            tint: Theme.inkSurf
        }

        Column {
            id: textColumn
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            AppText {
                text: root.displayAppId
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 9
            }

            AppText {
                text: root.displayTitle
                color: Theme.inkSurf
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }
    }
}
