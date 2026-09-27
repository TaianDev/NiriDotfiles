pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"
import "."

PanelWindow {
    id: panel

    required property var screen

    readonly property bool open: NotificationService.panelOpen
    readonly property int panelWidth: 360
    readonly property int edgeMargin: 14
    property real barPopupTopY: 42
    readonly property int panelVerticalMargin: Math.round((barPopupTopY + edgeMargin) / 2)

    property int currentIndex: -1

    ListModel { id: notifModel }

    function rebuildSortedList() {
        const list = NotificationService.notifications.values.slice()
        list.sort((a, b) => NotificationService.receivedAt(b) - NotificationService.receivedAt(a))

        // Pass 1: remove items no longer in the new list (backwards for stable indices)
        var i = notifModel.count - 1
        while (i >= 0) {
            var existing = notifModel.get(i).notification
            if (list.indexOf(existing) < 0)
                notifModel.remove(i, 1)
            i--
        }

        // Pass 2: insert new items at their correct sorted position
        for (var j = 0; j < list.length; j++) {
            var newNotif = list[j]
            var found = false
            for (var k = 0; k < notifModel.count; k++) {
                if (notifModel.get(k).notification === newNotif) {
                    found = true
                    break
                }
            }
            if (!found) {
                var insertPos = 0
                while (insertPos < notifModel.count) {
                    var existing = notifModel.get(insertPos).notification
                    if (NotificationService.receivedAt(newNotif) > NotificationService.receivedAt(existing))
                        break
                    insertPos++
                }
                notifModel.insert(insertPos, { notification: newNotif })
            }
        }
    }

    Component.onCompleted: Qt.callLater(rebuildSortedList)

    Connections {
        target: NotificationService
        function onListChanged() {
            Qt.callLater(rebuildSortedList)
        }
    }

    onVisibleChanged: {
        if (visible) {
            currentIndex = -1
            Qt.callLater(() => focusHost.forceActiveFocus())
        }
    }

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: panel.panelVerticalMargin
        bottom: panel.panelVerticalMargin
        right: panel.edgeMargin
    }

    implicitWidth: panel.panelWidth

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_notifications_" + screen.name
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: open || shell.exitRunning

    onOpenChanged: shell.active = open

    PopupEscCapture {
        active: panel.open
        popupId: PopupManager.notificationsId

        PopupEnterExit {
            id: shell
            anchors.fill: parent
            active: panel.open
            fromRight: true
            panelColor: "transparent"
            borderAlpha: 0

        Item {
            id: focusHost
            anchors.fill: parent
            focus: panel.open

            Keys.onUpPressed: {
                if (notifModel.count === 0) return
                if (panel.currentIndex < 0)
                    panel.currentIndex = 0
                else
                    panel.currentIndex = Math.max(0, panel.currentIndex - 1)
                notifList.positionViewAtIndex(panel.currentIndex, ListView.Contain)
            }
            Keys.onDownPressed: {
                if (notifModel.count === 0) return
                if (panel.currentIndex < 0)
                    panel.currentIndex = 0
                else
                    panel.currentIndex = Math.min(notifModel.count - 1, panel.currentIndex + 1)
                notifList.positionViewAtIndex(panel.currentIndex, ListView.Contain)
            }
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Backspace) {
                    if (event.modifiers & Qt.AltModifier) {
                        NotificationService.dismissAll()
                    } else if (panel.currentIndex >= 0 && panel.currentIndex < notifModel.count) {
                        const item = notifList.itemAtIndex(panel.currentIndex)
                        if (item)
                            item.dismissWithAnimation()
                    }
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Theme.surface
                border.width: 1
                border.color: Theme.outlineVariant

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 12
                            spacing: 8

                            AppText {
                                text: "Notifications"
                                color: Theme.inkSurf
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Item {
                                visible: notifModel.count > 0
                                Layout.preferredWidth: clearLabel.implicitWidth + 8
                                Layout.preferredHeight: 28

                                AppText {
                                    id: clearLabel
                                    anchors.centerIn: parent
                                    text: "Clear All"
                                    color: clearMa.containsMouse ? Theme.primary : Theme.inkSurfVar
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    opacity: clearMa.containsMouse ? 1 : 0.85
                                }

                                MouseArea {
                                    id: clearMa
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.dismissAll()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: closePanelMa.containsMouse
                                       ? Theme.outlineVariant
                                       : "transparent"

                                AppText {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.inkSurfVar
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: closePanelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.closePanel()
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }

                    Item {
                        width: parent.width
                        height: parent.height - 49

                        ListView {
                            id: notifList
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 8
                            clip: true
                            model: notifModel
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            add: Transition {
                                PropertyAction { property: "x"; value: notifList.width }
                                NumberAnimation {
                                    property: "x"
                                    to: 0
                                    duration: 240
                                    easing.type: Easing.OutCubic
                                }
                            }

                            removeDisplaced: Transition {
                                NumberAnimation {
                                    properties: "y"
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }

                            delegate: NotificationCard {
                                required property var modelData
                                required property int index
                                width: notifList.width
                                notification: modelData
                                isCurrent: index === panel.currentIndex
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            width: parent.width - 48
                            visible: notifModel.count === 0
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            SvgIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: AppPaths.iconsDir + "notifications.svg"
                                size: 32
                                tint: Theme.inkSurfVar
                                opacity: 0.28
                            }

                            AppText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No Notifications"
                                color: Theme.inkSurfVar
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                            }

                            AppText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                text: "New alerts will show up here"
                                color: Theme.inkSurfVar
                                font.pixelSize: 11
                                opacity: 0.65
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
    }
    }
}
