import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../services"
import "../../utils"
import "../../components"

// Módulo de privacidad: quién usa el micrófono (Audio) y la cámara (Video).
// Dos filas por sección: píldora de sección (arriba) y apps (abajo), centradas.
ColumnLayout {
    id: root
    spacing: 8

    // Activa el polling solo cuando el hub está abierto en la sección Home.
    readonly property bool hubHome: HubService.opened && HubService.section === 0
    onHubHomeChanged: PrivacyService.active = hubHome
    Component.onCompleted: PrivacyService.active = false

    // ── Audio ──
    Item {
        Layout.fillWidth: true
        implicitHeight: audioHeader.height + 6 + audioFlow.implicitHeight

        HeaderPill {
            id: audioHeader
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            iconSource: AppPaths.iconsDir + "mic.svg"
            label: "Audio"
        }

        Flow {
            id: audioFlow
            anchors.top: audioHeader.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(audioFlow.implicitWidth, root.width)
            spacing: 6

            Repeater {
                model: PrivacyService.audio
                AppPill {
                    required property var modelData
                    name: modelData.name
                    binary: modelData.binary
                    canKill: modelData.pid > 1
                    onKilled: PrivacyService.killPid(modelData.pid)
                }
            }

            AppText {
                height: 24
                verticalAlignment: Text.AlignVCenter
                text: "No active apps"
                color: Theme.inkSurfVar
                font.pixelSize: 10
                opacity: 0.5
                visible: PrivacyService.audio.length === 0
            }
        }
    }

    // ── Video ──
    Item {
        Layout.fillWidth: true
        implicitHeight: videoHeader.height + 6 + videoFlow.implicitHeight

        HeaderPill {
            id: videoHeader
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: "\uf030"
            label: "Video"
        }

        Flow {
            id: videoFlow
            anchors.top: videoHeader.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(videoFlow.implicitWidth, root.width)
            spacing: 6

            Repeater {
                model: PrivacyService.video
                AppPill {
                    required property var modelData
                    name: modelData.name
                    binary: modelData.binary
                    canKill: modelData.pid > 1
                    onKilled: PrivacyService.killPid(modelData.pid)
                }
            }

            AppText {
                height: 24
                verticalAlignment: Text.AlignVCenter
                text: "No active apps"
                color: Theme.inkSurfVar
                font.pixelSize: 10
                opacity: 0.5
                visible: PrivacyService.video.length === 0
            }
        }
    }

    Item { Layout.fillHeight: true }

    // ── Píldora de encabezado (identifica la sección) ──
    component HeaderPill: Rectangle {
        id: header
        property string label: ""
        property string iconSource: ""
        property string glyph: ""

        implicitWidth: hdr.implicitWidth + 18
        implicitHeight: 24
        radius: 12
        color: Theme.alpha(Theme.surfaceVariant, 0.55)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.3)

        RowLayout {
            id: hdr
            anchors.centerIn: parent
            spacing: 5

            SvgIcon {
                visible: header.iconSource !== ""
                source: header.iconSource
                size: 12
                tint: Theme.primary
            }

            AppText {
                visible: header.glyph !== ""
                text: header.glyph
                color: Theme.primary
                font.pixelSize: 12
            }

            AppText {
                text: header.label
                color: Theme.inkSurf
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    // ── Píldora de app (icono de la app + nombre + matar) ──
    component AppPill: Rectangle {
        id: appPill
        property string name: ""
        property string binary: ""
        property bool canKill: true
        signal killed()

        readonly property string iconSource: {
            let e = null
            try { e = DesktopEntries.heuristicLookup(appPill.name) } catch (x) {}
            if ((!e || !e.icon) && appPill.binary !== "") {
                try { e = DesktopEntries.byId(appPill.binary) } catch (x) {}
            }
            if (e && e.icon) {
                const p = Quickshell.iconPath(e.icon, true)
                if (p && p !== "")
                    return p
            }
            const byName = IconResolver.resolveThemeIcon((appPill.binary || appPill.name || "").toLowerCase())
            if (byName !== "")
                return byName
            return IconResolver.fallbackAppIcon()
        }

        implicitWidth: appRow.implicitWidth + 16
        implicitHeight: 24
        radius: 12
        color: Theme.alpha(Theme.surfaceVariant, 0.45)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.2)

        RowLayout {
            id: appRow
            anchors.centerIn: parent
            spacing: 6

            Image {
                visible: appPill.iconSource !== ""
                source: appPill.iconSource
                sourceSize: Qt.size(14, 14)
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            AppText {
                text: appPill.name
                color: Theme.inkSurf
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.maximumWidth: 120
            }

            AppText {
                visible: appPill.canKill
                text: "✕"
                color: killMa.containsMouse ? Theme.err : Theme.inkSurfVar
                font.pixelSize: 10
                font.bold: true

                MouseArea {
                    id: killMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appPill.killed()
                }
            }
        }
    }
}
