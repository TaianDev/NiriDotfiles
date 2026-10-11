import QtQuick
import Qt5Compat.GraphicalEffects
import "../core"

// Píldora de título de sección: icono + texto, pequeña pero evidente.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property int iconSize: 12
    property int fontSize: 11

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24
    radius: 999
    color: Theme.alpha(Theme.inkSurf, 0.06)
    border.width: 1
    border.color: Theme.alpha(Theme.inkSurf, 0.08)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            width: root.iconSize
            height: root.iconSize

            Image {
                anchors.fill: parent
                source: root.icon !== "" ? AppPaths.iconsDir + root.icon : ""
                sourceSize.width: root.iconSize
                sourceSize.height: root.iconSize
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: Theme.primary }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Theme.inkSurf
            font.family: Theme.fontFamily
            font.pixelSize: root.fontSize
            font.bold: true
        }
    }
}
