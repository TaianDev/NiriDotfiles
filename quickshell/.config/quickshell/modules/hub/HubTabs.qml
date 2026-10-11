import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"

// Selector de sección del hub: Home / Date / Task (centrado, con cerrar a la derecha).
Item {
    id: root

    property int current: 0
    signal sectionSelected(int section)
    signal closeRequested()

    implicitHeight: 30

    readonly property var sections: [
        { label: "Home", icon: "apps.svg" },
        { label: "Date", icon: "calendar.svg" },
        { label: "Tasks", icon: "tasks.svg" }
    ]

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: root.sections

            Rectangle {
                required property var modelData
                required property int index

                width: row.implicitWidth + 22
                height: 30
                radius: 15
                color: index === root.current
                    ? Theme.alpha(Theme.primary, 0.20)
                    : (ma.containsMouse ? Theme.alpha(Theme.inkSurf, 0.07) : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 6

                    SvgIcon {
                        source: AppPaths.iconsDir + modelData.icon
                        size: 14
                        tint: index === root.current ? Theme.primary : Theme.inkSurfVar
                    }

                    AppText {
                        text: modelData.label
                        color: index === root.current ? Theme.inkSurf : Theme.inkSurfVar
                        font.pixelSize: 12
                        font.weight: index === root.current ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionSelected(index)
                }
            }
        }
    }
}
