import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../components"

Item {
    id: root

    property string currentCode: ""
    property string currentName: ""
    property var entries: []
    property int itemHeight: 36
    property int maxVisible: 8
    property int radius: 8
    property bool capsule: false

    property bool open: false

    signal selected(string code, string name)
    signal opened()

    implicitWidth: 120
    implicitHeight: 32

    onOpenChanged: {
        if (root.open) {
            root.opened()
            dropdown.open()
        } else {
            dropdown.close()
        }
    }

    function findName(code) {
        for (let i = 0; i < root.entries.length; i++) {
            if (root.entries[i].code === code) return root.entries[i].name
        }
        return code
    }

    onCurrentCodeChanged: {
        root.currentName = root.findName(root.currentCode)
    }

    Component.onCompleted: {
        root.currentName = root.findName(root.currentCode)
    }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: root.radius
        color: root.open
               ? Theme.alpha(Theme.primary, 0.28)
               : (pillMa.containsMouse
                  ? Theme.alpha(Theme.primary, 0.22)
                  : (root.capsule ? Theme.alpha(Theme.primary, 0.10) : "transparent"))
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: root.currentName
                color: Theme.inkSurf
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            SvgIcon {
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                source: AppPaths.iconsDir + "down.svg"
                size: 12
                tint: "#FFFFFF"
                rotation: root.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: pillMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }

    Popup {
        id: dropdown
        x: 0
        y: root.height + 4
        width: root.width
        height: Math.min(listView.contentHeight, root.itemHeight * root.maxVisible) + 8
        padding: 0
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose

        onClosed: {
            if (root.open) root.open = false
        }

        background: Rectangle {
            radius: 12
            color: Theme.surfaceVariant
            border.width: 1
            border.color: Theme.outlineVariant
        }

        contentItem: ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 4
            model: root.entries
            currentIndex: -1
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                width: listView.width
                height: root.itemHeight
                radius: 8
                color: itemMa.containsMouse
                       ? Theme.alpha(Theme.primary, 0.12)
                       : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: modelData.code === root.currentCode ? Theme.primary : Theme.inkSurf
                    font.pixelSize: 12
                    font.weight: modelData.code === root.currentCode ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.open = false
                        root.selected(modelData.code, modelData.name)
                    }
                }
            }
        }
    }
}
