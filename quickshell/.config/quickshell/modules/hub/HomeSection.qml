import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../components"
import "../network/popup"
import "../music"
import "."

// Sección Home: avatar+stats | controles de red | música (3 columnas).
Item {
    id: root

    property int netPage: 0

    implicitWidth: 940
    implicitHeight: 430

    RowLayout {
        anchors.fill: parent
        spacing: 14

        // ── Columna 1: avatar + stats ──
        UserStats {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.alpha(Theme.outline, 0.2)
        }

        // ── Columna 2: red ──
        Item {
            id: netHost
            Layout.preferredWidth: 336
            Layout.fillHeight: true
            clip: true

            // Carrusel con slide (como el NetworkPopup original).
            Item {
                id: carrusel
                width: netHost.width * 2
                height: netHost.height
                x: root.netPage === 0 ? 0 : -netHost.width
                Behavior on x {
                    NumberAnimation { duration: 350; easing.type: Easing.OutQuart }
                }

                // Slot 0: vista principal
                Item {
                    width: netHost.width
                    height: netHost.height
                    x: 0

                    NetworkMainView {
                        anchors.fill: parent
                        onRequestPage: page => root.netPage = page
                    }
                }

                // Slot 1: Wi-Fi / Bluetooth
                Item {
                    width: netHost.width
                    height: netHost.height
                    x: netHost.width

                    RowLayout {
                        id: netHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        spacing: 8

                        AppText {
                            text: "‹ Back"
                            color: Theme.primary
                            font.pixelSize: 13
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.netPage = 0
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AppText {
                            text: root.netPage === 1 ? "Wi-Fi" : "Bluetooth"
                            color: Theme.inkSurf
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        AppText {
                            text: "↻"
                            color: Theme.primary
                            font.pixelSize: 15
                            font.bold: true
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.netPage === 1) wifiView.forceRefresh()
                                    else if (root.netPage === 2) btView.forceRefresh()
                                }
                            }
                        }
                    }

                    Item {
                        anchors.top: netHeader.bottom
                        anchors.topMargin: 8
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        WifiPage {
                            id: wifiView
                            anchors.fill: parent
                            visible: root.netPage === 1
                        }

                        BluetoothPage {
                            id: btView
                            anchors.fill: parent
                            visible: root.netPage === 2
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.alpha(Theme.outline, 0.2)
        }

        // ── Columna 3: música ──
        MusicSection {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
