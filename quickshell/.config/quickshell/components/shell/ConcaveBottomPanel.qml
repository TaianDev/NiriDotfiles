import QtQuick
import QtQuick.Shapes
import "../../core"

Item {
    id: root

    property real panelWidth: 600
    property real panelHeight: 500
    default property alias content: contentSlot.data

    width: panelWidth
    height: panelHeight

    Item {
        id: mainBody
        anchors.fill: parent

        Shape {
            anchors.fill: parent
            anchors.leftMargin: -20
            anchors.rightMargin: -20
            antialiasing: true
            layer.enabled: true
            layer.samples: 8

            ShapePath {
                fillColor: Theme.alpha(Theme.background, 0.9)
                strokeWidth: 0
                startX: 0; startY: mainBody.height
                PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                PathLine { x: 20; y: 20 }
                PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                PathLine { x: root.panelWidth; y: 0 }
                PathArc { x: root.panelWidth + 20; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                PathLine { x: root.panelWidth + 20; y: mainBody.height - 20 }
                PathQuad { x: root.panelWidth + 40; y: mainBody.height; controlX: root.panelWidth + 20; controlY: mainBody.height }
                PathLine { x: 0; y: mainBody.height }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.alpha(Theme.outlineVariant, 0.9)
                strokeWidth: 1.2
                startX: 0; startY: mainBody.height
                PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                PathLine { x: 20; y: 20 }
                PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                PathLine { x: root.panelWidth; y: 0 }
                PathArc { x: root.panelWidth + 20; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                PathLine { x: root.panelWidth + 20; y: mainBody.height - 20 }
                PathQuad { x: root.panelWidth + 40; y: mainBody.height; controlX: root.panelWidth + 20; controlY: mainBody.height }
            }
        }

        Item {
            id: contentSlot
            anchors.fill: parent
        }
    }
}
