import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../components"
import "../../core"
import "../../utils"

RowLayout {
    id: root
    spacing: 6

    property var playerList: []
    property int activeIndex: 0
    property string iconsPath: ""

    readonly property bool hasPlayers: playerList.length > 1
    readonly property var activePlayer: playerList.length > 0 ? playerList[activeIndex] : null

    signal playerChanged(int index, int direction)

    function playerIcon(mprisPlayer) {
        if (!mprisPlayer)
            return ""
        const candidates = IconResolver.playerIconCandidates(mprisPlayer)
        return IconResolver.resolveIconFromCandidates(candidates)
    }

    function cycle(delta) {
        const n = playerList.length
        if (n <= 1)
            return
        const next = (activeIndex + delta + n) % n
        root.playerChanged(next, delta)
    }

    Item {
        Layout.preferredWidth: root.hasPlayers ? 20 : 0
        Layout.preferredHeight: 20
        visible: root.hasPlayers
        opacity: prevMa.containsMouse ? 0.6 : 0.85
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Image {
            anchors.centerIn: parent
            source: root.iconsPath + "up.svg"
            width: 12; height: 12
            rotation: -90
            fillMode: Image.PreserveAspectFit
            cache: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: Theme.onBackgroundMuted }
        }
        MouseArea {
            id: prevMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycle(-1)
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: playerCapsuleContent.width + 16
        Layout.preferredHeight: 24
        radius: 12
        color: Theme.alpha(Theme.primaryContainer, 0.45)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.2)

        Row {
            id: playerCapsuleContent
            anchors.centerIn: parent
            spacing: 6
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Connections {
                target: root
                function onActiveIndexChanged() {
                    playerCapsuleContent.opacity = 0
                    Qt.callLater(function() { playerCapsuleContent.opacity = 1 })
                }
            }

            Image {
                id: capsuleIcon
                anchors.verticalCenter: parent.verticalCenter
                source: root.playerIcon(root.activePlayer)
                width: 14; height: 14
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 14
                sourceSize.height: 14
                cache: false
                visible: status === Image.Ready
            }

            AppText {
                id: capsuleLabel
                anchors.verticalCenter: parent.verticalCenter
                text: (root.activePlayer?.identity ?? root.activePlayer?.playerName ?? "").toString()
                color: Theme.onPrimaryContainer
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    Item {
        Layout.preferredWidth: root.hasPlayers ? 20 : 0
        Layout.preferredHeight: 20
        visible: root.hasPlayers
        opacity: nextMa.containsMouse ? 0.6 : 0.85
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Image {
            anchors.centerIn: parent
            source: root.iconsPath + "up.svg"
            width: 12; height: 12
            rotation: 90
            fillMode: Image.PreserveAspectFit
            cache: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: Theme.onBackgroundMuted }
        }
        MouseArea {
            id: nextMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycle(1)
        }
    }
}