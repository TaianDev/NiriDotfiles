import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"

ColumnLayout {
    id: root

    property var menuHandle: null
    property bool showBack: false

    signal backRequested()
    signal entryActivated()
    signal contentReady()
    signal submenuRequested(var entry)

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: showBack ? 28 : 0
        visible: showBack
        spacing: 8

        Text {
            text: "‹ Back"
            color: Theme.primary
            font.pixelSize: 12
            font.bold: true
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }
    }

    QsMenuOpener {
        id: menuOpener
    }

    readonly property int contentHeight: {
        let h = showBack ? 28 : 0
        const entries = menuOpener.children.values
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i]
            if (!entry)
                continue
            h += entry.isSeparator ? 7 : 34
        }
        return h
    }

    function bindMenu(handle) {
        menuOpener.menu = null
        if (!handle)
            return
        menuOpener.menu = handle
        if (typeof handle.updateLayout === 'function')
            handle.updateLayout()
        asyncRefreshTimer.restart()
    }

    onMenuHandleChanged: bindMenu(menuHandle)

    Timer {
        id: asyncRefreshTimer
        interval: 120
        repeat: false
        onTriggered: root.contentReady()
    }

    Component.onCompleted: bindMenu(menuHandle)

    Connections {
        target: menuOpener
        function onChildrenChanged() {
            root.contentReady()
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: modelData.isSeparator ? 7 : 34
                    visible: modelData.isSeparator || modelData.text !== ""

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Theme.alpha(Theme.outline, 0.35)
                        visible: modelData.isSeparator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: rowMa.containsMouse
                               ? Theme.alpha(Theme.inkSurf, 0.08)
                               : "transparent"
                        visible: !modelData.isSeparator

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Image {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: modelData.icon
                                sourceSize: Qt.size(16, 16)
                                fillMode: Image.PreserveAspectFit
                                visible: modelData.icon !== ""
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.text
                                color: modelData.enabled ? Theme.inkSurf : Theme.inkSurfVar
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "›"
                                color: Theme.inkSurfVar
                                font.pixelSize: 13
                                visible: modelData.hasChildren
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (modelData.hasChildren) {
                                    root.submenuRequested(modelData)
                                } else {
                                    modelData.triggered()
                                    root.entryActivated()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
