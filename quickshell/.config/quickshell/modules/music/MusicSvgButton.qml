import QtQuick
import Qt5Compat.GraphicalEffects
import "../../core"

Item {
    id: btn

    property int    size:       24
    property string iconPath:   ""
    property int    iconRot:    0
    property bool   btnEnabled: true
    property bool   toggled:    false
    property color  iconColor:  Theme.inkSurfVar
    property string kind:       "ghost"
    property bool   acceptRight: false

    signal clicked()
    signal rightClicked()

    readonly property bool isFab: btn.kind === "fab"

    readonly property color effColor: btn.isFab
        ? Theme.onPrimaryContainer
        : (btn.toggled ? Theme.primary : btn.iconColor)

    width: size
    height: size
    opacity: btn.btnEnabled ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: 120 } }

    scale: ma.pressed ? 0.92 : (ma.containsMouse && btn.isFab ? 1.06 : 1.0)
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

    layer.enabled: btn.isFab
    layer.effect: DropShadow {
        transparentBorder: true
        radius: 8
        samples: 16
        horizontalOffset: 0
        verticalOffset: 2
        color: Qt.rgba(0, 0, 0, 0.3)
    }

    Rectangle {
        id: bgCircle
        anchors.fill: parent
        radius: width / 2
        color: btn.isFab
            ? Theme.primaryContainer
            : (ma.containsMouse && btn.btnEnabled ? Theme.alpha(Theme.outlineVariant, 0.3) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Image {
        anchors.centerIn: parent
        width: btn.isFab ? btn.size * 0.55 : btn.size * 0.75
        height: btn.isFab ? btn.size * 0.55 : btn.size * 0.75
        source: btn.iconPath
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        rotation: btn.iconRot
        cache: true
        asynchronous: true
        layer.enabled: true
        layer.effect: ColorOverlay { color: btn.effColor }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: btn.acceptRight ? (Qt.LeftButton | Qt.RightButton) : Qt.LeftButton
        cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                btn.rightClicked()
            else if (btn.btnEnabled)
                btn.clicked()
        }
    }
}