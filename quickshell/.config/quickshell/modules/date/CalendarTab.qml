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
    property var markedDates: []   // Días marcados como "YYYY-MM-DD"

    function daysInMonth() { return new Date(root.dYear, root.dMonth + 1, 0).getDate() }

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

    Component.onCompleted: updateCal()

    property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    property var yearModel: {
        let arr = []
        let currentYear = new Date().getFullYear()
        for (let y = currentYear - 50; y <= currentYear + 50; y++) arr.push(y)
        return arr
    }

    function dateStr(day) {
        return root.dYear + "-" + String(root.dMonth + 1).padStart(2, '0') + "-" + String(day).padStart(2, '0')
    }

    function isTodayDate(day, isCurrentMonth) {
        return isCurrentMonth
            && day === new Date().getDate()
            && root.dMonth === new Date().getMonth()
            && root.dYear === new Date().getFullYear()
    }

    function isMarked(day, isCurrentMonth) {
        if (!isCurrentMonth) return false
        return root.markedDates.includes(root.dateStr(day))
    }

    function isSelected(day, isCurrentMonth) {
        if (!isCurrentMonth) return false
        return day === Math.min(root.selectedDay, root.daysInMonth())
    }

    // Clic simple: selecciona el día (simple, sin revertir).
    function selectDay(day) {
        if (day <= 0 || day > root.daysInMonth()) return
        root.selectedDay = day
    }

    // Doble clic: marca/desmarca con un cuadro y mantiene la selección.
    // El día actual no se puede marcar.
    function toggleMark(day) {
        if (day <= 0 || day > root.daysInMonth()) return
        if (root.isTodayDate(day, true)) return
        let ds = root.dateStr(day)
        let newMarked = root.markedDates.slice()
        let idx = newMarked.indexOf(ds)
        if (idx > -1) newMarked.splice(idx, 1)
        else newMarked.push(ds)
        root.markedDates = newMarked
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

        // ─── Header: navegación + selectores + "hoy" ───
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 7
                color: prevArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                AppText {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textMain
                    font.pixelSize: 16
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

            ComboBox {
                id: monthCombo
                model: root.monthNames
                displayText: root.monthNames[root.dMonth]
                Layout.fillWidth: true
                Layout.preferredWidth: 84
                Layout.preferredHeight: 26

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
                contentItem: AppText {
                    text: monthCombo.displayText
                    color: root.textMain
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: AppText {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 11
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }

                delegate: ItemDelegate {
                    id: monthItem
                    width: ListView.view.width
                    implicitHeight: 30
                    highlighted: monthCombo.highlightedIndex === index
                    readonly property bool selectedItem: index === monthCombo.currentIndex

                    contentItem: AppText {
                        text: modelData
                        color: monthItem.selectedItem ? Theme.inkPrimCont
                             : monthItem.highlighted ? Theme.primary
                             : root.textMain
                        font.pixelSize: 13
                        font.bold: monthItem.selectedItem
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        radius: 7
                        color: monthItem.selectedItem ? Theme.primaryContainer
                             : monthItem.highlighted ? Theme.alpha(Theme.primary, 0.14)
                             : "transparent"
                    }
                }

                popup: Popup {
                    y: monthCombo.height + 4
                    width: monthCombo.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 30 * 8 + 8)
                    padding: 4

                    background: Rectangle {
                        radius: 10
                        color: Theme.surfaceVariant
                        border.width: 1
                        border.color: Theme.outlineVariant
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: monthCombo.popup.visible ? monthCombo.delegateModel : null
                        currentIndex: monthCombo.highlightedIndex
                        boundsBehavior: Flickable.StopAtBounds
                        snapMode: ListView.SnapToItem
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    onOpened: contentItem.positionViewAtIndex(monthCombo.highlightedIndex, ListView.Center)
                }

                onActivated: {
                    root.dMonth = index
                    root.updateCal()
                }
            }

            ComboBox {
                id: yearCombo
                model: root.yearModel
                displayText: root.dYear.toString()
                Layout.fillWidth: true
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26

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
                contentItem: AppText {
                    text: yearCombo.displayText
                    color: root.textMain
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: AppText {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 11
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }

                delegate: ItemDelegate {
                    id: yearItem
                    width: ListView.view.width
                    implicitHeight: 30
                    highlighted: yearCombo.highlightedIndex === index
                    readonly property bool selectedItem: index === yearCombo.currentIndex

                    contentItem: AppText {
                        text: modelData
                        color: yearItem.selectedItem ? Theme.inkPrimCont
                             : yearItem.highlighted ? Theme.primary
                             : root.textMain
                        font.pixelSize: 13
                        font.bold: yearItem.selectedItem
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        radius: 7
                        color: yearItem.selectedItem ? Theme.primaryContainer
                             : yearItem.highlighted ? Theme.alpha(Theme.primary, 0.14)
                             : "transparent"
                    }
                }

                popup: Popup {
                    y: yearCombo.height + 4
                    width: yearCombo.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 30 * 8 + 8)
                    padding: 4

                    background: Rectangle {
                        radius: 10
                        color: Theme.surfaceVariant
                        border.width: 1
                        border.color: Theme.outlineVariant
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: yearCombo.popup.visible ? yearCombo.delegateModel : null
                        currentIndex: yearCombo.highlightedIndex
                        boundsBehavior: Flickable.StopAtBounds
                        snapMode: ListView.SnapToItem
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }
                    onOpened: contentItem.positionViewAtIndex(yearCombo.highlightedIndex, ListView.Center)
                }

                onActivated: {
                    root.dYear = root.yearModel[index]
                    root.updateCal()
                }
            }

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 7
                color: nextArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                AppText {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.textMain
                    font.pixelSize: 16
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

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 7
                color: todayArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.1) : "transparent"
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "refresh.svg"
                    size: 15
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

        // ─── Nombres de los días ───
        RowLayout {
            id: weekdayRow
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                AppText {
                    Layout.fillWidth: true
                    text: modelData
                    color: root.textMuted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ─── Grilla de días ───
        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.preferredHeight: 157
            columns: 7
            rowSpacing: 5
            columnSpacing: 5

            Repeater {
                model: root.daysModel
                Rectangle {
                    id: dayCell
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 7

                    property bool isTodayCell: modelData.current && root.isTodayDate(modelData.day, modelData.current)
                    property bool isSelected: root.isSelected(modelData.day, modelData.current)
                    property bool isMarked: root.isMarked(modelData.day, modelData.current)
                    property bool cellHovered: false

                    color: isTodayCell ? root.accentGreen
                         : isSelected ? Theme.primaryContainer
                         : cellHovered ? Theme.alpha(Theme.inkSurf, 0.08)
                         : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Cuadro selector para los días marcados (doble clic).
                    border.width: isMarked ? 1.5 : 0
                    border.color: root.accentGreen

                    AppText {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: isTodayCell ? root.bgDark
                             : isSelected ? Theme.inkPrimCont
                             : (modelData.current ? root.textMain : root.textMuted)
                        font.pixelSize: 13
                        font.bold: isTodayCell || isSelected
                        opacity: modelData.current ? 1 : 0.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton

                        onEntered: dayCell.cellHovered = true
                        onExited: dayCell.cellHovered = false

                        // Clic simple: selección (sin revertir).
                        onClicked: if (modelData.current) root.selectDay(modelData.day)

                        // Doble clic: marca/desmarca y mantiene la selección.
                        onDoubleClicked: if (modelData.current) root.toggleMark(modelData.day)
                    }
                }
            }
        }
    }
}
