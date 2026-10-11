import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../components"
import "../date"

// Sección Date: una sola página 2x2 con Calendar + Weather (izquierda) y
// Stopwatch + Timer (derecha). (Alarm queda fuera por ahora.)
Item {
    id: root

    property var widgetRef: null

    // Alto del dashboard (ya no hay sub-pestañas que lo ajusten).
    readonly property int contentHeight: 420

    function handleKey(event) {
        // Esc cierra el hub (la barra tiene el teclado en exclusivo mientras
        // el timer está enfocado, así que lo resolvemos aquí).
        if (event.key === Qt.Key_Escape) {
            HubService.close()
            event.accepted = true
            return
        }
        timerTabInstance.handleKey(event)
    }

    // Al cerrar el hub, soltar el foco del timer para no capturar el teclado.
    Connections {
        target: HubService
        function onOpenedChanged() {
            if (!HubService.opened && root.widgetRef)
                root.widgetRef.timerFocused = false
        }
    }

    Component.onCompleted: HubService.dateTab = 0

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // ── Columna izquierda: Calendar (arriba) + Weather (abajo) ──
        ColumnLayout {
            id: leftCol
            Layout.preferredWidth: 300
            Layout.minimumWidth: 260
            Layout.maximumWidth: 300
            Layout.fillHeight: true
            spacing: 10

            // Calendar
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 250

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.alpha(Theme.inkSurf, 0.04)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    SectionTitle {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "calendar.svg"
                        label: "Calendar"
                    }

                    CalendarTab {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        textMain: Theme.inkSurf
                        textMuted: Theme.inkSurfVar
                        accentGreen: Theme.primary
                        bgDark: Theme.surface
                    }
                }
            }

            // Weather
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.alpha(Theme.inkSurf, 0.04)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    SectionTitle {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "temperature.svg"
                        label: "Weather"
                    }

                    WeatherCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        textMain: Theme.inkSurf
                        textMuted: Theme.inkSurfVar
                        accent: Theme.primary
                    }
                }
            }
        }

        // ── Columna derecha: Stopwatch (arriba) + Timer (abajo) ──
        ColumnLayout {
            id: rightCol
            Layout.fillWidth: true
            Layout.minimumWidth: 260
            Layout.fillHeight: true
            spacing: 10

            // Stopwatch
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 96

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.alpha(Theme.inkSurf, 0.04)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    SectionTitle {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "stopwatch.svg"
                        label: "Stopwatch"
                    }

                    StopwatchTab {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        textMain: Theme.inkSurf
                        bgLighter: Theme.surfaceVariant
                        widgetRef: root.widgetRef
                    }
                }
            }

            // Timer
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 240

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.alpha(Theme.inkSurf, 0.04)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    SectionTitle {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "timer.svg"
                        label: "Timer"
                    }

                    TimerTab {
                        id: timerTabInstance
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        textMain: Theme.inkSurf
                        textMuted: Theme.inkSurfVar
                        bgLighter: Theme.surfaceVariant
                        widgetRef: root.widgetRef
                    }
                }
            }
        }
    }
}
