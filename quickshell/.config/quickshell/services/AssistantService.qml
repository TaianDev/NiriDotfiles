pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property bool panelOpen: false

    signal showTranslatorRequested(string text)

    IpcHandler {
        target: "assistant_panel"
        function toggle(): void { root.togglePanel() }
    }

    IpcHandler {
        target: "assistant_translate"
        function translate(text: string): void { root.openTranslator(text) }
    }

    function openTranslator(text) {
        TranslationService.sourceLang = "auto"
        TranslationService.input = text ?? ""
        root.openPanel()
        root.showTranslatorRequested(text ?? "")
        if (text !== "") Qt.callLater(TranslationService.translate)
    }

    function togglePanel() {
        root.panelOpen ? root.closePanel() : root.openPanel()
    }

    function openPanel() {
        PopupManager.openExclusive(PopupManager.assistantId)
        Qt.callLater(() => { root.panelOpen = true })
    }

    function closePanel() { root.panelOpen = false }

    onPanelOpenChanged: {
        if (!root.panelOpen) PopupManager.notifyClosed(PopupManager.assistantId)
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.assistantId) root.panelOpen = false
        }
    }
}
