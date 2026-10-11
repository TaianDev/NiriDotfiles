import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../core"
import "../../services"

Item {
    id: root

    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar
    property color bgLighter: Theme.surfaceVariant

    // Connection to the global Dynamic Island state
    property var widgetRef: null

    property int h: widgetRef ? widgetRef.tmH : 0
    property int m: widgetRef ? widgetRef.tmM : 0
    property int s: widgetRef ? widgetRef.tmS : 0
    property int totalSecs: widgetRef ? widgetRef.tmTotalSecs : 0
    property bool isActive: widgetRef ? widgetRef.tmActive : false
    property bool isRunning: widgetRef ? widgetRef.tmRunning : false

    property int activeFieldIndex: -1
    property int cursorPos: 2
    property bool caretOn: false

    Timer {
        id: caretBlink
        interval: 500
        repeat: true
        running: root.activeFieldIndex >= 0 && !root.isActive
        onTriggered: root.caretOn = !root.caretOn
    }

    function fieldValue(idx) {
        return idx === 0 ? root.h : idx === 1 ? root.m : root.s
    }

    function fieldMax(idx) {
        return idx === 0 ? 99 : 59
    }

    function selectField(idx) {
        activeFieldIndex = idx
        cursorPos = 2
        caretOn = true
        if (widgetRef) widgetRef.timerFocused = true
    }

    function moveCursor(delta) {
        if (root.isActive) return
        if (activeFieldIndex < 0) selectField(1)
        cursorPos = Math.max(0, Math.min(2, cursorPos + delta))
        caretOn = true
    }

    function insertDigit(d) {
        if (root.isActive) return
        if (activeFieldIndex < 0) selectField(1)
        const maxVal = fieldMax(activeFieldIndex)
        const cur = fieldValue(activeFieldIndex)
        let newVal = cur
        if (cursorPos === 2) {
            newVal = (cur * 10 + d) % 100
            if (newVal > maxVal) newVal = d
        } else if (cursorPos === 0) {
            newVal = d * 10 + (cur % 10)
        } else {
            newVal = Math.floor(cur / 10) * 10 + d
        }
        setTimeVal(activeFieldIndex, Math.min(newVal, maxVal))
        cursorPos = Math.min(cursorPos + 1, 2)
        caretOn = true
    }

    function backspaceField() {
        if (root.isActive) return
        if (activeFieldIndex < 0) return
        const cur = fieldValue(activeFieldIndex)
        if (cursorPos === 2) {
            setTimeVal(activeFieldIndex, Math.floor(cur / 10))
        } else if (cursorPos === 1) {
            setTimeVal(activeFieldIndex, cur % 10)
            cursorPos = 0
        }
        caretOn = true
    }

    function deleteForward() {
        if (root.isActive) return
        if (activeFieldIndex < 0) return
        const cur = fieldValue(activeFieldIndex)
        if (cursorPos === 0) {
            setTimeVal(activeFieldIndex, cur % 10)
        } else if (cursorPos === 1) {
            setTimeVal(activeFieldIndex, Math.floor(cur / 10) * 10)
        }
        caretOn = true
    }

    function startTimer() {
        if (!widgetRef) return
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
        if (widgetRef.tmTotalSecs > 0) {
            widgetRef.tmActive = true
            widgetRef.tmRunning = true
            widgetRef.timerFocused = false
        }
    }

    function handleKey(event) {
        if (root.isActive) {
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Backspace) {
            backspaceField()
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            deleteForward()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            moveCursor(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            moveCursor(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Home) {
            if (activeFieldIndex < 0) selectField(1)
            cursorPos = 0
            caretOn = true
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_End) {
            if (activeFieldIndex < 0) selectField(1)
            cursorPos = 2
            caretOn = true
            event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
            if (activeFieldIndex < 0) selectField(1)
            else selectField((activeFieldIndex + 1) % 3)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            startTimer()
            event.accepted = true
        } else {
            const ch = event.text
            if (ch.length === 1 && ch >= "0" && ch <= "9") {
                insertDigit(parseInt(ch, 10))
                event.accepted = true
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                insertDigit(event.key - Qt.Key_0)
                event.accepted = true
            }
        }
    }

    function setQuick(mins) {
        if (!widgetRef) return
        widgetRef.tmH = Math.floor(mins / 60)
        widgetRef.tmM = mins % 60
        widgetRef.tmS = 0
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
        widgetRef.tmActive = true
        widgetRef.tmRunning = true
        widgetRef.timerFocused = false
    }

    function updateTime(idx, delta) {
        if (!widgetRef) return
        if (idx === 0) {
            widgetRef.tmH = Math.max(0, Math.min(99, widgetRef.tmH + delta))
        } else if (idx === 1) {
            let newVal = widgetRef.tmM + delta
            if (newVal > 59) newVal = 0
            else if (newVal < 0) newVal = 59
            widgetRef.tmM = newVal
        } else if (idx === 2) {
            let newVal = widgetRef.tmS + delta
            if (newVal > 59) newVal = 0
            else if (newVal < 0) newVal = 59
            widgetRef.tmS = newVal
        }
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
    }

    function setTimeVal(idx, val) {
        if (!widgetRef) return
        if (idx === 0) widgetRef.tmH = Math.max(0, Math.min(99, val))
        else if (idx === 1) widgetRef.tmM = Math.max(0, Math.min(59, val))
        else if (idx === 2) widgetRef.tmS = Math.max(0, Math.min(59, val))
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
    }

    Item {
        anchors.fill: parent

        // ─── STATE 1: SETUP ───
        Item {
            anchors.fill: parent
            opacity: root.isActive ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                Item { Layout.fillHeight: true }

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Quick start"
                    color: root.textMain
                    font.pixelSize: 10
                    font.bold: true
                }

                // Quick start (chips compactos)
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 4
                    columnSpacing: 6
                    rowSpacing: 6

                    Repeater {
                        model: [1, 2, 3, 5, 10, 15, 30, 60]
                        Rectangle {
                            width: 46
                            height: 26
                            radius: 7

                            color: qsMa.containsMouse ? Qt.lighter(root.bgLighter, 1.3) : root.bgLighter
                            Behavior on color { ColorAnimation { duration: 150 } }

                            AppText {
                                anchors.centerIn: parent
                                text: modelData === 60 ? "1h" : modelData + "m"
                                color: root.textMain
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: qsMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setQuick(modelData)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Set timer"
                    color: root.textMain
                    font.pixelSize: 10
                    font.bold: true
                }

                // Set timer: pills H/M/S editables + Start
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 80
                            height: 34
                            radius: 9
                            color: root.bgLighter

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.fillHeight: true
                                    radius: 9
                                    color: minusMa.containsMouse ? (minusMa.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    AppText { anchors.centerIn: parent; text: "−"; color: root.textMain; font.pixelSize: 15 }

                                    Timer { id: repMinus; interval: 80; repeat: true; onTriggered: root.updateTime(index, -1) }
                                    Timer { id: delMinus; interval: 400; onTriggered: repMinus.start() }

                                    MouseArea {
                                        id: minusMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: { root.updateTime(index, -1); delMinus.start() }
                                        onReleased: { delMinus.stop(); repMinus.stop() }
                                        onCanceled: { delMinus.stop(); repMinus.stop() }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    AppText {
                                        id: digitText
                                        anchors.centerIn: parent
                                        text: (index === 0 ? root.h : index === 1 ? root.m : root.s).toString().padStart(2, "0")
                                        color: root.textMain
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: (parent.width - digitText.width) / 2 + root.cursorPos * (digitText.width / 2)
                                        width: 2
                                        height: 15
                                        radius: 1
                                        color: Theme.primary
                                        visible: index === root.activeFieldIndex && root.caretOn
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: root.selectField(index)
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.fillHeight: true
                                    radius: 9
                                    color: plusMa.containsMouse ? (plusMa.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    AppText { anchors.centerIn: parent; text: "+"; color: root.textMain; font.pixelSize: 15 }

                                    Timer { id: repPlus; interval: 80; repeat: true; onTriggered: root.updateTime(index, 1) }
                                    Timer { id: delPlus; interval: 400; onTriggered: repPlus.start() }

                                    MouseArea {
                                        id: plusMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: { root.updateTime(index, 1); delPlus.start() }
                                        onReleased: { delPlus.stop(); repPlus.stop() }
                                        onCanceled: { delPlus.stop(); repPlus.stop() }
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 76
                    height: 30
                    radius: 15

                    color: empMa.containsMouse ? Theme.alpha(Theme.secondary, 0.9) : Theme.secondaryContainer
                    Behavior on color { ColorAnimation { duration: 150 } }

                    AppText {
                        anchors.centerIn: parent
                        text: "Start"
                        color: Theme.inkSecCont
                        font.bold: true
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: empMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startTimer()
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ─── STATE 2: CUENTA REGRESIVA ───
        Item {
            anchors.fill: parent
            opacity: root.isActive ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                AppText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.floor(root.totalSecs / 3600).toString().padStart(2, '0') + ":" + Math.floor((root.totalSecs % 3600) / 60).toString().padStart(2, '0') + ":" + (root.totalSecs % 60).toString().padStart(2, '0')
                    color: root.textMain
                    font.pixelSize: 34
                    font.weight: Font.Thin
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Rectangle {
                        width: 84
                        height: 30
                        radius: 15

                        color: prMa.containsMouse ? Qt.lighter(root.bgLighter, 1.3) : root.bgLighter
                        Behavior on color { ColorAnimation { duration: 150 } }

                        AppText {
                            anchors.centerIn: parent
                            text: root.isRunning ? "Pause" : "Resume"
                            color: Theme.inkSecCont
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: prMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (widgetRef) widgetRef.tmRunning = !widgetRef.tmRunning }
                        }
                    }

                    Rectangle {
                        width: 84
                        height: 30
                        radius: 15

                        color: canMa.containsMouse ? Theme.alpha(Theme.err, 0.9) : Theme.errContainer
                        Behavior on color { ColorAnimation { duration: 150 } }

                        AppText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.inkSecCont
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: canMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (widgetRef) {
                                    widgetRef.tmRunning = false
                                    widgetRef.tmActive = false
                                    widgetRef.tmTotalSecs = 0
                                    widgetRef.tmH = 0
                                    widgetRef.tmM = 0
                                    widgetRef.tmS = 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
