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

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        AppText {
            Layout.alignment: Qt.AlignHCenter
            text: root.formatSW(root.elapsedMs)
            color: root.textMain
            font.pixelSize: 48
            font.weight: Font.Thin
            style: Text.Outline
            styleColor: Theme.alpha(Theme.inkSurf, 0.2)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // 🌟 Pause / Play button with hover
            Rectangle {
                width: 48; height: 48; radius: 24
                
                // Hover effect: the background gray lightens
                color: playMa.containsMouse ? Qt.lighter(root.bgLighter, 1.4) : root.bgLighter
                Behavior on color { ColorAnimation { duration: 150 } }
                
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + (root.running ? "pause.svg" : "play.svg")
                    size: 20
                    tint: root.textMain
                }
                
                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true // Needed to detect when the mouse hovers over it
                    cursorShape: Qt.PointingHandCursor
                    // Sends the command to the parent
                    onClicked: { if (root.widgetRef) { root.widgetRef.swRunning = !root.widgetRef.swRunning; if (root.widgetRef.swRunning) root.widgetRef.togglePopup() } }
                }
            }

            // 🌟 Stop button with red hover
            Rectangle {
                width: 48; height: 48; radius: 24
                
                // Hover effect: goes from gray to destructive red to indicate "Stop/Clear"
                color: stopMa.containsMouse ? Theme.err : root.bgLighter
                Behavior on color { ColorAnimation { duration: 150 } }
                
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "stop.svg"
                    size: 20
                    tint: root.textMain
                }
                
                MouseArea {
                    id: stopMa
                    anchors.fill: parent
                    hoverEnabled: true // Needed to detect when the mouse hovers over it
                    cursorShape: Qt.PointingHandCursor
                    // Resets the state on the parent
                    onClicked: { 
                        if (root.widgetRef) {
                            root.widgetRef.swRunning = false; 
                            root.widgetRef.swElapsedMs = 0 
                        }
                    }
                }
            }
        }
    }
}