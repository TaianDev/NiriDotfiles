import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../core"

// MorphMenu — menú que "nace" desde su píldora y hace morph hasta su tamaño final.
// La caja es un Shape con las esquinas superiores CÓNCAVAS (fillets invertidos que
// abrazan el borde inferior de la barra) y las inferiores convexas, de modo que el
// menú parece emerger de la barra. El contenido va contra-posicionado para no
// deformarse mientras la caja crece.
PanelWindow {
    id: menu

    required property bool open
    property rect collapsedRect: Qt.rect(0, 0, 0, 0)
    // En niri, la superficie Overlay arranca en el borde inferior de la barra, así
    // que anchorBottom=0 (coordenadas del overlay) = pegado a la barra.
    property real anchorBottom: 0
    property real expandedWidth: 360
    property real expandedHeight: 440
    property real slideIn: 8

    // Radios finales: cóncavo arriba, convexo abajo.
    property real concaveTop: 14
    property real cornerBottom: 18

    // Color del panel: mismo que el borde inferior de la barra (en dark es
    // background*0.6; en light queda plano, sin gris).
    property color panelColor: Theme.panelShade

    default property alias content: contentInner.data

    signal requestClose()

    // Rect final del menú: centrado sobre la píldora y pegado al borde de la barra.
    readonly property rect expandedRect: Qt.rect(
        collapsedRect.x + collapsedRect.width / 2 - expandedWidth / 2,
        anchorBottom,
        expandedWidth,
        expandedHeight)

    // ── Geometría animada de la caja ──
    property bool _opening: false
    property bool _closing: false
    property real boxX: collapsedRect.x
    property real boxY: anchorBottom
    property real boxW: collapsedRect.width
    property real boxH: collapsedRect.height
    // Radios efectivos: se recortan al tamaño actual de la caja para que la forma
    // siga redondeada/cóncava hasta el final del cierre (sin fotogramas rectos).
    readonly property real effTopC: Math.max(0, Math.min(menu.concaveTop, boxW / 2))
    readonly property real effBotR: Math.max(0, Math.min(menu.cornerBottom, boxH / 2))

    Behavior on boxX { enabled: !menu._opening && !menu._closing; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on boxY { enabled: !menu._opening && !menu._closing; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on boxW { enabled: !menu._opening && !menu._closing; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on boxH { enabled: !menu._opening && !menu._closing; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Apertura: OutBack con overshoot sutil, 320 ms.
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: menu; property: "boxX"; to: menu.expandedRect.x; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.18 }
        NumberAnimation { target: menu; property: "boxY"; to: menu.expandedRect.y; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.18 }
        NumberAnimation { target: menu; property: "boxW"; to: menu.expandedRect.width; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.18 }
        NumberAnimation { target: menu; property: "boxH"; to: menu.expandedRect.height; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.18 }
        onFinished: menu._opening = false
    }

    // Cierre: ~200 ms.
    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: menu; property: "boxX"; to: menu.collapsedRect.x; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: menu; property: "boxY"; to: menu.anchorBottom; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: menu; property: "boxW"; to: menu.collapsedRect.width; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: menu; property: "boxH"; to: menu.collapsedRect.height; duration: 200; easing.type: Easing.OutCubic }
        onFinished: menu._closing = false
    }

    // Resize suave cuando cambia el tamaño expandido estando abierto (pestañas).
    onExpandedRectChanged: {
        if (!menu.expandedRect || !menu.open || menu._opening || menu._closing)
            return
        menu.boxX = menu.expandedRect.x
        menu.boxY = menu.expandedRect.y
        menu.boxW = menu.expandedRect.width
        menu.boxH = menu.expandedRect.height
    }

    // ── Superficie fullscreen (Overlay) ──
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_morph_" + (screen ? screen.name : "none")
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: menu.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: menu.open || menu._closing

    // Clic fuera del menú → cerrar.
    MouseArea {
        anchors.fill: parent
        onClicked: menu.requestClose()
    }

    // ── Caja con forma cóncava ──
    Item {
        id: box
        x: menu.boxX
        y: menu.boxY
        width: menu.boxW
        height: menu.boxH
        clip: false

        // El Shape se extiende a los lados para alojar los fillets cóncavos.
        Shape {
            id: shape
            x: -menu.effTopC
            y: 0
            width: box.width + menu.effTopC * 2
            height: box.height
            antialiasing: true
            layer.enabled: true
            layer.samples: 8

            readonly property real w: shape.width
            readonly property real h: shape.height
            readonly property real tc: menu.effTopC
            readonly property real br: menu.effBotR

            ShapePath {
                fillColor: menu.panelColor
                strokeWidth: 0

                // Borde superior pegado a la barra, con fillets cóncavos en las
                // esquinas de arriba (simétricos) y radio convexo en las de abajo.
                startX: 0; startY: 0
                PathLine { x: shape.w; y: 0 }
                PathQuad { x: shape.w - shape.tc; y: shape.tc; controlX: shape.w - shape.tc; controlY: 0 }
                PathLine { x: shape.w - shape.tc; y: shape.h - shape.br }
                PathQuad { x: shape.w - shape.tc - shape.br; y: shape.h; controlX: shape.w - shape.tc; controlY: shape.h }
                PathLine { x: shape.tc + shape.br; y: shape.h }
                PathQuad { x: shape.tc; y: shape.h - shape.br; controlX: shape.tc; controlY: shape.h }
                PathLine { x: shape.tc; y: shape.tc }
                PathQuad { x: 0; y: 0; controlX: shape.tc; controlY: 0 }
                PathLine { x: 0; y: 0 }
            }
        }

        // Los clics dentro de la caja no cierran el menú.
        MouseArea { anchors.fill: parent; onClicked: {} }

        // Contenido: tamaño FINAL fijo y contra-posicionado para quedar fijo en
        // pantalla. Se recorta al tamaño actual de la caja (contentClip) para que
        // se revele junto con la apertura en vez de aparecer completo antes de
        // tiempo. El fondo `Shape` queda fuera de contentClip para no cortar los
        // fillets cóncavos.
        Item {
            id: contentClip
            x: 0
            y: 0
            width: box.width
            height: box.height
            clip: true

            Item {
                id: contentWrap
                x: menu.expandedRect.x - menu.boxX
                y: menu.expandedRect.y - menu.boxY
                width: menu.expandedWidth
                height: menu.expandedHeight
                opacity: 0
                transform: Translate { id: contentShift; y: 0 }

                Item { id: contentInner; anchors.fill: parent }
            }
        }
    }

    // Entrada escalonada del contenido.
    SequentialAnimation {
        id: contentEnter
        PauseAnimation { duration: 100 }
        ParallelAnimation {
            NumberAnimation { target: contentWrap; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: contentShift; property: "y"; from: -menu.slideIn; to: 0; duration: 260; easing.type: Easing.OutCubic }
        }
    }

    NumberAnimation {
        id: contentExit
        target: contentWrap; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic
    }

    onOpenChanged: {
        if (menu.open) {
            menu._opening = true
            menu._closing = false
            menu.boxX = menu.collapsedRect.x
            menu.boxY = menu.anchorBottom
            menu.boxW = menu.collapsedRect.width
            menu.boxH = menu.collapsedRect.height
            contentWrap.opacity = 0
            contentShift.y = -menu.slideIn
            contentExit.stop()
            openAnim.restart()
            contentEnter.restart()
        } else {
            menu._opening = false
            menu._closing = true
            contentEnter.stop()
            contentExit.restart()
            closeAnim.restart()
        }
    }
}
