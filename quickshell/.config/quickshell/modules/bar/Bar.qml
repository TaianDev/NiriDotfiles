import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../components"
import "./widgets"
import "../assistant"
import "../notifications"
import "../network"
import "../network/popup"
import "../date"
import "../music"
import "../tray"
import "../focused-window"

PanelWindow {
    id: flareBar

    required property var modelData

    screen: modelData

    readonly property string primaryMonitorName: "HDMI-A-1"
    readonly property bool isPrimary: modelData.name === primaryMonitorName
    readonly property bool isFocused: {
        const active = NiriData.activeOutput
        return active !== "" ? active === modelData.name
                             : modelData.name === flareBar.primaryMonitorName
    }
    readonly property int barHeight: 40
    readonly property int flareRadius: 20
    readonly property int edgeMargin: 10
    readonly property int sectionSpacing: 10
    readonly property int barPopupGap: 8

    readonly property real barPopupTopY: {
        const ref = dateWidget
        const pos = ref.mapToItem(flareBar.contentItem, 0, ref.height)
        return pos.y + barPopupGap
    }

    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight + flareRadius + 13
    exclusiveZone: barHeight
    WlrLayershell.namespace: "flare_bar_" + modelData.name
    WlrLayershell.keyboardFocus: (dateWidget.timerKeyMode || dateWidget.textInputMode)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
    color: "transparent"
    mask: Region { item: mainBody }

    function focusTimerKeys() {
        Qt.callLater(() => timerKeyHost.forceActiveFocus())
    }

    Item {
        id: timerKeyHost
        focus: dateWidget.timerKeyMode
        Keys.onPressed: event => dateWidget.handleTimerKey(event)
    }

    // Bridge for text fields in the date popup: if the compositor gives the
    // layer surface the keyboard, forward keys to the active editor field.
    Item {
        id: textInputHost
        focus: dateWidget.textInputMode
        Keys.forwardTo: dateWidget.textInputTargets
    }

    property color _barDarkColor: Qt.rgba(
        Theme.background.r * 0.6,
        Theme.background.g * 0.6,
        Theme.background.b * 0.6,
        1
    )

    Item {
        id: barShadowHost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: flareBar.barHeight + flareBar.flareRadius

        Rectangle {
            id: mainBody
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: flareBar.barHeight

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.background }
                GradientStop { position: 1.0; color: flareBar._barDarkColor }
            }
        }

        Shape {
            anchors.top: mainBody.bottom
            anchors.left: parent.left
            width: flareBar.flareRadius; height: flareBar.flareRadius
            antialiasing: true
            layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: flareBar._barDarkColor; strokeWidth: 0
                startX: 0; startY: 0
                PathLine { x: flareBar.flareRadius; y: 0 }
                PathQuad { x: 0; y: flareBar.flareRadius; controlX: 0; controlY: 0 }
            }
        }

        Shape {
            anchors.top: mainBody.bottom
            anchors.right: parent.right
            width: flareBar.flareRadius; height: flareBar.flareRadius
            antialiasing: true
            layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: flareBar._barDarkColor; strokeWidth: 0
                startX: 0; startY: 0
                PathQuad {
                    x: flareBar.flareRadius; y: flareBar.flareRadius
                    controlX: flareBar.flareRadius; controlY: 0
                }
                PathLine { x: flareBar.flareRadius; y: 0 }
                PathLine { x: 0; y: 0 }
            }
        }
    }

    // Sombra densa cercana (contact shadow)
    DropShadow {
        anchors.fill: barShadowHost
        horizontalOffset: 0; verticalOffset: 2
        radius: 4; samples: 8
        color: Qt.rgba(0, 0, 0, 0.45)
        source: barShadowHost
        transparentBorder: true
    }

    // Sombra suave separada (ambient shadow)
    DropShadow {
        anchors.fill: barShadowHost
        horizontalOffset: 0; verticalOffset: 5
        radius: 14; samples: 22
        color: Qt.rgba(0, 0, 0, 0.3)
        source: barShadowHost
        transparentBorder: true
    }

    Item {
        id: barContent
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: flareBar.barHeight
        anchors.leftMargin: flareBar.edgeMargin
        anchors.rightMargin: flareBar.edgeMargin

        // ── Shared DateWidget (single instance) ──
        DateWidget {
            id: dateWidget
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            hostWindow: flareBar
        }

        // ═══════════════════════════════════════════════════════
        // SECONDARY MONITOR — unchanged
        // ═══════════════════════════════════════════════════════
        Item {
            visible: !flareBar.isPrimary
            anchors.fill: parent

            Row {
                id: leftRowSec
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: flareBar.sectionSpacing

                FedoraLogo { }

                WorkspacePills {
                    outputName: flareBar.modelData.name
                    primaryMonitorName: flareBar.primaryMonitorName
                }

                Loader {
                    active: true
                    sourceComponent: SystemPill { }
                }
            }

            Row {
                id: rightRowSec
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: flareBar.sectionSpacing

                Loader {
                    active: true
                    sourceComponent: compBatteryPill
                }

                NetworkPill {
                    id: networkPillSec
                    hostWindow: flareBar
                }

                PowerPill { }
            }
        }

        // ═══════════════════════════════════════════════════════
        // PRIMARY MONITOR — new layout
        // ═══════════════════════════════════════════════════════
        Item {
            visible: flareBar.isPrimary
            anchors.fill: parent

            // ── LEFT EDGE ──
            FocusedWindow {
                anchors.left: parent.left
                anchors.leftMargin: 15
                anchors.verticalCenter: parent.verticalCenter
            }

            // ── RIGHT EDGE ──
            Row {
                id: rightEdgeRow
                anchors.right: parent.right
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                spacing: flareBar.sectionSpacing

                // MusicSpectrumPill { }
                KeyboardPill { }
                NotificationPill { }
                AssistantPill { }
                ScreenshotPill { }
                PowerPill { }
            }

            // ── LEFT of the Date ──
            Row {
                id: centerLeftRow
                x: dateWidget.x - width - flareBar.sectionSpacing
                y: dateWidget.y + (dateWidget.height - height) / 2
                spacing: flareBar.sectionSpacing

                TrayWidget {
                    id: trayWidgetPri
                    hostWindow: flareBar
                }

                WorkspacePills {
                    outputName: flareBar.modelData.name
                    primaryMonitorName: flareBar.primaryMonitorName
                }

                Item {
                    id: musicSlotPri
                    width: musicPri.implicitWidth
                    height: musicPri.implicitHeight

                    CavaBackdrop {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }
                        width: musicPri.implicitWidth - 28
                        height: musicPri.implicitHeight
                        radius: musicPri.capsuleHeight / 2
                        shown: musicPri.player !== null
                        animating: musicPri.playing
                    }

                    MusicWidget {
                        id: musicPri
                        anchors.centerIn: parent
                    }
                }

                UpdatePill { }

                BatteryPill { }
            }

            // ── RIGHT of the Date ──
            Row {
                id: centerRightRow
                x: dateWidget.x + dateWidget.width + flareBar.sectionSpacing
                y: dateWidget.y + (dateWidget.height - height) / 2
                spacing: flareBar.sectionSpacing

                SystemPill { }

                NetworkPill {
                    id: networkPillPri
                    hostWindow: flareBar
                }
            }
        }
    }

    Component { id: compBatteryPill; BatteryPill { } }

    Connections {
        target: PopupManager
        function onToggleMusicRequested() {
            if (!flareBar.isPrimary) return
            musicPri.togglePopup()
        }
        function onToggleNetworkRequested() {
            if (!flareBar.isFocused) return
            const ref = flareBar.isPrimary ? networkPillPri : networkPillSec
            if (ref) ref.togglePopup()
        }
        function onToggleDateRequested() {
            if (!flareBar.isFocused) return
            dateWidget.togglePopup()
        }
    }

    Loader {
        active: flareBar.isPrimary
        sourceComponent: Item {
            MusicPopup {
                widgetRef: musicPri
                parentWindow: flareBar
            }
            TrayPopup {
                widgetRef: trayWidgetPri
                parentWindow: flareBar
            }
            NotificationPanel {
                screen: flareBar.modelData
                barPopupTopY: flareBar.barPopupTopY
            }
            AssistantPanel {
                screen: flareBar.modelData
                barPopupTopY: flareBar.barPopupTopY
            }
            NotificationPopups {
                screen: flareBar.modelData
                barPopupTopY: flareBar.barPopupTopY
            }
        }
    }
}
