import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"

// Píldora compacta de volumen: icono (mute) + slider corto + porcentaje.
Rectangle {
    id: root

    property real volume: 0
    property bool muted: false
    property bool enabled: true

    signal muteToggled()
    signal moved(real value)

    implicitHeight: 28
    implicitWidth: row.implicitWidth + 20
    radius: 14
    color: Theme.alpha(Theme.surfaceVariant, 0.5)
    border.width: 1
    border.color: Theme.alpha(Theme.outline, 0.25)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        SvgIcon {
            source: AppPaths.iconsDir + (root.muted ? "no-volume.svg" : "volume.svg")
            size: 14
            tint: root.muted ? Theme.err : Theme.inkSurfVar

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.muteToggled()
            }
        }

        FlatSlider {
            Layout.preferredWidth: 90
            enabled: root.enabled
            value: root.volume
            onMoved: val => root.moved(val)
        }

        AppText {
            Layout.preferredWidth: 30
            text: Math.round(root.volume * 100) + "%"
            color: Theme.inkSurfVar
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
        }
    }
}
