pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "."

PanelWindow {
    id: popups

    required property var screen
    property real barPopupTopY: 42

    anchors {
        top: true
        right: true
    }

    margins {
        top: 0
        right: 0
    }

    implicitWidth: 340 + 14
    implicitHeight: popups.current !== null ? (toastItem.implicitHeight + 6) : 0
    height: implicitHeight

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_notif_popups_" + screen.name
    WlrLayershell.layer: WlrLayer.Overlay

    // Cola de a una: se muestra `current` hasta que salga; recién ahí entra otra.
    property var current: null

    visible: popups.current !== null && !NotificationService.panelOpen

    function pickCurrent() {
        const list = NotificationService.popups
        // Mantener la actual mientras siga viva.
        if (popups.current !== null && list.indexOf(popups.current) >= 0)
            return
        // FIFO: la más antigua (pushPopupNow pone las nuevas al frente).
        popups.current = list.length > 0 ? list[list.length - 1] : null
    }

    Component.onCompleted: Qt.callLater(pickCurrent)

    Connections {
        target: NotificationService
        function onPopupVersionChanged() { Qt.callLater(popups.pickCurrent) }
    }

    NotificationPopupToast {
        id: toastItem
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width
        visible: popups.current !== null
        notification: popups.current

        onRequestClose: {
            const notif = popups.current
            if (!notif)
                return
            if (NotificationService.popups.indexOf(notif) >= 0) {
                const transient = notif.transient ?? false
                NotificationService.popPopup(notif)
                if (transient)
                    notif.dismiss()
            }
        }
    }
}
