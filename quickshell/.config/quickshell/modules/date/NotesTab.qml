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
    readonly property Item activeInput: titleField.activeFocus ? titleField
        : bodyArea.activeFocus ? bodyArea
        : tagField.activeFocus ? tagField
        : titleField

    property bool editorOpen: false
    property string editingId: ""
    property string targetStatus: "todo"
    property string eTitle: ""
    property string eBody: ""
    property string eImportance: "none"
    property string eDifficulty: "none"
    property var eTags: []
    property string eNewTagName: ""
    property string eNewTagColor: ""

    readonly property var tagPalette: [
        "#EF5350", "#FFA726", "#66BB6A", "#42A5F5",
        "#AB47BC", "#26A69A", "#EC407A", "#5C6BC0"
    ]

    readonly property int titleMax: 64
    readonly property int bodyMax: 800

    property var columns: [
        { key: "todo", name: "To-Do" },
        { key: "ongoing", name: "On-going" },
        { key: "done", name: "Done" }
    ]

    function statusName(status) {
        if (status === "todo") return "To-Do"
        if (status === "ongoing") return "On-going"
        if (status === "done") return "Done"
        return status
    }

    function countFor(status) {
        return NotesService.notesFor(status).length
    }

    function notesFor(status) {
        return NotesService.notesFor(status)
    }

    function canMoveLeft(status) {
        return status === "ongoing" || status === "done"
    }

    function canMoveRight(status) {
        return status === "todo" || status === "ongoing"
    }

    function impColor(level) {
        if (level === "high") return "#EF5350"
        if (level === "medium") return "#FFA726"
        if (level === "low") return "#66BB6A"
        return "transparent"
    }

    function diffColor(level) {
        if (level === "hard") return "#F06292"
        if (level === "medium") return "#AB47BC"
        if (level === "easy") return "#29B6F6"
        return "transparent"
    }

    function impLabel(level) {
        if (level === "high") return "High"
        if (level === "medium") return "Med"
        if (level === "low") return "Low"
        return ""
    }

    function diffLabel(level) {
        if (level === "hard") return "Hard"
        if (level === "medium") return "Med"
        if (level === "easy") return "Easy"
        return ""
    }

    function hasTag(name) {
        const key = String(name ?? "").trim().toLowerCase()
        for (let i = 0; i < root.eTags.length; i++)
            if (String(root.eTags[i].name ?? "").trim().toLowerCase() === key)
                return true
        return false
    }

    function cardChips(n) {
        const out = []
        const importance = n.importance ?? "none"
        const difficulty = n.difficulty ?? "none"
        if (importance !== "none")
            out.push({ label: root.impLabel(importance), color: root.impColor(importance) })
        if (difficulty !== "none")
            out.push({ label: root.diffLabel(difficulty), color: root.diffColor(difficulty) })
        const tags = n.tags ?? []
        for (let i = 0; i < tags.length; i++) {
            const t = tags[i]
            if (t && String(t.name ?? "").trim() !== "")
                out.push({ label: t.name, color: t.color })
        }
        return out
    }

    readonly property var usableExistingTags: NotesService.existingTags.filter(t => !root.hasTag(t.name))

    function formatStamp(n) {
        if (!n || !n.created) return ""
        const d = new Date(n.modified > n.created ? n.modified : n.created)
        const fmt = d.toLocaleString([], { day: "2-digit", month: "short", hour: "numeric", minute: "2-digit" })
        return (n.modified > n.created ? "Edited " : "Created ") + fmt
    }

    function openNew(status) {
        targetStatus = status
        editingId = ""
        eTitle = ""
        eBody = ""
        eImportance = "none"
        eDifficulty = "none"
        eTags = []
        eNewTagName = ""
        eNewTagColor = root.tagPalette.length > 0 ? root.tagPalette[0] : ""
        editorOpen = true
    }

    function openEdit(id) {
        const n = NotesService.findNote(id)
        if (!n) return
        editingId = id
        targetStatus = n.status ?? "todo"
        eTitle = n.title ?? ""
        eBody = n.body ?? ""
        eImportance = n.importance ?? "none"
        eDifficulty = n.difficulty ?? "none"
        eTags = (n.tags ?? []).map(t => ({ name: t.name ?? "", color: t.color ?? "#42A5F5" }))
        eNewTagName = ""
        eNewTagColor = root.tagPalette.length > 0 ? root.tagPalette[0] : ""
        editorOpen = true
    }

    function addTag() {
        const name = eNewTagName.trim()
        if (name === "" || eTags.length >= NotesService.tagMax) return
        eTags = eTags.concat([{ name: name.slice(0, 20), color: eNewTagColor }])
        eNewTagName = ""
    }

    function removeTag(name) {
        const key = String(name ?? "").trim().toLowerCase()
        if (key === "") return
        eTags = eTags.filter(t => String(t.name ?? "").trim().toLowerCase() !== key)
    }

    function addExistingTag(t) {
        if (!t || root.hasTag(t.name)) return
        if (eTags.length >= NotesService.tagMax) return
        eTags = eTags.concat([{ name: t.name, color: t.color }])
    }

    function save() {
        const title = eTitle.trim().slice(0, root.titleMax)
        const body = eBody.trim().slice(0, root.bodyMax)
        editorOpen = false
        try {
            if (editingId === "") {
                NotesService.addNote(title, body, targetStatus, eImportance, eDifficulty, eTags)
            } else {
                NotesService.updateNote(editingId, { title, body, importance: eImportance, difficulty: eDifficulty, tags: eTags.slice(0, NotesService.tagMax) })
            }
        } catch (e) {
            console.warn("NotesTab.save:", e)
        }
    }

    function focusTitle() {
        titleField.forceActiveFocus()
    }

    // ─── ESTADO 1: TABLERO ───
    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        anchors.topMargin: -4
        opacity: root.editorOpen ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Repeater {
                model: root.columns

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.alpha(Theme.surfaceVariant, 0.35)
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.5)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            AppText {
                                text: modelData.name
                                color: root.textMain
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 18
                                radius: 9
                                color: Theme.alpha(Theme.primary, 0.18)

                                AppText {
                                    anchors.centerIn: parent
                                    text: root.countFor(modelData.key)
                                    color: Theme.inkPrimCont
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 12
                                color: addArea.containsMouse ? Theme.alpha(Theme.primary, 0.28) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                AppText {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: root.textMain
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    id: addArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openNew(modelData.key)
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: colList
                                anchors.fill: parent
                                spacing: 8
                                clip: true
                                model: root.notesFor(modelData.key)

                                delegate: Rectangle {
                                    required property var modelData
                                    width: colList.width
                                    radius: 10
                                    color: cardArea.containsMouse
                                        ? Theme.alpha(Theme.primary, 0.12)
                                        : Theme.alpha(Theme.inkSurf, 0.06)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    property bool expanded: true

                                    readonly property bool hasBody: (modelData.body ?? "") !== ""

                                    height: expanded && hasBody
                                        ? 76 + bodyText.height
                                        : 72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    clip: true

                                    MouseArea {
                                        id: cardArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: expanded = !expanded
                                    }

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 8
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Item {
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 20
                                                Layout.alignment: Qt.AlignVCenter

                                                SvgIcon {
                                                    anchors.centerIn: parent
                                                    source: root.iconsPath + "down.svg"
                                                    size: 14
                                                    tint: root.textMuted
                                                    rotation: expanded ? 180 : 0
                                                    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                AppText {
                                                    Layout.fillWidth: true
                                                    text: (modelData.title ?? "") === ""
                                                        ? "(no title)"
                                                        : modelData.title
                                                    color: root.textMain
                                                    font.pixelSize: 13
                                                    elide: Text.ElideRight
                                                    font.bold: true
                                                }

                                                AppText {
                                                    Layout.fillWidth: true
                                                    text: root.formatStamp(modelData)
                                                    color: root.textMuted
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 16
                                                Layout.alignment: Qt.AlignVCenter
                                                clip: true
                                                color: "transparent"
                                                visible: root.cardChips(modelData).length > 0

                                                ListView {
                                                    anchors.fill: parent
                                                    orientation: ListView.Horizontal
                                                    spacing: 4
                                                    clip: true
                                                    interactive: true
                                                    model: root.cardChips(modelData)

                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        width: chipTx.implicitWidth + 8
                                                        height: 14
                                                        y: 1
                                                        radius: 7
                                                        clip: true
                                                        color: modelData.color

                                                        AppText {
                                                            id: chipTx
                                                            anchors.centerIn: parent
                                                            text: modelData.label
                                                            color: Theme.background
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignVCenter
                                                radius: 11
                                                color: editArea.containsMouse ? Theme.alpha(Theme.primary, 0.22) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                SvgIcon {
                                                    anchors.centerIn: parent
                                                    source: root.iconsPath + "pencil.svg"
                                                    size: 12
                                                    tint: root.textMuted
                                                }

                                                MouseArea {
                                                    id: editArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.openEdit(modelData.id)
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignVCenter
                                                radius: 11
                                                color: leftArea.containsMouse ? Theme.alpha(Theme.primary, 0.22) : "transparent"
                                                opacity: root.canMoveLeft(modelData.status) ? 1 : 0.25
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                SvgIcon {
                                                    anchors.centerIn: parent
                                                    source: root.iconsPath + "down.svg"
                                                    size: 12
                                                    tint: root.textMuted
                                                    rotation: 90
                                                }

                                                MouseArea {
                                                    id: leftArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: root.canMoveLeft(modelData.status)
                                                    onClicked: NotesService.moveNote(modelData.id, -1)
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignVCenter
                                                radius: 11
                                                color: rightArea.containsMouse ? Theme.alpha(Theme.primary, 0.22) : "transparent"
                                                opacity: root.canMoveRight(modelData.status) ? 1 : 0.25
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                SvgIcon {
                                                    anchors.centerIn: parent
                                                    source: root.iconsPath + "down.svg"
                                                    size: 12
                                                    tint: root.textMuted
                                                    rotation: -90
                                                }

                                                MouseArea {
                                                    id: rightArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: root.canMoveRight(modelData.status)
                                                    onClicked: NotesService.moveNote(modelData.id, 1)
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                Layout.alignment: Qt.AlignVCenter
                                                radius: 11
                                                color: delArea.containsMouse ? Theme.alpha(Theme.err, 0.22) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                SvgIcon {
                                                    anchors.centerIn: parent
                                                    source: root.iconsPath + "trash.svg"
                                                    size: 12
                                                    tint: delArea.containsMouse ? Theme.err : root.textMuted
                                                }

                                                MouseArea {
                                                    id: delArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: NotesService.removeNote(modelData.id)
                                                }
                                            }
                                        }

                                        AppText {
                                            id: bodyText
                                            Layout.fillWidth: true
                                            visible: expanded && hasBody
                                            opacity: expanded ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                                            text: modelData.body ?? ""
                                            color: root.textMuted
                                            font.pixelSize: 13
                                            wrapMode: Text.Wrap
                                            textFormat: Text.PlainText
                                        }
                                    }
                                }
                            }

                            Column {
                                visible: root.countFor(modelData.key) === 0
                                anchors.centerIn: parent
                                spacing: 8

                                SvgIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: root.iconsPath + "notes.svg"
                                    size: 32
                                    tint: Theme.alpha(Theme.inkSurfVar, 0.5)
                                }

                                AppText {
                                    text: "Empty"
                                    color: root.textMuted
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppText {
                    Layout.fillWidth: true
                    text: editingId === ""
                        ? "New note · " + root.statusName(targetStatus)
                        : "Edit note · " + root.statusName(targetStatus)
                    color: root.textMain
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: closeArea.containsMouse ? Theme.alpha(Theme.inkSurf, 0.15) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    AppText {
                        anchors.centerIn: parent
                        text: "✕"
                        color: root.textMuted
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editorOpen = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    TextField {
                        id: titleField
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        placeholderText: "Title"
                        color: root.textMain
                        placeholderTextColor: root.textMuted
                        font.pixelSize: 14
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.inkPrim
                        activeFocusOnPress: true
                        selectByMouse: true
                        maximumLength: root.titleMax
                        text: root.eTitle

                        onTextChanged: {
                            if (text !== root.eTitle)
                                root.eTitle = text
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.alpha(Theme.inkSurf, 0.08)
                            border.width: 1
                            border.color: Theme.alpha(Theme.primary,
                                titleField.activeFocus ? 0.8 : 0.25)
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: Theme.alpha(Theme.inkSurf, 0.08)
                        border.width: 1
                        border.color: bodyArea.activeFocus ? Theme.alpha(Theme.primary, 0.6) : Theme.alpha(Theme.outlineVariant, 0.5)
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        ScrollView {
                            id: bodyScroll
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true

                            TextArea {
                                id: bodyArea
                                placeholderText: "Details (optional)"
                                color: root.textMain
                                placeholderTextColor: root.textMuted
                                font.pixelSize: 13
                                wrapMode: TextArea.Wrap
                                activeFocusOnPress: true
                                selectByMouse: true
                                text: root.eBody
                                background: null

                                onTextChanged: {
                                    if (text !== root.eBody)
                                        root.eBody = text
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 230
                    Layout.fillHeight: true
                    radius: 10
                    color: Theme.alpha(Theme.inkSurf, 0.06)
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        AppText {
                            Layout.fillWidth: true
                            text: "Importance"
                            color: root.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: ["low", "medium", "high"]

                                Rectangle {
                                    required property string modelData
                                    width: 46
                                    height: 20
                                    radius: 10
                                    color: root.eImportance === modelData
                                        ? root.impColor(modelData)
                                        : Theme.alpha(Theme.inkSurf, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    AppText {
                                        anchors.centerIn: parent
                                        text: root.impLabel(modelData)
                                        color: root.eImportance === modelData ? Theme.background : root.textMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.eImportance = modelData
                                    }
                                }
                            }

                            Rectangle {
                                width: 44
                                height: 20
                                radius: 10
                                color: root.eImportance === "none"
                                    ? Theme.alpha(Theme.inkSurf, 0.18)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                AppText {
                                    anchors.centerIn: parent
                                    text: "None"
                                    color: root.eImportance === "none" ? root.textMain : root.textMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eImportance = "none"
                                }
                            }
                        }

                        AppText {
                            Layout.fillWidth: true
                            text: "Difficulty"
                            color: root.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: ["easy", "medium", "hard"]

                                Rectangle {
                                    required property string modelData
                                    width: 46
                                    height: 20
                                    radius: 10
                                    color: root.eDifficulty === modelData
                                        ? root.diffColor(modelData)
                                        : Theme.alpha(Theme.inkSurf, 0.08)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    AppText {
                                        anchors.centerIn: parent
                                        text: root.diffLabel(modelData)
                                        color: root.eDifficulty === modelData ? Theme.background : root.textMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.eDifficulty = modelData
                                    }
                                }
                            }

                            Rectangle {
                                width: 44
                                height: 20
                                radius: 10
                                color: root.eDifficulty === "none"
                                    ? Theme.alpha(Theme.inkSurf, 0.18)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                AppText {
                                    anchors.centerIn: parent
                                    text: "None"
                                    color: root.eDifficulty === "none" ? root.textMain : root.textMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eDifficulty = "none"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.alpha(Theme.outlineVariant, 0.5)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            AppText {
                                Layout.fillWidth: true
                                text: "Tags"
                                color: root.textMuted
                                font.pixelSize: 11
                                font.bold: true
                            }

                            AppText {
                                text: eTags.length + "/" + NotesService.tagMax
                                color: root.textMuted
                                font.pixelSize: 10
                            }
                        }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 24
                                                Layout.alignment: Qt.AlignVCenter
                                                clip: true
                                                color: "transparent"
                                                visible: root.eTags.length > 0

                                                ListView {
                                                    anchors.fill: parent
                                                    orientation: ListView.Horizontal
                                                    spacing: 4
                                                    clip: true
                                                    interactive: true
                                model: root.eTags

                                delegate: Rectangle {
                                    required property var modelData
                                    width: chipRow.implicitWidth + 14
                                    height: 22
                                    y: 1
                                    radius: 11
                                    color: modelData.color

                                    RowLayout {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        AppText {
                                            text: modelData.name
                                            color: Theme.background
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        Item {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14

                                            AppText {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                color: Theme.background
                                                font.pixelSize: 10
                                                font.bold: true
                                            }

                                            MouseArea {
                                                id: chipCloseArea2
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.removeTag(modelData.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            TextField {
                                id: tagField
                                font.family: Theme.fontFamily
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                placeholderText: "New tag"
                                color: root.textMain
                                placeholderTextColor: root.textMuted
                                font.pixelSize: 11
                                selectionColor: Theme.primary
                                selectedTextColor: Theme.inkPrim
                                activeFocusOnPress: true
                                selectByMouse: true
                                maximumLength: 20
                                text: root.eNewTagName
                                enabled: root.eTags.length < NotesService.tagMax

                                onTextChanged: {
                                    if (text !== root.eNewTagName)
                                        root.eNewTagName = text
                                }

                                onAccepted: root.addTag()

                                background: Rectangle {
                                    radius: 15
                                    color: Theme.alpha(Theme.inkSurf, 0.08)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.primary,
                                        tagField.activeFocus ? 0.8 : 0.25)
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                }
                            }

                            Rectangle {
                                width: 48
                                height: 30
                                radius: 15
                                color: addAreaX2.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                                opacity: root.eTags.length >= NotesService.tagMax ? 0.4 : 1
                                Behavior on color { ColorAnimation { duration: 120 } }

                                AppText {
                                    anchors.centerIn: parent
                                    text: "Add"
                                    color: Theme.inkPrim
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                            MouseArea {
                                                id: addAreaX2
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.addTag()
                                            }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: root.tagPalette

                                Rectangle {
                                    required property string modelData
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: modelData
                                    border.width: root.eNewTagColor === modelData ? 3 : 1
                                    border.color: root.eNewTagColor === modelData
                                        ? Qt.lighter(modelData, 2.5)
                                        : Theme.alpha(Theme.inkSurf, 0.6)
                                    Behavior on border.width { NumberAnimation { duration: 80 } }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.eNewTagColor = modelData
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.alpha(Theme.outlineVariant, 0.5)
                            visible: root.usableExistingTags.length > 0
                        }

                        AppText {
                            Layout.fillWidth: true
                            text: "Used"
                            color: root.textMuted
                            font.pixelSize: 11
                            font.bold: true
                            visible: root.usableExistingTags.length > 0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            clip: true
                            color: "transparent"
                            visible: root.usableExistingTags.length > 0

                            ListView {
                                anchors.fill: parent
                                orientation: ListView.Horizontal
                                spacing: 6
                                clip: true
                                interactive: true
                                model: root.usableExistingTags

                                delegate: Rectangle {
                                    required property var modelData
                                    width: usedTxt.implicitWidth + 12
                                    height: 22
                                    y: 1
                                    radius: 11
                                    color: modelData.color

                                    AppText {
                                        id: usedTxt
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: Theme.background
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.addExistingTag(modelData)
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
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
