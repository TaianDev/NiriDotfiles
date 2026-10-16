import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../core"
import "../../services"
import "../../components"
import "../../utils"

PillBase {
    id: root
    hoverEffect: true

    readonly property string tempString: WeatherService.summary !== ""
        ? WeatherService.summary : "..."
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property var hostWindow: null

    property int activeInstance: 1
    property string currentViewState: tmEndedNotification ? "notification"
        : showSwControls ? "stopwatch"
        : showTmControls ? "timer" : "normal"

    property bool swRunning: false
    property int swElapsedMs: 0
    property bool showSwControls: false

    Timer {
        id: swTimer
        interval: 50; running: root.swRunning; repeat: true
        onTriggered: root.swElapsedMs += 50
    }

    property int tmH: 0
    property int tmM: 0
    property int tmS: 0
    property int tmTotalSecs: 0
    property bool tmActive: false
    property bool tmRunning: false
    property bool tmEndedNotification: false
    property bool showTmControls: false
    property bool timerFocused: false

    readonly property bool timerKeyMode: HubService.opened && HubService.section === 1
        && root.timerFocused && !root.tmActive

    Timer {
        id: tmTimer
        interval: 1000; running: root.tmRunning; repeat: true
        onTriggered: {
            if (root.tmTotalSecs > 0) root.tmTotalSecs--
            else { root.tmRunning = false; root.tmActive = false; root.triggerTimerEnded() }
        }
    }

    Timer {
        id: dismissNotificationTimer
        interval: 5000
        onTriggered: root.tmEndedNotification = false
    }

    function triggerTimerEnded() {
        root.showTmControls = false; root.showSwControls = false
        root.tmEndedNotification = true; dismissNotificationTimer.restart()
        if (root.swElapsedMs > 0 || root.swRunning) root.activeInstance = 1
    }

    Timer { id: autoHideSw; interval: 3500; onTriggered: root.showSwControls = false }
    Timer { id: autoHideTm; interval: 3500; onTriggered: root.showTmControls = false }

    onSwRunningChanged: {
        if (swRunning) { root.activeInstance = 1; root.showSwControls = true; root.showTmControls = false; autoHideSw.restart() }
    }
    onTmRunningChanged: {
        if (tmRunning) { root.activeInstance = 2; root.showTmControls = true; root.showSwControls = false; autoHideTm.restart() }
    }

    SystemClock { id: sysClock; precision: SystemClock.Minutes }

    content: Item {
        id: mainLayout
        height: 28

        width: currentViewState === "notification" ? notificationView.implicitWidth
            : currentViewState === "stopwatch" ? swView.implicitWidth
            : currentViewState === "timer" ? tmView.implicitWidth : normalView.implicitWidth
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }

        MouseArea {
            id: pillMa
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            enabled: root.currentViewState === "normal" || root.currentViewState === "notification"

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    HubService.toggle(1, root)
                } else {
                    if (root.tmEndedNotification) {
                        root.tmEndedNotification = false
                        if (root.swElapsedMs > 0 || root.swRunning) {
                            root.activeInstance = 1; root.showSwControls = true; root.showTmControls = false
                        } else if (root.tmActive) {
                            root.activeInstance = 2; root.showTmControls = true; root.showSwControls = false
                        }
                        return
                    }
                    if (root.activeInstance === 1 && (root.swElapsedMs > 0 || root.swRunning)) {
                        root.showSwControls = !root.showSwControls; root.showTmControls = false
                        autoHideSw.stop()
                        if (root.showSwControls) autoHideSw.restart()
                    } else if (root.activeInstance === 2 && root.tmActive) {
                        root.showTmControls = !root.showTmControls; root.showSwControls = false
                        autoHideTm.stop()
                        if (root.showTmControls) autoHideTm.restart()
                    }
                }
            }
        }

        RowLayout {
            id: normalView
            anchors.centerIn: parent
            opacity: root.currentViewState === "normal" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 8

            RowLayout {
                spacing: 6
                visible: root.swElapsedMs > 0 || root.tmActive

                Rectangle {
                    id: swDotIndicator
                    width: 8; height: 8; radius: 4; color: Theme.err
                    visible: root.swElapsedMs > 0
                    SequentialAnimation {
                        id: swDotBlinker
                        running: root.swRunning && root.currentViewState === "normal" && swDotIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) swDotIndicator.opacity = 1 }
                    }
                }

                Item {
                    id: tmIconIndicator
                    Layout.preferredWidth: 12; Layout.preferredHeight: 12
                    visible: root.tmActive
                    Image {
                        anchors.fill: parent; source: root.iconsPath + "sand-clock.svg"
                        sourceSize.width: 12; sourceSize.height: 12
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: Theme.primary }
                    }
                    SequentialAnimation {
                        id: tmIconBlinker
                        running: root.tmRunning && root.currentViewState === "normal" && tmIconIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 1; to: 0.3; duration: 600 }
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 0.3; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) tmIconIndicator.opacity = 1 }
                    }
                }
            }

            AppText {
                text: Qt.formatDateTime(sysClock.date, "HH:mm") + " \u2022 " +
                    Qt.formatDateTime(sysClock.date, "ddd, dd/MM") + " \u2022 " + root.tempString
                color: Theme.primary
                font.pixelSize: 12
                font.bold: true
            }
        }

        RowLayout {
            id: swView
            anchors.centerIn: parent
            opacity: root.currentViewState === "stopwatch" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Rectangle {
                id: swActiveDot
                width: 8; height: 8; radius: 4; color: Theme.err
                SequentialAnimation {
                    running: root.swRunning && root.currentViewState === "stopwatch"
                    loops: Animation.Infinite
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                    onRunningChanged: { if (!running) swActiveDot.opacity = 1 }
                }
            }

            AppText {
                text: TimeUtils.formatMSS(root.swElapsedMs)
                color: Theme.primary; font.pixelSize: 14; font.bold: true
            }

            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(1, 1, 1, 0.1)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + "stop.svg"; size: 12; tint: Theme.primary }
                MouseArea { anchors.fill: parent; onClicked: { if (root.currentViewState !== "stopwatch") return; root.swRunning = false; root.swElapsedMs = 0; root.showSwControls = false; if (root.tmActive) root.activeInstance = 2 } }
            }
            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(224/255, 108/255, 117/255, 0.2)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + (root.swRunning ? "pause.svg" : "play.svg"); size: 12; tint: Theme.err }
                MouseArea { anchors.fill: parent; onClicked: { if (root.currentViewState !== "stopwatch") return; root.swRunning = !root.swRunning } }
            }
        }

        RowLayout {
            id: tmView
            anchors.centerIn: parent
            opacity: root.currentViewState === "timer" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Image {
                source: root.iconsPath + "sand-clock.svg"
                Layout.preferredWidth: 14; Layout.preferredHeight: 14
                sourceSize.width: 14; sourceSize.height: 14
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: Theme.inkSurf }
            }

            AppText {
                text: TimeUtils.formatHMSSecs(root.tmTotalSecs)
                color: Theme.primary; font.pixelSize: 14; font.bold: true
            }

            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(1, 1, 1, 0.1)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + "stop.svg"; size: 12; tint: Theme.primary }
                MouseArea { anchors.fill: parent; onClicked: { if (root.currentViewState !== "timer") return; root.tmRunning = false; root.tmActive = false; root.tmTotalSecs = 0; root.showTmControls = false; if (root.swElapsedMs > 0 || root.swRunning) root.activeInstance = 1 } }
            }
            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(180/255, 219/255, 146/255, 0.2)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + (root.tmRunning ? "pause.svg" : "play.svg"); size: 12; tint: Theme.primary }
                MouseArea { anchors.fill: parent; onClicked: { if (root.currentViewState !== "timer") return; root.tmRunning = !root.tmRunning } }
            }
        }

        RowLayout {
            id: notificationView
            anchors.centerIn: parent
            opacity: root.currentViewState === "notification" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 10

            Image {
                source: root.iconsPath + "end-clock.svg"
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                sourceSize.width: 16; sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: Theme.inkSurf }
            }

            AppText { text: "Time's up!"; color: Theme.err; font.pixelSize: 14; font.bold: true }
        }

        MouseArea {
            id: swipeDetector
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true
            hoverEnabled: false

            property real startX: 0
            property bool dragDetected: false

            onPressed: mouse => { startX = mouse.x; dragDetected = false }

            onPositionChanged: mouse => {
                if (!dragDetected && (mouse.x - startX > 40)) {
                    dragDetected = true
                    let swIsActive = (root.swElapsedMs > 0 || root.swRunning)
                    if (swIsActive && root.tmActive) {
                        root.activeInstance = (root.activeInstance === 1) ? 2 : 1
                        if (root.showSwControls || root.showTmControls) {
                            root.showSwControls = (root.activeInstance === 1)
                            root.showTmControls = (root.activeInstance === 2)
                        }
                    }
                }
            }
        }
    }

    function togglePopup() {
        HubService.toggle(1, root)
    }
}
