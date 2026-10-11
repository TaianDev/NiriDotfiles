import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"
import "."

// Menú unificado: Home / Date / Task, sobre el MorphMenu (forma cóncava + morph).
MorphMenu {
    id: hub

    property var hostWindow: null
    property var defaultAnchor: null
    property var anchorItem: null
    property bool isOpened: false

    open: hub.isOpened
    screen: hub.hostWindow ? hub.hostWindow.screen : null
    anchorBottom: 0
    concaveTop: 14
    cornerBottom: 20

    readonly property int section: HubService.section

    expandedWidth: hub.section === 0 ? 1020 : (hub.section === 1 ? 640 : 900)
    expandedHeight: hub.section === 0 ? 470 : (hub.section === 1 ? (dateSection.contentHeight + 74) : 560)
    onRequestClose: HubService.close()

    // El hub siempre nace y queda centrado en la barra principal.
    function syncAnchor() {
        if (!hub.hostWindow) {
            hub.collapsedRect = Qt.rect(0, 0, 0, 0)
            return
        }
        const barW = hub.hostWindow.width
        hub.collapsedRect = Qt.rect(barW / 2 - 60, 0, 120, 28)
    }

    // Ruteo de teclado del Timer (sub-pestaña de Date) hacia su TimerTab.
    function handleDateTabKey(event) {
        if (hub.section === 1)
            dateSection.handleKey(event)
    }

    Connections {
        target: HubService
        function onOpenRequested(section, anchorItem) {
            if (hub.hostWindow && !hub.hostWindow.isPrimary)
                return
            hub.anchorItem = anchorItem
            hub.syncAnchor()
            hub.isOpened = true
        }
        function onCloseRequested() {
            hub.isOpened = false
        }
    }

    PopupEscCapture {
        active: hub.isOpened
        popupId: HubService.id

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            HubTabs {
                Layout.fillWidth: true
                current: hub.section
                onSectionSelected: section => HubService.section = section
                onCloseRequested: HubService.close()
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                HomeSection {
                    anchors.fill: parent
                    visible: hub.section === 0
                }

                DateSection {
                    id: dateSection
                    anchors.fill: parent
                    visible: hub.section === 1
                    widgetRef: hub.dateWidgetRef
                }

                TaskSection {
                    anchors.fill: parent
                    visible: hub.section === 2
                }
            }
        }
    }

    // Referencia al DateWidget dueño del estado de timer/stopwatch.
    property var dateWidgetRef: null
}
