import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"

Item {
    id: root

    property color textMain: Theme.inkSurf
    property color bgLighter: Theme.surfaceVariant
    property string iconsPath: widgetRef ? widgetRef.iconsPath : Qt.resolvedUrl("../../assets/icons/")

    // 🌟 Receives the centralized reference
    property var widgetRef: null

    // Reads the real values from the bar
    property int elapsedMs: widgetRef ? widgetRef.swElapsedMs : 0
    property bool running: widgetRef ? widgetRef.swRunning : false

    function formatSW(ms) {
        let h = Math.floor(ms / 3600000).toString().padStart(2, '0')
        let m = Math.floor((ms % 3600000) / 60000).toString().padStart(2, '0')
        let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
        let d = Math.floor((ms % 1000) / 100)
        return h + ":" + m + ":" + s + "." + d
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        AppText {
            Layout.fillWidth: true
            text: root.formatSW(root.elapsedMs)
            color: root.textMain
            font.pixelSize: 26
            font.weight: Font.Thin
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        // Pause / Play
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 34; height: 34; radius: 17
            color: playMa.containsMouse ? Qt.lighter(root.bgLighter, 1.4) : root.bgLighter
            Behavior on color { ColorAnimation { duration: 150 } }

            SvgIcon {
                anchors.centerIn: parent
                source: root.iconsPath + (root.running ? "pause.svg" : "play.svg")
                size: 16
                tint: root.textMain
            }

            MouseArea {
                id: playMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.widgetRef) root.widgetRef.swRunning = !root.widgetRef.swRunning }
            }
        }

        // Stop
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 34; height: 34; radius: 17
            color: stopMa.containsMouse ? Theme.err : root.bgLighter
            Behavior on color { ColorAnimation { duration: 150 } }

            SvgIcon {
                anchors.centerIn: parent
                source: root.iconsPath + "stop.svg"
                size: 16
                tint: root.textMain
            }

            MouseArea {
                id: stopMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.widgetRef) {
                        root.widgetRef.swRunning = false
                        root.widgetRef.swElapsedMs = 0
                    }
                }
            }
        }
    }
}
