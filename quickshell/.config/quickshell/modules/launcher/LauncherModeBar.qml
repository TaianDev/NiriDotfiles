import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"

Row {
    id: root

    property int currentMode: 0

    signal modeSelected(int mode)

    spacing: 8

    readonly property var modes: [
        { label: "Apps", icon: "apps.svg" },
        { label: "Wallpapers", icon: "image.svg" },
        { label: "Web", icon: "globe.svg" },
        { label: "Clipboard", icon: "clipboard-attachment.svg" }
    ]

    Repeater {
        model: root.modes

        delegate: Rectangle {
            required property var modelData
            required property int index

            height: 32
            width: chipRow.implicitWidth + 24
            radius: 16
            color: index === root.currentMode
                ? Theme.secondaryContainer
                : (chipMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.06) : "transparent")
            border.width: 1
            border.color: index === root.currentMode ? "transparent" : Theme.outlineVariant
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 6

                SvgIcon {
                    source: AppPaths.iconsDir + modelData.icon
                    size: 15
                    tint: index === root.currentMode ? Theme.inkSecCont : Theme.inkSurfVar
                }

                AppText {
                    text: modelData.label
                    color: index === root.currentMode ? Theme.inkSecCont : Theme.inkSurfVar
                    font.pixelSize: 12
                    font.bold: index === root.currentMode
                }
            }

            MouseArea {
                id: chipMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modeSelected(index)
            }
        }
    }
}
