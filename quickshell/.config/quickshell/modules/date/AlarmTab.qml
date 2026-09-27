import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../components"

Item {
    id: root

    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar
    property color bgLighter: Theme.surfaceVariant
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property var widgetRef: null

    // Field that the bar can forward key events to if the layer surface
    // receives keyboard focus instead of the popup (see Bar.qml).
    readonly property Item activeInput: labelField

    property string editingId: ""
    property bool editorOpen: false
    property int eHour: 8
    property int eMinute: 0
    property string eLabel: ""
    property var eDays: [true, true, true, true, true, true, true]

    readonly property int labelMax: 48

    readonly property bool listEmpty: AlarmService.alarms.length === 0

    function openNew() {
        const now = new Date()
        eHour = Math.min(23, (now.getHours() + 1) % 24)
        eMinute = 0
        eLabel = ""
        eDays = [true, true, true, true, true, true, true]
        editingId = ""
        editorOpen = true
    }

    function openEdit(id) {
        const a = AlarmService.findAlarm(id)
        if (!a) return
        eHour = a.hour
        eMinute = a.minute
        eLabel = a.label ?? ""
        eDays = (a.days ?? [true, true, true, true, true, true, true]).slice()
        editingId = id
        editorOpen = true
    }

    function save() {
        const label = eLabel.trim()
        editorOpen = false
        try {
            if (editingId === "") {
                AlarmService.addAlarm(eHour, eMinute, eDays, label)
            } else {
                AlarmService.updateAlarm(editingId, {
                    hour: eHour,
                    minute: eMinute,
                    days: eDays,
                    label: label
                })
            }
        } catch (e) {
            console.warn("AlarmTab.save:", e)
        }
    }

    function bumpField(field, delta) {
        if (field === "h") eHour = (eHour + delta + 24) % 24
        else eMinute = (eMinute + delta + 60) % 60
    }

    function focusLabel() {
        labelField.forceActiveFocus()
    }

    function daySummary(days) {
        const names = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        const active = []
        for (let i = 0; i < 7; i++) if (days[i]) active.push(i)
        if (active.length === 7) return "Every day"
        if (active.length === 0) return "Once"
        if (active.length === 5 && !days[0] && !days[6]) return "Weekdays"
        if (active.length === 2 && days[0] && days[6]) return "Weekends"
        const sorted = [1, 2, 3, 4, 5, 0, 6].filter(i => days[i]).map(i => names[i])
        return sorted.join(", ")
    }

    function toggleCd(id, enabled) { AlarmService.setEnabled(id, !enabled) }

    function dismissRinging(alarm) { AlarmService.dismiss(alarm) }

    // ─── ESTADO 1: LISTA ───
    Item {
        anchors.fill: parent
        anchors.margins: 20
        opacity: root.editorOpen ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppText {
                    Layout.fillWidth: true
                    text: "Alarms"
                    color: root.textMain
                    font.pixelSize: 20
                    font.bold: true
                }

                RowLayout {
                    visible: !!AlarmService.nextAlarm
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    SvgIcon {
                        source: root.iconsPath + "alarm-clock.svg"
                        size: 14
                        tint: root.textMuted
                    }

                    AppText {
                        text: AlarmService.nextAlarm
                            ? AlarmService.nextAlarm.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
                            : ""
                        color: root.textMuted
                        font.pixelSize: 11
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: alarmList
                    anchors.fill: parent
                    model: AlarmService.alarms
                    spacing: 8
                    clip: true

                    delegate: Rectangle {
                        required property var modelData
                        width: alarmList.width
                        height: 58
                        radius: 12

                        property bool rowRinging: modelData.id === AlarmService.ringingId
                        property bool rowEnabled: (AlarmService.revision, modelData.enabled)

                        color: rowRinging
                            ? Theme.alpha(Theme.err, 0.25)
                            : (rowArea.containsMouse ? Theme.alpha(Theme.primary, 0.1) : Theme.surfaceVariant)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rowRinging
                                ? root.dismissRinging(modelData)
                                : root.openEdit(modelData.id)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            SvgIcon {
                                source: root.iconsPath + "alarm-clock.svg"
                                size: 20
                                tint: rowRinging ? Theme.err : root.textMain
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                AppText {
                                    text: AlarmService.formatTime(modelData)
                                    color: rowRinging ? Theme.err : root.textMain
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                AppText {
                                    text: rowRinging ? "RINGING — click to dismiss"
                                         : (modelData.label ?? "") !== ""
                                             ? modelData.label
                                             : root.daySummary(modelData.days ?? [true, true, true, true, true, true, true])
                                    color: rowRinging ? Theme.err : root.textMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            AppText {
                                text: root.daySummary(modelData.days ?? [true, true, true, true, true, true, true])
                                visible: !rowRinging && (modelData.label ?? "") !== ""
                                color: root.textMuted
                                font.pixelSize: 10
                            }

                            Rectangle {
                                id: toggle
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignVCenter
                                width: 34
                                height: 20
                                radius: 10
                                color: rowEnabled ? Theme.primary : Theme.alpha(Theme.inkSurf, 0.25)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.inkPrim
                                    y: 2
                                    x: rowEnabled ? toggle.width - width - 2 : 2
                                    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleCd(modelData.id, rowEnabled)
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                Layout.alignment: Qt.AlignVCenter
                                width: 26
                                height: 26
                                radius: 8
                                color: delArea.containsMouse ? Theme.alpha(Theme.err, 0.18) : "transparent"

                                SvgIcon {
                                    anchors.centerIn: parent
                                    source: root.iconsPath + "trash.svg"
                                    size: 15
                                    tint: delArea.containsMouse ? Theme.err : root.textMuted
                                }

                                MouseArea {
                                    id: delArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AlarmService.removeAlarm(modelData.id)
                                }
                            }
                        }
                    }
                }

                Column {
                    visible: root.listEmpty
                    anchors.centerIn: parent
                    spacing: 12

                    SvgIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: root.iconsPath + "alarm-clock.svg"
                        size: 42
                        tint: Theme.alpha(Theme.inkSurfVar, 0.6)
                    }

                    AppText {
                        text: "No alarms set"
                        color: root.textMuted
                        font.pixelSize: 13
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 44
            height: 44
            radius: 22
            color: fabArea.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
            Behavior on color { ColorAnimation { duration: 120 } }

            AppText {
                anchors.centerIn: parent
                text: "+"
                color: Theme.inkPrim
                font.pixelSize: 26
                font.bold: true
            }

            MouseArea {
                id: fabArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openNew()
            }
        }
    }

    // ─── ESTADO 2: EDITOR ───
    Item {
        anchors.fill: parent
        anchors.margins: 20
        opacity: root.editorOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            AppText {
                Layout.fillWidth: true
                text: root.editingId === "" ? "New alarm" : "Edit alarm"
                color: root.textMain
                font.pixelSize: 20
                font.bold: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Repeater {
                    model: ["h", "m"]
                    Rectangle {
                        width: 64
                        height: 96
                        radius: 12
                        color: root.bgLighter

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 12
                                color: upArea.containsMouse ? (upArea.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                AppText { anchors.centerIn: parent; text: "+"; color: root.textMain; font.pixelSize: 18 }

                                Timer { id: repUp; interval: 80; repeat: true; onTriggered: root.bumpField(modelData, 1) }
                                Timer { id: delUp; interval: 400; onTriggered: repUp.start() }

                                MouseArea {
                                    id: upArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: { root.bumpField(modelData, 1); delUp.start() }
                                    onReleased: { delUp.stop(); repUp.stop() }
                                    onCanceled: { delUp.stop(); repUp.stop() }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                color: "transparent"

                                AppText {
                                    anchors.centerIn: parent
                                    text: (modelData === "h" ? root.eHour : root.eMinute).toString().padStart(2, "0")
                                    color: root.textMain
                                    font.pixelSize: 30
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 12
                                color: downArea.containsMouse ? (downArea.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                AppText { anchors.centerIn: parent; text: "-"; color: root.textMain; font.pixelSize: 18 }

                                Timer { id: repDown; interval: 80; repeat: true; onTriggered: root.bumpField(modelData, -1) }
                                Timer { id: delDown; interval: 400; onTriggered: repDown.start() }

                                MouseArea {
                                    id: downArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: { root.bumpField(modelData, -1); delDown.start() }
                                    onReleased: { delDown.stop(); repDown.stop() }
                                    onCanceled: { delDown.stop(); repDown.stop() }
                                }
                            }
                        }
                    }
                }

                AppText {
                    text: ":"
                    color: root.textMain
                    font.pixelSize: 30
                    font.bold: true
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        // Repeater index closure: use main.daysActive via function call
                        color: chipArea.containsMouse
                            ? (root.eDays[index] ? Qt.lighter(Theme.primaryContainer, 1.15) : Theme.alpha(Theme.inkSurf, 0.12))
                            : (root.eDays[index] ? Theme.primaryContainer : Theme.alpha(Theme.inkSurf, 0.08))
                        Behavior on color { ColorAnimation { duration: 120 } }

                        AppText {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.eDays[index] ? Theme.onPrimaryContainer : root.textMuted
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const d = root.eDays.slice()
                                d[index] = !d[index]
                                root.eDays = d
                            }
                        }
                    }
                }
            }

            TextField {
                id: labelField
                font.family: Theme.fontFamily
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 260
                Layout.preferredHeight: 40
                placeholderText: "Label (optional)"
                color: root.textMain
                placeholderTextColor: root.textMuted
                font.pixelSize: 14
                selectionColor: Theme.primary
                selectedTextColor: Theme.inkPrim
                activeFocusOnPress: true
                selectByMouse: true
                maximumLength: root.labelMax
                text: root.eLabel

                onTextChanged: {
                    if (text !== root.eLabel)
                        root.eLabel = text
                }

                background: Rectangle {
                    radius: 8
                    color: Theme.alpha(Theme.inkSurf, 0.08)
                    border.width: 1
                    border.color: Theme.alpha(Theme.primary,
                        labelField.activeFocus ? 0.8 : (root.eLabel.length > 0 ? 0.6 : 0.25))
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Rectangle {
                    width: 110
                    height: 38
                    radius: 19
                    color: saveArea.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                    Behavior on color { ColorAnimation { duration: 120 } }

                    AppText {
                        anchors.centerIn: parent
                        text: "Save"
                        color: Theme.inkPrim
                        font.bold: true
                    }

                    MouseArea {
                        id: saveArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.save()
                    }
                }

                Rectangle {
                    width: 110
                    height: 38
                    radius: 19
                    color: cancelArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    AppText {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: root.textMuted
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editorOpen = false
                    }
                }
            }
        }
    }
}