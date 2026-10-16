import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../core"

// Un "nivel" del menú del tray. Mantiene SU PROPIO QsMenuOpener, ligado de forma
// declarativa al handle (sin reasignaciones). Se instancia una vez por nivel de
// la pila: los openers padre siguen vivos porque las entradas hijas pertenecen al
// modelo del padre, y destruir/reutilizar el opener padre invalidaría el submenú.
ColumnLayout {
    id: root

    required property var menuHandle
    property bool showBack: false

    signal backRequested()
    signal entryActivated()
    signal submenuRequested(var entry)
    signal contentReady()

    readonly property real rowHeight: 34
    readonly property real sepHeight: 7

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 0

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    readonly property var entries: menuOpener.children.values

    readonly property int contentHeight: {
        let h = showBack ? 28 : 0
        const e = entries
        for (let i = 0; i < e.length; i++) {
            const it = e[i]
            if (!it)
                continue
            h += it.isSeparator ? sepHeight : rowHeight
        }
        return h
    }

    // Ancho natural del menú (según el texto/ícono más largo).
    TextMetrics {
        id: tm
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    readonly property int contentWidth: {
        let w = 0
        const e = entries
        for (let i = 0; i < e.length; i++) {
            const it = e[i]
            if (!it || it.isSeparator)
                continue
            tm.text = it.text ?? ""
            let row = tm.advanceWidth + 16          // márgenes internos del row
            if (it.icon && it.icon !== "")
                row += 16 + 8                        // icono + spacing
            if (it.hasChildren)
                row += 8 + 12                        // spacing + flecha
            if (row > w)
                w = row
        }
        return Math.ceil(w)
    }

    Connections {
        target: menuOpener
        function onChildrenChanged() {
            root.contentReady()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: showBack ? 28 : 0
        visible: showBack
        spacing: 8

        AppText {
            text: "‹ Back"
            color: Theme.primary
            font.pixelSize: 12
            font.bold: true
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    required property var modelData
                    width: parent ? parent.width : 0
                    height: modelData.isSeparator ? root.sepHeight : root.rowHeight
                    visible: modelData.isSeparator || modelData.text !== ""

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Theme.alpha(Theme.outline, 0.35)
                        visible: modelData.isSeparator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: rowMa.containsMouse
                               ? Theme.alpha(Theme.inkSurf, 0.08)
                               : "transparent"
                        visible: !modelData.isSeparator

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Image {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                source: modelData.icon
                                sourceSize: Qt.size(16, 16)
                                fillMode: Image.PreserveAspectFit
                                visible: modelData.icon !== ""
                            }

                            AppText {
                                Layout.fillWidth: true
                                text: modelData.text
                                color: modelData.enabled ? Theme.inkSurf : Theme.inkSurfVar
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            AppText {
                                text: "›"
                                color: Theme.inkSurfVar
                                font.pixelSize: 13
                                visible: modelData.hasChildren
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (modelData.hasChildren) {
                                    root.submenuRequested(modelData)
                                } else {
                                    modelData.triggered()
                                    root.entryActivated()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
