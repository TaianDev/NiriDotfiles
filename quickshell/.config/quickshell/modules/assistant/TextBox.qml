import QtQuick
import QtQuick.Controls
import "../../core"

Item {
    id: root

    property string text: ""
    property string placeholderText: ""
    property color textColor: Theme.inkSurf
    property color placeholderColor: Theme.alpha(Theme.inkSurfVar, 0.7)
    property color borderColor: Theme.alpha(Theme.outline, 0.35)
    property bool readOnly: false
    property int fontPixelSize: 14
    property bool focused: false

    signal textEdited(string text)
    signal focusStateChanged(bool focused)

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: 14
        color: Theme.alpha(Theme.surfaceVariant, root.readOnly ? 0.35 : 0.6)
        border.width: 1
        border.color: root.borderColor
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentHeight: edit.height
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        TextEdit {
            id: edit
            width: flick.width
            height: Math.max(flick.height, edit.contentHeight)
            padding: 12
            wrapMode: Text.Wrap
            readOnly: root.readOnly
            selectByMouse: true
            activeFocusOnPress: true
            text: root.text
            color: root.textColor
            font.pixelSize: root.fontPixelSize

            onTextEdited: root.textEdited(edit.text)

            onActiveFocusChanged: {
                root.focused = activeFocus
                root.focusStateChanged(activeFocus)
            }

            onCursorRectangleChanged: {
                const cr = edit.cursorRectangle
                if (cr.y + cr.height > flick.contentY + flick.height)
                    flick.contentY = cr.y + cr.height - flick.height
                else if (cr.y < flick.contentY)
                    flick.contentY = cr.y
            }
        }
    }

    Text {
        visible: root.text === ""
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 12
        anchors.leftMargin: 12
        text: root.placeholderText
        color: root.placeholderColor
        font.pixelSize: root.fontPixelSize
    }
}
