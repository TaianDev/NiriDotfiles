import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"

PopupWindow {
    id: popup
    color: "transparent"
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    
    implicitWidth: popup.notesWidth
    implicitHeight: popup.notesHeight

    property int baseWidth: 480
    property int baseHeight: 360
    property int notesWidth: 860
    property int notesHeight: 540

    readonly property bool isNotesTab: popup.currentTab === 4

    property real panelW: popup.isNotesTab ? popup.notesWidth : popup.baseWidth
    property real panelH: popup.isNotesTab ? popup.notesHeight : popup.baseHeight
    Behavior on panelW { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on panelH { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property bool isOpened: false
    property int currentTab: 0
    property var widgetRef: null
    property var anchorItem: null
    property var parentWindow: null
    property alias timerTab: timerTabInstance
    property alias alarmTabInstance: alarmTabInstance
    property alias notesTabInstance: notesTabInstance

    property color bgDark: Theme.surface
    property color bgLighter: Theme.surfaceVariant
    property color accentGreen: Theme.primary
    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar

    visible: isOpened || shell.exitRunning

    grabFocus: isOpened

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.dateId)
                popup.isOpened = false
        }
    }

    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right

    mask: Region {
        id: panelMask
        item: panelContainer
        radius: 16
    }

    Connections {
        target: shell
        function onSlideYChanged() { panelMask.changed() }
    }

    function reposition() {
        if (!anchorItem || !parentWindow)
            return
        const pos = anchorItem.mapToItem(parentWindow.contentItem, 0, anchorItem.height)
        const ax = pos.x + anchorItem.width / 2 - popup.implicitWidth / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, popup.implicitWidth, popup.implicitHeight)
        anchor.updateAnchor()
    }

    function prepareTimerTab() {
        if (currentTab !== 2)
            return
        timerTabInstance.selectField(1)
        Qt.callLater(() => {
            popupKeyInput.forceActiveFocus()
            if (parentWindow && parentWindow.focusTimerKeys)
                parentWindow.focusTimerKeys()
        })
    }

    onCurrentTabChanged: prepareTimerTab()

    Connections {
        target: popup.alarmTabInstance
        function onEditorOpenChanged() {
            if (popup.alarmTabInstance.editorOpen)
                Qt.callLater(popup.alarmTabInstance.focusLabel)
        }
    }

    Connections {
        target: popup.notesTabInstance
        function onEditorOpenChanged() {
            if (popup.notesTabInstance.editorOpen)
                Qt.callLater(popup.notesTabInstance.focusTitle)
        }
    }

    onIsOpenedChanged: {
        if (!isOpened)
            PopupManager.notifyClosed(PopupManager.dateId)

        if (isOpened) {
            reposition()
            shell.active = true
            Qt.callLater(prepareTimerTab)
        } else {
            shell.active = false
            // Leaving edit mode on close means reopening the popup shows the
            // normal tab again and drops the layer-surface keyboard grab.
            if (notesTabInstance.editorOpen) notesTabInstance.editorOpen = false
            if (alarmTabInstance.editorOpen) alarmTabInstance.editorOpen = false
        }
    }

    onVisibleChanged: {
        if (visible) {
            reposition()
        } else if (popup.isOpened && !shell.exitRunning) {
            popup.isOpened = false
        }
    }

    PopupEscCapture {
        active: popup.isOpened
        popupId: PopupManager.dateId

        Item {
            id: popupKeyInput
            focus: popup.currentTab === 2
            Keys.onPressed: event => {
                if (popup.currentTab === 2)
                    timerTabInstance.handleKey(event)
            }
        }

        PopupEnterExit {
            id: shell
            anchors.fill: parent
            active: popup.isOpened
            cornerRadius: 16
            panelColor: "transparent"
            borderAlpha: 0

            Item {
            id: panelContainer
            width: popup.panelW
            height: popup.panelH
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.background
            border.width: 1
            border.color: Theme.outlineVariant
            clip: true

            RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Calendar", icon: "calendar.svg", index: 0 },
                            { name: "Stopwatch", icon: "stopwatch.svg", index: 1 },
                            { name: "Timer", icon: "timer.svg", index: 2 },
                            { name: "Alarm", icon: "alarm-clock.svg", index: 3 },
                            { name: "Notes", icon: "notes.svg", index: 4 }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: 12
                            color: popup.currentTab === modelData.index
                                   ? Theme.alpha(Theme.primary, 0.18)
                                   : (btnMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.05) : "transparent")

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                SvgIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: popup.iconsPath + modelData.icon
                                    size: 20
                                    tint: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted
                                }
                                AppText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    color: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted
                                    font.pixelSize: 11
                                }
                            }
                            MouseArea {
                                id: btnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.currentTab = modelData.index
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.alpha(Theme.outline, 0.25)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                CalendarTab {
                    anchors.fill: parent
                    textMain: popup.textMain
                    textMuted: popup.textMuted
                    accentGreen: popup.accentGreen
                    bgDark: popup.bgDark
                    property bool isActive: popup.currentTab === 0
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                StopwatchTab {
                    anchors.fill: parent
                    textMain: popup.textMain
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 1
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                TimerTab {
                    id: timerTabInstance
                    anchors.fill: parent
                    textMain: popup.textMain
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 2
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                AlarmTab {
                    id: alarmTabInstance
                    anchors.fill: parent
                    textMain: popup.textMain
                    textMuted: popup.textMuted
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 3
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                NotesTab {
                    id: notesTabInstance
                    anchors.fill: parent
                    textMain: popup.textMain
                    textMuted: popup.textMuted
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 4
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }
            }
        }
        }
        }
    }
    }
}
