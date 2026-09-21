import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../components"

TextField {
    id: root

    property color accentColor: Theme.primary
    property string iconSource: AppPaths.iconsDir + "magnifying.svg"
    property int iconSize: 18

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    leftPadding: 44
    rightPadding: 16
    color: Theme.inkSurf
    placeholderTextColor: Theme.alpha(Theme.inkSurfVar, 0.7)
    font.pixelSize: 15
    activeFocusOnPress: true

    SvgIcon {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        source: root.iconSource
        size: root.iconSize
        tint: root.activeFocus ? root.accentColor : Theme.alpha(Theme.inkSurfVar, 0.7)
        Behavior on tint { ColorAnimation { duration: 150 } }
    }

    background: Rectangle {
        radius: 14
        color: Theme.alpha(Theme.surfaceVariant, 0.6)
        border.width: 1
        border.color: root.activeFocus ? root.accentColor : Theme.alpha(Theme.outline, 0.35)
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
