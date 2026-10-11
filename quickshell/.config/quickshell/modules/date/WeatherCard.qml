import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"
import "../../services"

// WeatherCard — clima actual + pronóstico de 5 días (flex, ocupa todo el card).
Item {
    id: root

    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar
    property color accent: Theme.primary

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // ── Actual ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppText {
                text: WeatherService.glyph !== "" ? WeatherService.glyph : "\ue302"
                color: root.accent
                font.pixelSize: 26
            }
            AppText {
                text: WeatherService.temperature !== "" ? WeatherService.temperature : "--"
                color: root.textMain
                font.pixelSize: 20
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
            AppText {
                Layout.fillWidth: true
                text: WeatherService.location !== "" ? WeatherService.location : "\u2014"
                color: root.textMain
                font.pixelSize: 13
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        // ── Pronóstico (cada día en su mini-tarjeta) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: WeatherService.forecast.length > 0

            Repeater {
                model: WeatherService.forecast

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Theme.alpha(Theme.inkSurf, 0.05)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 1

                        AppText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.weekday
                            color: root.textMuted
                            font.pixelSize: 10
                        }
                        AppText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            text: modelData.glyph
                            color: root.accent
                            font.pixelSize: 18
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                        AppText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.max + "\u00b0 " + modelData.min + "\u00b0"
                            color: root.textMain
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        AppText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: WeatherService.forecast.length === 0
            text: "Loading forecast…"
            color: root.textMuted
            font.pixelSize: 11
            verticalAlignment: Text.AlignVCenter
        }
    }
}
