import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../components"

TextField {
    id: root
    font.family: Theme.fontFamily

    property color accentColor: Theme.primary
    property string iconSource: AppPaths.iconsDir + "magnifying.svg"
    property int iconSize: 18

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    leftPadding: 44
    rightPadding: 16
    color: Theme.inkSurf
    placeholderTextColor: Theme.inkSurfVar
    font.pixelSize: 15
    activeFocusOnPress: true

    SvgIcon {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        source: root.iconSource
        size: root.iconSize
        tint: root.activeFocus ? root.accentColor : Theme.inkSurfVar
        Behavior on tint { ColorAnimation { duration: 150 } }
    }

    background: Rectangle {
        radius: 24
        color: Theme.surfaceVariant
        border.width: 1
        border.color: root.activeFocus ? root.accentColor : Theme.outline
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
