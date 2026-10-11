import QtQuick
import QtQuick.Controls
import "../core"

// MiniComboBox — ComboBox compacto con popup Material You (opaco).
ComboBox {
    id: control

    property int displayWidth: 150

    implicitWidth: displayWidth
    implicitHeight: 40

    font.family: Theme.fontFamily
    font.pixelSize: 12

    contentItem: Text {
        leftPadding: 14
        rightPadding: 24
        text: control.displayText
        color: Theme.inkSurf
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - 12
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "\u25be"
        color: Theme.inkSurfVar
        font.pixelSize: 12
    }

    background: Rectangle {
        radius: 20
        color: Theme.surfaceVariant
        border.width: 1
        border.color: Theme.outlineVariant
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: ListView.view ? ListView.view.width : control.width
        implicitHeight: 34
        highlighted: control.highlightedIndex === index

        contentItem: Text {
            leftPadding: 14
            text: modelData
            color: itemDelegate.highlighted ? Theme.inkSecCont : Theme.inkSurf
            font.family: Theme.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 8
            color: itemDelegate.highlighted ? Theme.secondaryContainer : "transparent"
        }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 34 * 8 + 8)
        padding: 4

        background: Rectangle {
            radius: 12
            color: Theme.surfaceVariant
            border.width: 1
            border.color: Theme.outlineVariant
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        onOpened: contentItem.positionViewAtIndex(control.highlightedIndex, ListView.Center)
    }
}
