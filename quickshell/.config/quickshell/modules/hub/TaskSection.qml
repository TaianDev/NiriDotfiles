import QtQuick
import "../../core"
import "../date"

// Sección Task: el tablero y editor de Notes.
Item {
    id: root

    implicitWidth: 840
    implicitHeight: 520

    NotesTab {
        anchors.fill: parent
        textMain: Theme.inkSurf
        textMuted: Theme.inkSurfVar
        bgLighter: Theme.surfaceVariant
    }
}
