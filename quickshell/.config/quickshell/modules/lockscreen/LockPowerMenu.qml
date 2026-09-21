import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../services"

Item {
    id: root

    property string homeDir: ""
    readonly property string iconPathBase: homeDir !== ""
        ? "file://" + homeDir + "/.config/quickshell/assets/icons/"
        : ""

    property var actionList: [
        { label: "Log Out",   icon: "logout.svg", action: "logout" },
        { label: "Shut Down", icon: "power.svg",  action: "poweroff" },
        { label: "Sleep",     icon: "sleep.svg",  action: "sleep" }
    ]

    property int currentIndex: 1
    property bool menuOpen: false
    property bool dialogOpen: false

    readonly property var currentAction: actionList[currentIndex]

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }

    // ── PILL ─────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 40
        height: 44
        radius: 12
        width: pillRow.width + 24
        color: alpha(Theme.surface, 0.8)
        border.width: 1
        border.color: alpha(Theme.outline, 0.3)

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 10

            Item {
                id: pillAction
                height: 44
                width: actionIcon.width + 8 + actionLabel.implicitWidth

                Image {
                    id: actionIcon
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    source: root.iconPathBase + root.currentAction.icon
                    width: 16; height: 16
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: Theme.onBackground }
                }

                Text {
                    id: actionLabel
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: actionIcon.right
                    anchors.leftMargin: 8
                    text: root.currentAction.label
                    color: Theme.onBackground
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dialogOpen = true
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 18
                color: alpha(Theme.outline, 0.25)
            }

            Item {
                id: pillArrow
                height: 44
                width: 20

                Image {
                    anchors.centerIn: parent
                    source: root.iconPathBase + "up.svg"
                    width: 10; height: 10
                    sourceSize.width: 10
                    sourceSize.height: 10
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    rotation: root.menuOpen ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: alpha(Theme.onBackground, 0.7) }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuOpen = !root.menuOpen
                }
            }
        }
    }

    // ── MENU ─────────────────────────────────────────────────
    Item {
        id: menuContainer
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.bottom: pill.top
        anchors.bottomMargin: 8
        width: 150
        clip: true
        height: root.menuOpen ? menuHeight : 0

        readonly property real menuHeight: 132

        Behavior on height {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: menuShadow
            anchors.fill: menuBox
            anchors.leftMargin: 4
            anchors.topMargin: 4
            anchors.rightMargin: -4
            anchors.bottomMargin: -6
            radius: menuBox.radius + 4
            color: alpha("#000000", 0.25)
            visible: root.menuOpen
            z: -1

            layer.enabled: root.menuOpen
            layer.effect: FastBlur {
                radius: 8
                cached: true
            }
        }

        Rectangle {
            id: menuBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: menuContainer.menuHeight
            radius: 16
            enabled: root.menuOpen
            color: Theme.surface
            border.width: 1
            border.color: alpha(Theme.outline, 0.3)

            ColumnLayout {
                id: menuColumn
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top; topMargin: 8
                    bottom: parent.bottom; bottomMargin: 8
                }
                spacing: 4

                Repeater {
                    model: root.actionList

                    Rectangle {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 10
                        color: ma.containsMouse
                            ? alpha(Theme.onBackground, 0.1)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 12; rightMargin: 12
                            }
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                source: root.iconPathBase + modelData.icon
                                sourceSize.width: 16
                                sourceSize.height: 16
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: index === root.currentIndex
                                        ? Theme.primary : Theme.onBackground
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.label
                                color: index === root.currentIndex
                                    ? Theme.primary : Theme.onBackground
                                font.pixelSize: 13
                                font.weight: index === root.currentIndex
                                    ? Font.DemiBold : Font.Medium
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = index
                                root.menuOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ── DIALOG OVERLAY ───────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: root.dialogOpen
        z: 9999

        Rectangle {
            anchors.fill: parent
            color: alpha("#000000", 0.5)
            MouseArea { anchors.fill: parent; onClicked: root.dialogOpen = false }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: dialogColumn.height + 32
            radius: 24
            color: Theme.surface
            border.width: 1
            border.color: alpha(Theme.outline, 0.3)

            layer.enabled: true
            layer.effect: DropShadow {
                radius: 32; samples: 33
                color: alpha("#000000", 0.4)
                verticalOffset: 4
            }

            ColumnLayout {
                id: dialogColumn
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 16

                Item { width: 1; height: 4 }

                Text {
                    Layout.fillWidth: true
                    text: "Are you sure?"
                    color: Theme.onBackground
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "Do you want to " + root.currentAction.label.toLowerCase() + "?"
                    color: Theme.onBackgroundMuted
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 8
                        color: cancelMa.containsMouse
                            ? alpha(Theme.onBackground, 0.08)
                            : "transparent"
                        border.width: 1
                        border.color: alpha(Theme.outline, 0.3)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.onBackground
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dialogOpen = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 12
                        color: acceptMa.containsMouse
                            ? alpha(Theme.error, 0.25)
                            : alpha(Theme.error, 0.15)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Accept"
                            color: Theme.error
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: acceptMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.dialogOpen = false
                                root.menuOpen = false
                                switch (root.currentAction.action) {
                                case "logout":   SessionService.logout(); break
                                case "poweroff": SessionService.poweroff(); break
                                case "sleep":    SessionService.sleep(); break
                                }
                            }
                        }
                    }
                }
                Item { width: 1; height: 4 }
            }
        }
    }
}
