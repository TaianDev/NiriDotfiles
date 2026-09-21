pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../core"
import "../../services"
import "../../components"

Item {
    id: card

    required property var notification
    property bool isCurrent: false

    readonly property string iconSrc: NotificationService.resolveIcon(notification)
    readonly property bool isCritical: notification?.urgency === NotificationUrgency.Critical
    readonly property string timeLabel: NotificationService.formatTimeAgo(
        NotificationService.receivedAt(notification))
    readonly property string bodyText: NotificationService.formatBody(notification?.body)
    readonly property bool hasBody: bodyText !== ""
    readonly property bool hasImage: NotificationService.resolveImage(notification) !== ""
    readonly property bool hasActions: (notification?.actions?.length ?? 0) > 0

    width: ListView.view ? ListView.view.width : 340
    implicitHeight: surface.implicitHeight
    height: implicitHeight

    property bool _dismissing: false

    ParallelAnimation {
        id: slideOutAnimation
        NumberAnimation {
            property: "x"
            to: card.ListView.view ? card.ListView.view.width : card.width
            duration: 250
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            property: "opacity"
            to: 0.0
            duration: 250
            easing.type: Easing.InCubic
        }
        onFinished: {
            card._dismissing = true
            NotificationService.dismiss(card.notification)
        }
    }

    function dismissWithAnimation() {
        if (!_dismissing)
            slideOutAnimation.start()
    }

    Rectangle {
        id: surface
        width: parent.width
        implicitHeight: content.implicitHeight + 20
        radius: 14
        color: isCurrent ? Theme.alpha(Theme.primary, 0.12) : (isCritical ? Theme.errContainer : Theme.surfaceVariant)
        border.width: isCurrent ? 2 : 1
        border.color: isCurrent ? Theme.primary : (isCritical ? Theme.err : Theme.outlineVariant)

        ColumnLayout {
            id: content
            width: parent.width - 20
            x: 10
            y: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Theme.primaryContainer

                    Image {
                        id: appIconImg
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: card.iconSrc
                        sourceSize: Qt.size(18, 18)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        visible: card.iconSrc !== "" && status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (notification?.appName ?? "?").charAt(0).toUpperCase()
                        color: Theme.inkPrimCont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        visible: card.iconSrc === "" || appIconImg.status === Image.Error
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: notification?.appName ?? "App"
                            color: Theme.inkSurfVar
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: card.timeLabel
                            color: Theme.inkSurfVar
                            font.pixelSize: 10
                            opacity: 0.7
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: notification?.summary ?? ""
                        color: Theme.inkSurf
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: {
                        if (closeMa.containsMouse)
                            return Theme.alpha(Theme.inkSurf, 0.12)
                        return "transparent"
                    }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.inkSurfVar
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.dismissWithAnimation()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: hasBody ? 0 : -2
                text: card.bodyText
                color: Theme.inkSurfVar
                font.pixelSize: 12
                lineHeight: 1.3
                wrapMode: Text.WordWrap
                visible: card.hasBody
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: card.hasImage ? 88 : 0
                Layout.maximumHeight: card.hasImage ? 88 : 0
                radius: 10
                clip: true
                color: Theme.surfaceVariant
                visible: card.hasImage

                Image {
                    anchors.fill: parent
                    source: card.hasImage ? NotificationService.resolveImage(notification) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: card.hasActions ? 2 : 0
                spacing: 6
                visible: card.hasActions

                Repeater {
                    model: card.hasActions ? notification.actions : []

                    Rectangle {
                        required property var modelData
                        height: 28
                        width: actionLabel.implicitWidth + 20
                        radius: 14
                        color: actionMa.containsMouse ? Theme.primaryContainer : Theme.secondaryContainer

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData?.text ?? ""
                            color: Theme.primary
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: actionMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.invokeAction(card.notification, modelData)
                        }
                    }
                }
            }
        }
    }
}
