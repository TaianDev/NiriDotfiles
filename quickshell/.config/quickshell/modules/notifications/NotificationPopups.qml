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
        top: popups.barPopupTopY
        right: 14
    }

    implicitWidth: 340
    height: toastColumn.height + 6

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_notif_popups_" + screen.name
    WlrLayershell.layer: WlrLayer.Overlay

    visible: popupsModel.count > 0 && !NotificationService.panelOpen

    ListModel { id: popupsModel }

    function syncActivePopups() {
        const list = NotificationService.popups

        var i = popupsModel.count - 1
        while (i >= 0) {
            if (list.indexOf(popupsModel.get(i).notification) < 0)
                popupsModel.remove(i, 1)
            i--
        }

        var targetIdx = 0
        while (targetIdx < list.length) {
            if (targetIdx >= popupsModel.count) {
                popupsModel.append({ notification: list[targetIdx] })
            } else if (popupsModel.get(targetIdx).notification !== list[targetIdx]) {
                var src = -1
                for (var j = targetIdx + 1; j < popupsModel.count; j++) {
                    if (popupsModel.get(j).notification === list[targetIdx]) {
                        src = j
                        break
                    }
                }
                if (src >= 0)
                    popupsModel.remove(targetIdx, src - targetIdx)
                else
                    popupsModel.insert(targetIdx, { notification: list[targetIdx] })
            }
            targetIdx++
        }

        while (popupsModel.count > list.length)
            popupsModel.remove(popupsModel.count - 1, 1)
    }

    Component.onCompleted: Qt.callLater(syncActivePopups)

    Connections {
        target: NotificationService
        function onPopupVersionChanged() {
            Qt.callLater(syncActivePopups)
        }
    }

    Column {
        id: toastColumn
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 10
        width: parent.width

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: popupsModel

            NotificationPopupToast {
                required property var modelData
                required property int index
                width: toastColumn.width
                notification: modelData ?? null
                visible: modelData !== null

                onRequestClose: {
                    if (!modelData)
                        return
                    const notif = modelData
                    if (NotificationService.popups.indexOf(notif) >= 0) {
                        const transient = notif.transient ?? false
                        NotificationService.popPopup(notif)
                        if (transient)
                            notif.dismiss()
                    }
                }
            }
        }
    }
}
