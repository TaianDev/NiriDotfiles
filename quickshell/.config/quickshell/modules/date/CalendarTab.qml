import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../components"

Item {
    id: root

    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar
    property color accentGreen: Theme.primary
    property color bgDark: Theme.surface
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    property int dYear: new Date().getFullYear()
    property int dMonth: new Date().getMonth()
    property int selectedDay: new Date().getDate()
    property var daysModel: []
    property var markedDates: []   // Almacena las fechas marcadas como "YYYY-MM-DD"

    function daysInMonth() { return new Date(root.dYear, root.dMonth + 1, 0).getDate() }

    readonly property var selectedDate: root.selectedDay > 0
        ? new Date(root.dYear, root.dMonth, Math.min(root.selectedDay, root.daysInMonth()))
        : new Date()

    function resetToToday() {
        let today = new Date()
        dYear = today.getFullYear()
        dMonth = today.getMonth()
        selectedDay = today.getDate()
        updateCal()
    }

    function navigateMonth(delta) {
        root.dMonth += delta
        if (root.dMonth < 0) { root.dMonth = 11; root.dYear-- }
        if (root.dMonth > 11) { root.dMonth = 0; root.dYear++ }
        updateCal()
    }

    function updateCal() {
        if (root.selectedDay > 0 && root.selectedDay > root.daysInMonth())
            root.selectedDay = root.daysInMonth()
        let temp = []
        let firstDay = new Date(dYear, dMonth, 1).getDay()
        firstDay = firstDay === 0 ? 6 : firstDay - 1
        let daysInMonth = new Date(dYear, dMonth + 1, 0).getDate()
        let daysPrev = new Date(dYear, dMonth, 0).getDate()

        for (let i = firstDay - 1; i >= 0; i--) temp.push({day: daysPrev - i, current: false})
        for (let i = 1; i <= daysInMonth; i++) temp.push({day: i, current: true})
        let rem = 42 - temp.length
        for (let i = 1; i <= rem; i++) temp.push({day: i, current: false})
        daysModel = temp
    }

    Component.onCompleted: {
        updateCal()
        populateAgenda()
    }

    // Models for the combos
    property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    property var weekNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    property var yearModel: {
        let arr = []
        let currentYear = new Date().getFullYear()
        for (let y = currentYear - 50; y <= currentYear + 50; y++) arr.push(y)
        return arr
    }

    // Helper function to know whether a day is marked
    function isMarked(day, isCurrentMonth) {
        if (!isCurrentMonth) return false
        let dateStr = dYear + "-" + String(dMonth+1).padStart(2,'0') + "-" + String(day).padStart(2,'0')
        return markedDates.includes(dateStr)
    }

    function isSelected(day, isCurrentMonth) {
        if (!isCurrentMonth) return false
        if (root.selectedDay <= 0) return false
        return day === Math.min(root.selectedDay, root.daysInMonth())
    }

    function selectDay(day) {
        if (day <= 0 || day > root.daysInMonth()) return
        root.selectedDay = (root.selectedDay === day) ? -1 : day
    }

    function toggleMark(day) {
        if (day <= 0 || day > root.daysInMonth()) return
        let dateStr = root.dYear + "-" + String(root.dMonth+1).padStart(2,'0') + "-" + String(day).padStart(2,'0')
        let newMarked = root.markedDates.slice()
        let idx = newMarked.indexOf(dateStr)
        if (idx > -1) {
            newMarked.splice(idx, 1)
        } else {
            newMarked.push(dateStr)
        }
        root.markedDates = newMarked
    }

    function formatShort(d) {
        return root.monthNames[d.getMonth()].slice(0, 3) + " " + d.getDate() + ", " + d.getFullYear()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        // ─── Header with selectors and "Today" button ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Previous arrow (large hit area, hover)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: prevArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textMain
                    font.pixelSize: 22
                    font.bold: true
                }
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateMonth(-1)
                }
            }

            // Selector de mes
            ComboBox {
                id: monthCombo
                model: root.monthNames
                displayText: root.monthNames[root.dMonth]
                Layout.preferredWidth: 110

                Component.onCompleted: currentIndex = root.dMonth

                Connections {
                    target: root
                    function onDMonthChanged() { monthCombo.currentIndex = root.dMonth }
                }

                background: Rectangle {
                    radius: 6
                    color: monthCombo.hovered ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                    border.color: Theme.alpha(Theme.inkSurf, 0.1)
                    border.width: 1
                }
                contentItem: Text {
                    text: monthCombo.displayText
                    color: root.textMain
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: Text {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                onActivated: {
                    root.dMonth = index
                    root.updateCal()
                }
            }

            // Year selector
            ComboBox {
                id: yearCombo
                model: root.yearModel
                displayText: root.dYear.toString()
                Layout.preferredWidth: 80

                Component.onCompleted: currentIndex = root.yearModel.indexOf(root.dYear)

                Connections {
                    target: root
                    function onDYearChanged() { yearCombo.currentIndex = root.yearModel.indexOf(root.dYear) }
                }

                background: Rectangle {
                    radius: 6
                    color: yearCombo.hovered ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                    border.color: Theme.alpha(Theme.inkSurf, 0.1)
                    border.width: 1
                }
                contentItem: Text {
                    text: yearCombo.displayText
                    color: root.textMain
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: Text {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                onActivated: {
                    root.dYear = root.yearModel[index]
                    root.updateCal()
                }
            }

            // Next arrow (large hit area, hover)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: nextArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.textMain
                    font.pixelSize: 22
                    font.bold: true
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateMonth(1)
                }
            }

            // "Today" button (clock icon)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: todayArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "refresh.svg"
                    size: 18
                    tint: todayArea.containsMouse ? root.textMain : root.textMuted
                }
                MouseArea {
                    id: todayArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetToToday()
                }
            }
        }

        // ─── Weekday names ───
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: root.textMuted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ─── Day grid ───
        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: root.daysModel
                Rectangle {
                    id: dayCell
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8

                    property bool isToday: modelData.current && modelData.day === new Date().getDate() && root.dMonth === new Date().getMonth() && root.dYear === new Date().getFullYear()
                    property bool isSelected: root.isSelected(modelData.day, modelData.current)
                    property bool isMarked: root.isMarked(modelData.day, modelData.current)
                    property bool cellHovered: false
                    property int prevSelected: -1

                    color: isToday ? root.accentGreen
                         : isSelected ? Theme.alpha(root.accentGreen, 0.28)
                         : cellHovered ? Theme.alpha(Theme.inkSurf, 0.08)
                         : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    border.width: isSelected && !isToday ? 1 : 0
                    border.color: Theme.alpha(root.accentGreen, 0.55)

                    // Day number
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: isToday ? root.bgDark : (isSelected ? root.accentGreen : (modelData.current ? root.textMain : root.textMuted))
                        font.pixelSize: 14
                        font.bold: isToday || isSelected
                        opacity: modelData.current ? 1 : 0.5
                    }

                    // Mark indicator dot
                    Rectangle {
                        visible: dayCell.isMarked && modelData.current
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: root.accentGreen
                    }

                    // MouseArea: hover + selection (click) + double click (mark/unmark)
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton

                        onEntered: dayCell.cellHovered = true
                        onExited: dayCell.cellHovered = false

                        onClicked: {
                            if (modelData.current) {
                                dayCell.prevSelected = root.selectedDay
                                root.selectDay(modelData.day)
                            }
                        }

                        onDoubleClicked: {
                            if (modelData.current) {
                                root.selectedDay = dayCell.prevSelected
                                root.toggleMark(modelData.day)
                            }
                        }
                    }
                }
            }
        }

        // ─── Strip de agenda ───
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    Layout.preferredWidth: 130
                    text: root.formatShort(root.selectedDate)
                    color: root.textMain
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: 4
                    Layout.fillHeight: true
                    radius: 2
                    color: Theme.alpha(Theme.outline, 0.4)
                }

                ListView {
                    id: markedDaysList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true
                    interactive: true
                    visible: agendaModel.count > 0
                    model: ListModel { id: agendaModel }

                    delegate: Row {
                        width: implicitWidth
                        height: markedDaysList.height
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.label
                            color: root.textMain
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index < agendaModel.count - 1
                            text: "-"
                            color: root.textMuted
                            font.pixelSize: 11
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: agendaModel.count === 0
                    text: "Double-click to mark a day"
                    color: root.textMuted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }

    function populateAgenda() {
        agendaModel.clear()
        const prefix = root.dYear + "-" + String(root.dMonth + 1).padStart(2, '0') + "-"
        const inMonth = root.markedDates
            .filter(s => s.indexOf(prefix) === 0)
            .sort()
        for (let i = 0; i < inMonth.length; i++) {
            const d = parseInt(inMonth[i].slice(prefix.length), 10)
            agendaModel.append({ label: root.weekNames[new Date(root.dYear, root.dMonth, d).getDay()] + " " + d })
        }
    }

    onMarkedDatesChanged: populateAgenda()
    onDMonthChanged: populateAgenda()
    onDYearChanged: populateAgenda()
}