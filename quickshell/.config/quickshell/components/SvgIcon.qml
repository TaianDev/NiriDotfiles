// SvgIcon.qml — SVG icon with a color tint
import QtQuick
import Qt5Compat.GraphicalEffects
import "../core"

Item {
    property string source: ""
    property int    size:   14
    property color  tint:   Theme.inkSurf

    width: size; height: size

    Image {
        id: img
        anchors.fill: parent
        source: parent.source
        sourceSize.width:  parent.size
        sourceSize.height: parent.size
        fillMode: Image.PreserveAspectFit
        cache: true
        layer.enabled: true
        layer.effect: ColorOverlay { color: parent.tint }
    }
}
