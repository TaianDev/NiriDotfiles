import QtQuick
import "../core"

Item {
    id: root

    property alias content: contentItem.children
    property alias contentItem: contentItem

    property bool hoverEffect: true
    property bool gradient: false
    property color pillColor: Theme.barPillBackgroundColor()

    implicitHeight: 28
    implicitWidth: contentItem.width + 24

    readonly property color _hoverColor: Qt.rgba(
        pillColor.r * 1.15,
        pillColor.g * 1.15,
        pillColor.b * 1.15,
        pillColor.a
    )

    readonly property color _darkColor: Qt.rgba(
        pillColor.r * 0.88,
        pillColor.g * 0.88,
        pillColor.b * 0.88,
        pillColor.a
    )

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        border.width: Theme.barPillBorderWidth
        border.color: Theme.barPillBorderColor()

        color: root.hoverEffect && hoverMa.containsMouse
            ? root._hoverColor
            : root.pillColor

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.pillColor }
            GradientStop { position: 1.0; color: root.gradient ? root._darkColor : root.pillColor }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Item {
        id: contentItem
        width: childrenRect.width
        height: childrenRect.height
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
    }

    MouseArea {
        id: hoverMa
        anchors.fill: parent
        hoverEnabled: root.hoverEffect
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
    }
}
