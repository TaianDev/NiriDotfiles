pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../core"
import "../../services"
import "../../components"

Item {
    id: toast

    required property var notification

    readonly property int dismissMs: NotificationService.popupDuration(notification)
    readonly property bool autoDismiss: dismissMs > 0
    readonly property string iconSrc: NotificationService.resolveIcon(notification)
    readonly property bool isCritical: notification?.urgency === NotificationUrgency.Critical
    readonly property string bodyText: NotificationService.formatBody(notification?.body)
    readonly property bool hasBody: bodyText !== ""

    signal requestClose()

    width: 340
    implicitHeight: toastBody.implicitHeight
    height: implicitHeight
    opacity: 0
    x: width

    Component.onCompleted: enterAnim.start()

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: toast
            property: "opacity"
            from: 0
            to: 1
            duration: 280
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: toast
            property: "x"
            from: toast.width
            to: 0
            duration: 340
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation {
                target: toast
                property: "opacity"
                to: 0
                duration: 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: toast
                property: "x"
                to: toast.width
                duration: 240
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: toast.requestClose()
        }
    }

    function closeToast() {
        if (!exitAnim.running)
            exitAnim.start()
    }

    property int elapsedMs: 0

    Timer {
        id: lifeTimer
        interval: 40
        repeat: true
        running: toast.autoDismiss && !hoverMa.containsMouse && !exitAnim.running
        onTriggered: {
            toast.elapsedMs += interval
            progressFill.width = Math.max(0, progressTrack.width * (1 - toast.elapsedMs / toast.dismissMs))
            if (toast.elapsedMs >= toast.dismissMs)
                NotificationService.hidePopup(toast.notification)
        }
    }

    Rectangle {
        id: toastBody
        width: parent.width
        implicitHeight: contentColumn.implicitHeight + 24
        radius: 18
        color: Theme.surface
        border.width: 1
        border.color: isCritical ? Theme.err : Theme.outlineVariant

        Column {
            id: contentColumn
            width: parent.width - 24
            x: 12
            y: 12
            spacing: 0

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 8
                    color: Theme.primaryContainer

                    Image {
                        id: appIconImg
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: toast.iconSrc
                        sourceSize: Qt.size(18, 18)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        visible: toast.iconSrc !== "" && status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (notification?.appName ?? "?").charAt(0).toUpperCase()
                        color: Theme.inkPrimCont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        visible: toast.iconSrc === "" || appIconImg.status === Image.Error
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: notification?.appName ?? "App"
                        color: Theme.inkSurfVar
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        elide: Text.ElideRight
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
                    color: closeMa.containsMouse ? Theme.outlineVariant : "transparent"

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
                        onClicked: toast.closeToast()
                    }
                }
                }

                Text {
                    Layout.fillWidth: true
                    text: toast.bodyText
                    color: Theme.inkSurfVar
                    font.pixelSize: 12
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    visible: toast.hasBody
                }
            }

            Item {
                width: parent.width
                height: toast.autoDismiss ? 12 : 0
            }

            Rectangle {
                id: progressTrack
                width: parent.width
                height: toast.autoDismiss ? 2 : 0
                radius: 1
                visible: toast.autoDismiss
                color: Theme.outlineVariant
                clip: true

                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: 1
                    color: isCritical ? Theme.err : Theme.primary
                }
            }
        }
    }

    MouseArea {
        id: hoverMa
        z: -1
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.openPanel()
    }

    Connections {
        target: NotificationService
        function onPopupHideRequested(n) {
            if (n?.id === toast.notification?.id)
                toast.closeToast()
        }
    }
}
