import QtQuick
import Quickshell
import "../../../core"
import "../../../services"
import "../../../components/shell"

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 440

    property var hostWindow
    property var anchorItem
    property int currentPage: 0
    property bool isOpened: false

    visible: isOpened || shell.exitRunning

    grabFocus: isOpened

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.networkId)
                popup.isOpened = false
        }
    }

    function reposition() {
        if (!hostWindow || !anchorItem)
            return

        const pos = anchorItem.mapToItem(hostWindow.contentItem, 0, anchorItem.height)
        const ax = pos.x + anchorItem.width / 2 - implicitWidth / 2
        anchor.window = hostWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, implicitWidth, implicitHeight)
        anchor.updateAnchor()
    }

    function toggle() {
        if (popup.isOpened) {
            popup.isOpened = false
        } else {
            PopupManager.openExclusive(PopupManager.networkId)
            Qt.callLater(() => popup.isOpened = true)
        }
    }

    onIsOpenedChanged: {
        if (!isOpened)
            PopupManager.notifyClosed(PopupManager.networkId)

        if (isOpened) {
            currentPage = 0
            reposition()
            shell.active = true
            mainView.refresh()
            Qt.callLater(() => popup.contentItem.forceActiveFocus())
        } else {
            shell.active = false
        }
    }

    onVisibleChanged: {
        if (visible) {
            reposition()
        } else if (popup.isOpened && !shell.exitRunning) {
            popup.isOpened = false
        }
    }

    PopupEscCapture {
        active: popup.isOpened
        popupId: PopupManager.networkId

        PopupEnterExit {
            id: shell
            anchors.fill: parent
            active: popup.isOpened
            cornerRadius: 16
            onExitFinished: popup.currentPage = 0

            Item {
            id: header
            width: parent.width
            height: 40
            z: 10
            opacity: popup.currentPage !== 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Text {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "‹ Back"
                color: Theme.primary
                font.pixelSize: 14
                font.bold: true
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.currentPage = 0
                }
            }
            Text {
                anchors.centerIn: parent
                text: popup.currentPage === 1 ? "Wi-Fi Networks" : "Bluetooth Devices"
                color: Theme.inkSurf
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                x: parent.width - width - 16
                anchors.verticalCenter: parent.verticalCenter
                text: "↻ Updt"
                color: Theme.primary
                font.pixelSize: 14
                font.bold: true
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (popup.currentPage === 1)
                            wifiView.forceRefresh()
                        else if (popup.currentPage === 2)
                            btView.forceRefresh()
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.outline, 0.35)
            }
        }

        Item {
            id: carrusel
            width: popup.implicitWidth * 2
            height: parent.height
            x: popup.currentPage === 0 ? 0 : -popup.implicitWidth
            Behavior on x {
                NumberAnimation { duration: 350; easing.type: Easing.OutQuart }
            }

            Item {
                width: popup.implicitWidth
                height: parent.height
                x: 0

                NetworkMainView {
                    id: mainView
                    anchors.fill: parent
                    anchors.margins: 14
                    onRequestPage: page => popup.currentPage = page
                }
            }

            Item {
                width: popup.implicitWidth
                height: parent.height
                x: popup.implicitWidth

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 44
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 14

                    WifiPage {
                        id: wifiView
                        anchors.fill: parent
                        visible: popup.currentPage === 1
                    }

                    BluetoothPage {
                        id: btView
                        anchors.fill: parent
                        visible: popup.currentPage === 2
                    }
                }
            }
        }
    }
    }
}
