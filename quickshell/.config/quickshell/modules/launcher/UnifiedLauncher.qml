import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../utils"
import "../../components"
import "../../components/shell"
import "../theme"

PanelWindow {
    id: launcher
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: LauncherService.isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property int mode: LauncherService.mode
    readonly property bool isOpened: LauncherService.isOpened

    property string activeWallpaperPath: ""
    property real boxW: mode === LauncherService.modeWallpapers ? 960 : 660
    property real boxH: mode === LauncherService.modeWallpapers ? 520
        : mode === LauncherService.modeWeb ? 440 : 480

    Behavior on boxW { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on boxH { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    visible: isOpened || overlay.exitRunning

    BackgroundEffect.blurRegion: Region {
        id: blurRegion
        item: overlayBox
        radius: 28
    }

    WallpaperService { id: wallpaperService }

    onModeChanged: {
        if (mode === LauncherService.modeWallpapers)
            ensureWallpaperPath()
    }

    onIsOpenedChanged: {
        if (isOpened) {
            LauncherService.query = ""
            Qt.callLater(() => searchInput.forceActiveFocus())
        }
    }

    function ensureWallpaperPath() {
        if (wallGrid.currentPath === "" && AppPaths.homeDir !== "")
            wallGrid.currentPath = AppPaths.wallpapersPath
    }

    function handleUp() {
        if (mode === LauncherService.modeApps)
            appsView.moveSelection(-1)
        else if (mode === LauncherService.modeWeb)
            webView.moveSelection(-1)
    }

    function handleDown() {
        if (mode === LauncherService.modeApps)
            appsView.moveSelection(1)
        else if (mode === LauncherService.modeWeb)
            webView.moveSelection(1)
    }

    function handleEnter(inTerminal) {
        if (mode === LauncherService.modeApps)
            appsView.activateCurrent(inTerminal)
        else if (mode === LauncherService.modeWallpapers)
            wallGrid.applySelected()
        else
            webView.activateCurrent(inTerminal)
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() { launcher.ensureWallpaperPath() }
    }

    Connections {
        target: LauncherService
        function onQueryChanged() {
            if (launcher.mode === LauncherService.modeWallpapers)
                wallGrid.searchText = LauncherService.query
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: LauncherService.close()
    }

    OverlayEnterExit {
        id: overlay
        anchors.fill: parent
        active: launcher.isOpened

        Item {
            id: overlayBox
            anchors.centerIn: parent
            anchors.verticalCenterOffset: overlay.enterOffset
            width: launcher.boxW
            height: launcher.boxH

            Rectangle {
                anchors.fill: parent
                radius: 28
                color: Theme.alpha(Theme.background, 0.85)
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.8)
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    SearchBar {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        iconSource: AppPaths.iconsDir + (launcher.mode === LauncherService.modeWeb ? "globe.svg" : "magnifying.svg")
                        placeholderText: launcher.mode === LauncherService.modeApps
                            ? "Search applications..."
                            : launcher.mode === LauncherService.modeWallpapers
                            ? "Search wallpapers..."
                            : "Search the web with Zen..."
                        onTextChanged: LauncherService.query = text

                        Keys.onShortcutOverride: event => {
                            const wallpaperNav = (event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                                && launcher.mode === LauncherService.modeWallpapers
                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab
                                || event.key === Qt.Key_Up || event.key === Qt.Key_Down
                                || event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                || wallpaperNav)
                                event.accepted = true
                        }

                        Keys.onPressed: event => {
                            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0

                            if (event.key === Qt.Key_Tab) {
                                LauncherService.cycleMode(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Backtab) {
                                LauncherService.cycleMode(-1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                launcher.handleUp()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                launcher.handleDown()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left && launcher.mode === LauncherService.modeWallpapers) {
                                wallGrid.selectPrevious()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right && launcher.mode === LauncherService.modeWallpapers) {
                                wallGrid.selectNext()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                launcher.handleEnter(ctrl)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                LauncherService.close()
                                event.accepted = true
                            } else if (ctrl && event.key === Qt.Key_1) {
                                LauncherService.setMode(LauncherService.modeApps)
                                event.accepted = true
                            } else if (ctrl && event.key === Qt.Key_2) {
                                LauncherService.setMode(LauncherService.modeWallpapers)
                                event.accepted = true
                            } else if (ctrl && event.key === Qt.Key_3) {
                                LauncherService.setMode(LauncherService.modeWeb)
                                event.accepted = true
                            }
                        }
                    }

                    LauncherModeBar {
                        currentMode: launcher.mode
                        onModeSelected: mode => LauncherService.setMode(mode)
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        AppsView {
                            id: appsView
                            anchors.fill: parent
                            visible: launcher.mode === LauncherService.modeApps
                            query: LauncherService.query
                            onLaunched: LauncherService.close()
                        }

                        WallpaperGrid {
                            id: wallGrid
                            anchors.fill: parent
                            visible: launcher.mode === LauncherService.modeWallpapers
                            embedded: true
                            activeWallpaperPath: launcher.activeWallpaperPath
                            iconsPath: AppPaths.iconsDir
                            onWallpaperSelected: path => {
                                launcher.activeWallpaperPath = path
                                wallpaperService.apply(path)
                            }
                            onCloseRequested: LauncherService.close()
                        }

                        WebView {
                            id: webView
                            anchors.fill: parent
                            visible: launcher.mode === LauncherService.modeWeb
                            query: LauncherService.query
                            onLaunched: LauncherService.close()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: launcher.mode === LauncherService.modeApps
                            ? "Up/Down navigate \u00b7 Enter launch \u00b7 Ctrl+Enter terminal \u00b7 Tab mode \u00b7 Esc close"
                            : launcher.mode === LauncherService.modeWallpapers
                            ? "Left/Right browse \u00b7 Enter apply \u00b7 Tab mode \u00b7 Esc close"
                            : "Up/Down navigate \u00b7 Enter open in Zen \u00b7 Ctrl+Enter private \u00b7 Tab mode \u00b7 Esc close"
                        color: Theme.inkSurfVar
                        opacity: 0.5
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
