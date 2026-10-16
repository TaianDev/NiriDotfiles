pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

    // Color de la barra (mismo que el fondo inferior de la barra / hub).
    readonly property color surfaceColor: Theme.panelShade

    signal requestClose()

    // ── Geometría ──
    readonly property real tc: 14          // fillet cóncavo (arriba-izquierda)
    readonly property real br: 16          // radio redondeado
    readonly property real bodyW: 340
    width: bodyW + tc
    implicitHeight: contentColumn.implicitHeight + 24
    height: implicitHeight
    opacity: 0

    // Morph: nace como pill arriba (pegado a la barra) y crece; pegado a la derecha.
    property real boxW: 60
    property real boxH: 28
    readonly property real boxX: width - boxW
    readonly property real expandedW: bodyW
    readonly property real expandedH: toast.implicitHeight

    Component.onCompleted: enterAnim.start()

    // Nueva notificación en el mismo toast (cola de a una): reinicia la animación.
    onNotificationChanged: {
        if (toast.notification === null || toast.notification === undefined)
            return
        toast.elapsedMs = 0
        toast.opacity = 0
        toast.boxW = 60
        toast.boxH = 28
        contentWrap.opacity = 0
        exitAnim.stop()
        enterAnim.restart()
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: toast; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: toast; property: "boxW"; from: 60; to: toast.expandedW; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: toast; property: "boxH"; from: 28; to: toast.expandedH; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: contentWrap; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation { target: toast; property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: toast; property: "boxW"; to: 60; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: toast; property: "boxH"; to: 28; duration: 200; easing.type: Easing.InCubic }
        }
        ScriptAction { script: toast.requestClose() }
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

    // ── Caja con forma (cóncavo arriba-izquierda; resto redondeado) ──
    Item {
        id: box
        x: toast.boxX
        y: 0
        width: toast.boxW
        height: toast.boxH

        // El Shape se extiende `tc` a la izquierda para el fillet cóncavo.
        Shape {
            id: toastShape
            x: -toast.tc
            y: 0
            width: box.width + toast.tc
            height: box.height
            antialiasing: true
            layer.enabled: true
            layer.samples: 8

            readonly property real shW: width
            readonly property real shH: height
            readonly property real tc: Math.max(0, Math.min(toast.tc, width / 2))
            readonly property real br: Math.max(0, Math.min(toast.br, height / 2))

            ShapePath {
                fillColor: toast.surfaceColor
                strokeWidth: toast.isCritical ? 1 : 0
                strokeColor: Theme.err

                startX: toastShape.tc; startY: toastShape.tc
                PathQuad { x: 0; y: 0; controlX: toastShape.tc; controlY: 0 }
                PathLine { x: toastShape.shW - toastShape.br; y: 0 }
                PathQuad { x: toastShape.shW; y: toastShape.br; controlX: toastShape.shW; controlY: 0 }
                PathLine { x: toastShape.shW; y: toastShape.shH - toastShape.br }
                PathQuad { x: toastShape.shW - toastShape.br; y: toastShape.shH; controlX: toastShape.shW; controlY: toastShape.shH }
                PathLine { x: toastShape.tc + toastShape.br; y: toastShape.shH }
                PathQuad { x: toastShape.tc; y: toastShape.shH - toastShape.br; controlX: toastShape.tc; controlY: toastShape.shH }
                PathLine { x: toastShape.tc; y: toastShape.tc }
            }
        }

        // Contenido revelado junto con la caja.
        Item {
            id: contentClip
            x: 0
            y: 0
            width: box.width
            height: box.height
            clip: true

            Item {
                id: contentWrap
                x: toast.tc - box.x
                y: 0
                width: toast.bodyW
                height: toast.implicitHeight
                opacity: 0

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

                                AppText {
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

                                AppText {
                                    Layout.fillWidth: true
                                    text: notification?.appName ?? "App"
                                    color: Theme.inkSurfVar
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                AppText {
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

                                AppText {
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

                        AppText {
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
