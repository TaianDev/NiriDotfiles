pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"

// Tray como panel cóncavo (MorphMenu) que crece desde el widget de la barra.
// Página 0 = iconos; al pulsar uno con menú se "cambia de página" a sus opciones.
// Cada nivel de menú es un TrayMenuList propio (con su opener), apilado; sólo el
// nivel superior es visible. Así los submenús siguen siendo válidos y cada
// apertura usa openers frescos.
MorphMenu {
    id: tray

    property var hostWindow: null
    property var widgetRef: null

    open: tray.widgetRef?.isOpened ?? false
    screen: tray.hostWindow ? tray.hostWindow.screen : null
    anchorBottom: 0
    concaveTop: 14
    cornerBottom: 20

    readonly property var trayModel: SystemTray.items
    readonly property int trayCount: trayModel.values.length

    readonly property int iconCell: 28
    readonly property int iconGap: 6
    readonly property int iconsBoxWidth: Math.max(100, Math.min(320, trayCount * (iconCell + iconGap) + 20))
    readonly property int iconsBoxHeight: 40

    readonly property int maxMenuHeight: 380
    readonly property int minMenuWidth: 170
    readonly property int maxMenuWidth: 340

    // Rect del widget en la barra. `mapToItem` no es reactivo por sí solo, así
    // que un TransformWatcher observa la geometría entre el contentItem del bar
    // y el widget; referenciar `transform` reevalúa el binding cuando el layout
    // se asienta o cualquier ancestro se mueve, de modo que el menú nace justo
    // bajo el icono del tray.
    TransformWatcher {
        id: anchorWatch
        a: tray.hostWindow ? tray.hostWindow.contentItem : null
        b: tray.widgetRef
        commonParent: tray.hostWindow ? tray.hostWindow.contentItem : null
    }
    collapsedRect: {
        anchorWatch.transform
        const w = tray.widgetRef
        const hw = tray.hostWindow
        if (!w || !hw || !hw.contentItem)
            return Qt.rect(0, 0, 0, 0)
        const p = w.mapToItem(hw.contentItem, 0, 0)
        return Qt.rect(Math.round(p.x), 0, w.width, w.height)
    }

    // Pila de handles de menú (nivel 0 = menú raíz de un icono). Vacía = iconos.
    property var pageStack: []

    readonly property bool onIconsPage: pageStack.length === 0

    // Tamaño del nivel superior (lo reporta su TrayMenuList vía contentReady).
    property int menuWidth: tray.minMenuWidth
    property int menuHeight: 44

    expandedWidth: tray.onIconsPage
        ? tray.iconsBoxWidth
        : Math.max(tray.minMenuWidth, Math.min(tray.maxMenuWidth, tray.menuWidth + 20))
    expandedHeight: tray.onIconsPage
        ? tray.iconsBoxHeight
        : Math.min(tray.maxMenuHeight, tray.menuHeight + 16)

    onRequestClose: if (tray.widgetRef) tray.widgetRef.isOpened = false

    function refreshTopSize() {
        const n = tray.pageStack.length
        if (n === 0)
            return
        const it = menuRepeater.itemAt(n - 1)
        if (it) {
            tray.menuWidth = it.contentWidth
            tray.menuHeight = it.contentHeight
        }
    }

    function pushMenu(handle) {
        if (!handle)
            return
        var s = tray.pageStack.slice()
        s.push(handle)
        tray.pageStack = s
        Qt.callLater(tray.refreshTopSize)
    }

    // El menú de un icono se abre con su handle (`item.menu`), no con el item.
    function openItemMenu(item) {
        tray.pushMenu((item && item.menu) ? item.menu : item)
    }

    function goBack() {
        if (tray.pageStack.length === 0)
            return
        var s = tray.pageStack.slice()
        s.pop()
        tray.pageStack = s
        Qt.callLater(tray.refreshTopSize)
    }

    Connections {
        target: tray
        function onOpenChanged() {
            if (tray.open) {
                tray.pageStack = []
                tray.menuWidth = tray.minMenuWidth
                tray.menuHeight = 44
            }
        }
    }

    PopupEscCapture {
        active: tray.open
        popupId: PopupManager.trayId

        Item {
            anchors.fill: parent

            // ── Página de iconos ──
            Row {
                anchors.centerIn: parent
                visible: tray.onIconsPage
                height: tray.iconCell
                spacing: tray.iconGap

                Repeater {
                    model: tray.trayModel

                    Rectangle {
                        id: iconBtn
                        required property var modelData
                        required property int index

                        width: tray.iconCell
                        height: tray.iconCell
                        radius: 8
                        color: iconMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                        border.width: iconMa.containsMouse ? 1 : 0
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: iconBtn.modelData.icon
                            sourceSize: Qt.size(16, 16)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                        }

                        MouseArea {
                            id: iconMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (iconBtn.modelData.hasMenu) {
                                    tray.openItemMenu(iconBtn.modelData)
                                } else {
                                    iconBtn.modelData.activate()
                                    if (tray.widgetRef)
                                        tray.widgetRef.isOpened = false
                                }
                            }
                        }
                    }
                }
            }

            AppText {
                anchors.centerIn: parent
                visible: tray.onIconsPage && tray.trayCount === 0
                text: "No tray icons"
                color: Theme.inkSurfVar
                font.pixelSize: 11
            }

            // ── Pila de niveles de menú (sólo el superior visible) ──
            Repeater {
                id: menuRepeater
                model: tray.pageStack.length

                TrayMenuList {
                    required property int index

                    anchors.fill: parent
                    anchors.margins: 8
                    visible: index === tray.pageStack.length - 1
                    menuHandle: tray.pageStack[index] ?? null
                    showBack: true
                    onBackRequested: tray.goBack()
                    onSubmenuRequested: entry => tray.pushMenu(entry)
                    onEntryActivated: if (tray.widgetRef) tray.widgetRef.isOpened = false
                    onContentReady: {
                        if (index === tray.pageStack.length - 1)
                            tray.refreshTopSize()
                    }
                }
            }
        }
    }
}
