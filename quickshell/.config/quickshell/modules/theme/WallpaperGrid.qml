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
    property alias searchText: gridSearch.text
    property alias folderBrowserOpen: root.fbOpen

    property bool fbOpen: false

    onCurrentPathChanged: wallList.currentIndex = -1

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
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            visible: root.currentPath !== "" && root.currentPath !== AppPaths.wallpapersPath
            spacing: 6

            SvgIcon {
                source: root.iconsPath + "files.svg"
                size: 12; tint: Theme.inkSurfVar
            }

            Text {
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
                width: 186; height: wallList.height
                z: isSelected || itemMa.containsMouse ? 1 : 0

                property string myPath: filePath
                property string myName: fileName
                property bool isActive: myPath === root.activeWallpaperPath
                property bool isSelected: index === wallList.currentIndex

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 16; anchors.bottomMargin: 16
                    anchors.leftMargin: 8; anchors.rightMargin: 8
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
                            sourceSize: Qt.size(200, 400)
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Theme.alpha(Theme.colorShadow, 0.9) }
                            }
                        }

                        Text {
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
                        Text {
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
            Layout.fillWidth: true; spacing: 12

            Rectangle {
                Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 12
                color: Theme.alpha(Theme.surfaceVariant, 0.6)
                border.width: 1
                border.color: root.fbOpen ? Theme.primary : Theme.alpha(Theme.outline, 0.35)
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "files.svg"; size: 18
                    tint: root.fbOpen ? Theme.primary : Theme.inkSurf
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.fbOpen = !root.fbOpen
                }
            }

            TextField {
                id: gridSearch
                Layout.fillWidth: true; Layout.preferredHeight: 44
                visible: !root.embedded
                placeholderText: "Search wallpapers..."
                font.pixelSize: 13
                background: Rectangle {
                    radius: 12; color: Theme.alpha(Theme.surfaceVariant, 0.5)
                    border.width: 1; border.color: Theme.alpha(Theme.outline, 0.3)
                }
                onTextChanged: root.updateSearchFilter(text)

                Keys.onShortcutOverride: event => {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                        event.accepted = true
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeRequested()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Left) {
                        root.selectPrevious()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.selectNext()
                        event.accepted = true
                    }
                }
                Keys.onReturnPressed: root.applySelected()
                Keys.onEnterPressed: root.applySelected()
            }

            Rectangle {
                Layout.preferredWidth: 100; Layout.preferredHeight: 44; radius: 12
                visible: !root.embedded
                color: Theme.primary
                Text {
                    anchors.centerIn: parent
                    text: "Apply"; font.pixelSize: 14; font.bold: true; color: Theme.inkPrim
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.applySelected()
                }
            }
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
                    Text {
                        Layout.fillWidth: true; text: "Browse folders"
                        color: Theme.inkSurf; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        text: "\u2715"; color: Theme.inkSurfVar; font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fbOpen = false
                        }
                    }
                }

                Text {
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
                            Text { text: "\u2B06"; font.pixelSize: 14 }
                            Text {
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
                            Text {
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
                    Text {
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
