import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import "../../core"
import "../../components"

Item {
    id: root

    signal wallpaperSelected(string path)
    signal closeRequested()

    property string currentPath: ""
    property string activeWallpaperPath: ""
    property string iconsPath: ""
    property bool embedded: false
    property string searchText: ""
    property alias folderBrowserOpen: root.fbOpen

    property bool fbOpen: false
    property var service: null

    readonly property var schemes: [
        { label: "Tonal Spot", value: "scheme-tonal-spot" },
        { label: "Vibrant", value: "scheme-vibrant" },
        { label: "Expressive", value: "scheme-expressive" },
        { label: "Content", value: "scheme-content" },
        { label: "Fidelity", value: "scheme-fidelity" },
        { label: "Fruit Salad", value: "scheme-fruit-salad" },
        { label: "Monochrome", value: "scheme-monochrome" },
        { label: "Neutral", value: "scheme-neutral" },
        { label: "Rainbow", value: "scheme-rainbow" },
        { label: "Smart", value: "scheme-smart" }
    ]
    readonly property var modeLabels: ["Dark", "Light", "Smart"]
    readonly property var modeValues: ["dark", "light", "smart"]
    readonly property var transitionLabels: ["None", "Simple", "Fade", "Left", "Right", "Top",
        "Bottom", "Wipe", "Wave", "Grow", "Center", "Any", "Outer", "Random"]
    readonly property var transitionValues: ["none", "simple", "fade", "left", "right", "top",
        "bottom", "wipe", "wave", "grow", "center", "any", "outer", "random"]

    function schemeIndex() {
        if (!root.service) return 0
        for (let i = 0; i < root.schemes.length; i++)
            if (root.schemes[i].value === root.service.scheme) return i
        return 0
    }
    function modeIndex() {
        if (!root.service) return 0
        const i = root.modeValues.indexOf(root.service.mode)
        return i < 0 ? 0 : i
    }
    function transitionIndex() {
        if (!root.service) return 0
        const i = root.transitionValues.indexOf(root.service.transition)
        return i < 0 ? 0 : i
    }
    function regen() {
        if (root.service && root.activeWallpaperPath !== "")
            root.service.apply(root.activeWallpaperPath)
        else if (root.service)
            root.service.save()
    }
    function setContrast(x) {
        if (!root.service) return
        const t = Math.max(0, Math.min(1, x / 76))
        root.service.contrast = Math.round((t * 2 - 1) * 100) / 100
    }

    onCurrentPathChanged: wallList.currentIndex = -1
    onSearchTextChanged: root.updateSearchFilter(searchText)

    function forceSearchFocus() {
        gridSearch.forceActiveFocus()
    }

    FolderListModel {
        id: wallpaperFolderModel
        folder: root.currentPath !== "" ? "file://" + root.currentPath : ""
        showDirs: false; showFiles: true; showDotAndDotDot: false
        caseSensitive: false; sortField: FolderListModel.Name
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
    }

    FolderListModel {
        id: dirFolderModel
        folder: root.currentPath !== "" ? "file://" + root.currentPath : ""
        showDirs: true; showFiles: false; showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    function updateSearchFilter(query) {
        const exts = ["jpg", "jpeg", "png", "webp", "bmp"]
        const q = query && query.length > 0 ? ("*" + query + "*") : "*"
        const filters = []
        for (let e of exts) filters.push(q + "." + e)
        wallpaperFolderModel.nameFilters = filters
        if (wallpaperFolderModel.count > 0) {
            wallList.currentIndex = 0
            wallList.positionViewAtIndex(0, ListView.Contain)
        }
    }

    function parentOf(path) {
        const idx = path.lastIndexOf('/')
        return idx > 0 ? path.substring(0, idx) : path
    }

    function navigateToDirectory(path) { root.currentPath = path }
    function selectPrevious() { moveSelection(-1) }
    function selectNext() { moveSelection(1) }

    function moveSelection(delta) {
        if (wallpaperFolderModel.count === 0) return
        let newIndex = wallList.currentIndex + delta
        if (newIndex < 0) newIndex = 0
        if (newIndex >= wallpaperFolderModel.count) newIndex = wallpaperFolderModel.count - 1
        wallList.currentIndex = newIndex
        wallList.positionViewAtIndex(newIndex, ListView.Contain)
    }

    function applySelected() {
        if (wallList.currentIndex < 0 && wallpaperFolderModel.count > 0)
            wallList.currentIndex = 0
        if (wallList.currentItem) {
            root.activeWallpaperPath = wallList.currentItem.myPath
            root.wallpaperSelected(wallList.currentItem.myPath)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            visible: root.currentPath !== "" && root.currentPath !== AppPaths.wallpapersPath
            spacing: 6

            SvgIcon {
                source: root.iconsPath + "files.svg"
                size: 12; tint: Theme.inkSurfVar
            }

            AppText {
                Layout.fillWidth: true
                text: root.currentPath.replace(AppPaths.wallpapersPath, "Wallpapers")
                color: Theme.inkSurfVar; font.pixelSize: 11; elide: Text.ElideMiddle
            }
        }

        ListView {
            id: wallList
            Layout.fillWidth: true; Layout.fillHeight: true
            orientation: ListView.Horizontal; spacing: 0
            model: wallpaperFolderModel; clip: true
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
            highlight: null

            Behavior on contentX {
                enabled: !wallList.moving && !wallList.dragging
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0)
                        root.selectPrevious()
                    else root.selectNext()
                }
            }

            delegate: Item {
                id: wallDelegate
                width: 126; height: wallList.height
                z: isSelected || itemMa.containsMouse ? 1 : 0

                property string myPath: filePath
                property string myName: fileName
                property bool isActive: myPath === root.activeWallpaperPath
                property bool isSelected: index === wallList.currentIndex

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 10; anchors.bottomMargin: 10
                    anchors.leftMargin: 5; anchors.rightMargin: 5
                    scale: (isSelected && !isActive) || (itemMa.containsMouse && !isActive) ? 1.04 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Item {
                        id: thumbFrame
                        anchors.fill: parent

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: thumbFrame.width; height: thumbFrame.height; radius: 12
                            }
                        }

                        Rectangle { anchors.fill: parent; color: "#000000" }

                        Image {
                            anchors.fill: parent
                            source: "file://" + wallDelegate.myPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(140, 520)
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Theme.alpha(Theme.colorShadow, 0.9) }
                            }
                        }

                        AppText {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 8
                            width: parent.width - 16
                            text: wallDelegate.myName
                            color: Theme.inkSurf; font.pixelSize: 11
                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        anchors.fill: parent; radius: 12; color: "transparent"
                        border.width: isActive || isSelected ? 2 : (itemMa.containsMouse ? 1 : 0)
                        border.color: isActive ? Theme.primary
                            : isSelected ? Theme.inkSurf
                            : itemMa.containsMouse ? Theme.alpha(Theme.outline, 0.6) : "transparent"
                    }

                    Rectangle {
                        visible: isActive
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.margins: 6
                        width: 44; height: 20; radius: 10; color: Theme.primary
                        AppText {
                            anchors.centerIn: parent
                            text: "Active"; color: Theme.inkPrim; font.pixelSize: 10; font.bold: true
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallList.currentIndex = index
                            root.activeWallpaperPath = wallDelegate.myPath
                            root.wallpaperSelected(wallDelegate.myPath)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6

            Item { Layout.fillWidth: true }

            // Folder selector
            Rectangle {
                Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20
                color: Theme.surfaceVariant
                border.width: 1
                border.color: root.fbOpen ? Theme.primary : Theme.outlineVariant
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "files.svg"; size: 17
                    tint: root.fbOpen ? Theme.primary : Theme.inkSurf
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.fbOpen = !root.fbOpen
                }
            }

            // Explicit path capsule
            Rectangle {
                Layout.preferredWidth: Math.min(pathText.implicitWidth + 24, 200)
                Layout.preferredHeight: 38
                radius: 19
                color: Theme.surfaceVariant
                border.width: 1
                border.color: Theme.outlineVariant

                AppText {
                    id: pathText
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentPath !== "" ? root.currentPath : "\u2014"
                    color: Theme.inkSurf
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
            }

            // Matugen scheme
            MiniComboBox {
                id: schemeCombo
                displayWidth: 124
                model: root.schemes.map(s => s.label)
                currentIndex: root.schemeIndex()
                onActivated: index => {
                    if (root.service) {
                        root.service.scheme = root.schemes[index].value
                        root.regen()
                    }
                }
            }

            // Matugen mode
            MiniComboBox {
                id: modeCombo
                displayWidth: 76
                model: root.modeLabels
                currentIndex: root.modeIndex()
                onActivated: index => {
                    if (root.service) {
                        root.service.mode = root.modeValues[index]
                        root.regen()
                    }
                }
            }

            // Matugen contrast
            RowLayout {
                spacing: 6
                AppText { text: "Contrast"; color: Theme.inkSurfVar; font.pixelSize: 10 }

                Item {
                    Layout.preferredWidth: 76
                    Layout.preferredHeight: 38

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 6; radius: 3
                        color: Theme.alpha(Theme.inkSurf, 0.15)
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: contrastHandle.x + contrastHandle.width / 2
                        height: 6; radius: 3
                        color: Theme.primary
                    }
                    Rectangle {
                        id: contrastHandle
                        x: Math.max(0, Math.min(parent.width - width,
                            (root.service ? (root.service.contrast + 1) / 2 : 0.5) * parent.width - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: Theme.primary
                        border.width: 2
                        border.color: Theme.surface
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => root.setContrast(mouse.x)
                        onPositionChanged: if (pressed) root.setContrast(mouse.x)
                        onReleased: root.regen()
                    }
                }
            }

            // awww transition (incl. Random)
            MiniComboBox {
                id: animCombo
                displayWidth: 104
                model: root.transitionLabels
                currentIndex: root.transitionIndex()
                onActivated: index => {
                    if (root.service) {
                        root.service.transition = root.transitionValues[index]
                        root.service.save()
                    }
                }
            }

            // Apply
            Rectangle {
                Layout.preferredWidth: 82; Layout.preferredHeight: 38; radius: 19
                color: Theme.primary
                AppText {
                    anchors.centerIn: parent
                    text: "Apply"; font.pixelSize: 12; font.bold: true; color: Theme.inkPrim
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.applySelected()
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    Rectangle {
        anchors.fill: parent; radius: 20
        color: Theme.alpha(Theme.colorShadow, 0.75)
        visible: root.fbOpen
        MouseArea { anchors.fill: parent; onClicked: root.fbOpen = false }

        Rectangle {
            width: 460; height: 360; anchors.centerIn: parent
            radius: 16; color: Theme.alpha(Theme.background, 0.90)
            border.width: 1; border.color: Theme.alpha(Theme.outlineVariant, 0.55)
            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    AppText {
                        Layout.fillWidth: true; text: "Browse folders"
                        color: Theme.inkSurf; font.pixelSize: 14; font.bold: true
                    }
                    AppText {
                        text: "\u2715"; color: Theme.inkSurfVar; font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fbOpen = false
                        }
                    }
                }

                AppText {
                    Layout.fillWidth: true
                    text: root.currentPath.replace(AppPaths.wallpapersPath, "Wallpapers")
                    color: Theme.inkSurfVar; font.pixelSize: 10; elide: Text.ElideMiddle
                }

                ListView {
                    id: dirList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; model: dirFolderModel; spacing: 4

                    header: Rectangle {
                        width: dirList.width
                        height: root.currentPath !== AppPaths.wallpapersPath ? 38 : 0
                        visible: root.currentPath !== AppPaths.wallpapersPath
                        radius: 8
                        color: upMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.08) : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 8
                            AppText { text: "\u2B06"; font.pixelSize: 14 }
                            AppText {
                                Layout.fillWidth: true; text: ".. (parent folder)"
                                color: Theme.inkSurf; font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            id: upMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.navigateToDirectory(root.parentOf(root.currentPath))
                        }
                    }

                    delegate: Rectangle {
                        width: dirList.width; height: 38; radius: 8
                        color: dirMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.08) : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 8
                            SvgIcon {
                                source: root.iconsPath + "files.svg"; size: 14; tint: Theme.inkSurf
                            }
                            AppText {
                                Layout.fillWidth: true; text: fileName
                                color: Theme.inkSurf; font.pixelSize: 12; elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: dirMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.navigateToDirectory(filePath)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 10
                    color: Theme.primary
                    AppText {
                        anchors.centerIn: parent
                        text: "Use this folder"; font.pixelSize: 12; font.bold: true
                        color: Theme.inkPrim
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.fbOpen = false
                    }
                }
            }
        }
    }
}
