import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property LockContext context

    property string homeDir: ""
    readonly property string iconPathBase: homeDir !== ""
        ? "file://" + homeDir + "/.config/quickshell/assets/icons/"
        : ""
    property string userName: ""
    property string wallpaperPath: ""

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }
    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    property bool capsLockOn: false
    property int failedAttempts: 0
    property int lockoutRemaining: 0
    property bool lockedOut: false
    property bool attemptMade: false

    signal exitAnimationFinished()

    // ═══════════════════════════════════════════════════════════
    // WALLPAPER BACKGROUND
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Everything fades in together (wallpaper + UI)
    Item {
        id: entryRoot
        anchors.fill: parent
        opacity: 0

        Item {
            id: wallpaperLayer
            anchors.fill: parent

            Image {
                id: wallpaperImg
                anchors.fill: parent
                source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            FastBlur {
                anchors.fill: wallpaperImg
                source: wallpaperImg
                radius: 64
            }

            BubbleField {
                anchors.fill: parent
                palette: [
                    alpha(Theme.primary, 0.28),
                    alpha(Theme.secondary, 0.22),
                    alpha(Theme.tertiary, 0.18),
                    alpha(Theme.primary, 0.16),
                ]
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
            }
        }

        Process {
            id: wallpaperQuery
            command: ["awww", "query"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = this.text.trim().split('\n')
                    for (const line of lines) {
                        const idx = line.indexOf("image: ")
                        if (idx >= 0) {
                            root.wallpaperPath = line.substring(idx + 7).trim()
                            break
                        }
                    }
                }
            }
        }

        Process {
            id: userResolver
            command: ["sh", "-c", "echo -n \"$USER\""]
            stdout: StdioCollector {
                onStreamFinished: root.userName = this.text.trim()
            }
        }

        Process {
            id: capsLockChecker
            command: ["bash", "-c", "for f in /sys/class/leds/input*::capslock/brightness; do [ -f \"$f\" ] && cat \"$f\" && break; done"]
            stdout: StdioCollector {
                onStreamFinished: root.capsLockOn = this.text.trim() === "1"
            }
        }

        Timer {
            interval: 50
            repeat: true
            running: true
            onTriggered: capsLockChecker.running = true
        }

        Timer {
            id: lockoutTimer
            interval: 1000
            repeat: true
            running: false
            onTriggered: {
                root.lockoutRemaining--
                if (root.lockoutRemaining <= 0) {
                    root.lockoutRemaining = 0
                    root.lockedOut = false
                    root.failedAttempts = 0
                    running = false
                    passwordBox.focus = true
                }
            }
        }

        // ── MAIN CONTENT —──
        Item {
            id: contentArea
            anchors.fill: parent

        // ── CLOCK ──
        Text {
            id: clockText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: parent.height * 0.10
            }

            renderType: Text.NativeRendering
            font.pixelSize: 128
            font.weight: Font.Light
            color: Theme.onPrimaryContainer

            Timer {
                running: true
                repeat: true
                interval: 1000
                onTriggered: clockText.date = new Date()
            }

            text: {
                const h = clockText.date.getHours().toString().padStart(2, '0')
                const m = clockText.date.getMinutes().toString().padStart(2, '0')
                return h + ":" + m
            }
        }

        // ── DATE ──
        Text {
            id: dateText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: clockText.bottom
                topMargin: 10
            }

            renderType: Text.NativeRendering
            font.pixelSize: 32
            font.weight: Font.Normal
            color: alpha(Theme.onPrimaryContainer, 0.65)

            Timer {
                running: true
                repeat: true
                interval: 60000
                onTriggered: dateText.date = new Date()
            }

            text: {
                const d = dateText.date
                const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                const months = ["January","February","March","April","May","June","July","August",
                    "September","October","November","December"]
                return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
            }
        }

        // ── GREETING ──
        Text {
            id: greetingText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: dateText.bottom
                topMargin: 24
            }

            renderType: Text.NativeRendering
            font.pixelSize: 18
            font.weight: Font.Normal
            color: alpha(Theme.onPrimaryContainer, 0.7)

            Timer {
                running: true
                repeat: true
                interval: 60000
                onTriggered: greetingText.date = new Date()
            }

            text: {
                const h = greetingText.date.getHours()
                if (h >= 5 && h < 12) return "Good morning"
                if (h >= 12 && h < 18) return "Good afternoon"
                if (h >= 18 && h < 22) return "Good evening"
                return "Good night"
            }
        }

        // ── PASSWORD SECTION ──
        Item {
            id: passwordSection
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: greetingText.bottom
                topMargin: 32
            }
            width: passwordRow.width
            height: passwordRow.height

            Row {
                id: passwordRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                TextField {
                    id: passwordBox
                    implicitWidth: 300
                    padding: 14
                    focus: true
                    enabled: !root.context.unlockInProgress && !root.lockedOut
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    color: Theme.onBackground
                    font.pixelSize: 16

                    placeholderText: root.lockedOut ? "" : "Enter password"
                    placeholderTextColor: alpha(Theme.onBackgroundMuted, 0.42)

                    background: Rectangle {
                        radius: 16
                        color: alpha(Theme.surface, 0.55)
                        border.width: 1.5
                        border.color: root.context.showFailure
                            ? Theme.error
                            : (passwordBox.activeFocus ? Theme.primary : alpha(Theme.outline, 0.22))
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    onTextChanged: root.context.currentText = this.text
                    onAccepted: root.context.tryUnlock()

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText
                        }
                    }
                }

                Rectangle {
                    id: unlockBtn
                    width: 48
                    height: 48
                    radius: 16

                    readonly property string iconSource: {
                        if (root.context.unlockInProgress)
                            return root.iconPathBase + "unlock.svg"
                        if (root.context.currentText !== "")
                            return root.iconPathBase + "unlock.svg"
                        return root.iconPathBase + "lock.svg"
                    }

                    readonly property color activeGray: Qt.rgba(0.5, 0.5, 0.5, 1)
                    property bool successPulse: false

                    color: {
                        if (successPulse)
                            return Theme.tertiary
                        if (root.context.currentText !== "" || root.context.unlockInProgress)
                            return activeGray
                        return unlockMa.containsMouse ? Theme.primaryContainer : Theme.primary
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        id: unlockIcon
                        anchors.centerIn: parent
                        source: unlockBtn.iconSource
                        width: 22
                        height: 22
                        sourceSize.width: 22
                        sourceSize.height: 22
                        fillMode: Image.PreserveAspectFit
                        cache: true
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: Theme.onPrimary }

                        Behavior on source {
                            SequentialAnimation {
                                PropertyAnimation { target: unlockIcon; property: "scale"; to: 0.7; duration: 80 }
                                PropertyAnimation { target: unlockIcon; property: "scale"; to: 1.1; duration: 100 }
                                PropertyAnimation { target: unlockIcon; property: "scale"; to: 1.0; duration: 80 }
                            }
                        }
                    }

                    MouseArea {
                        id: unlockMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.context.currentText !== "" && !root.context.unlockInProgress
                            ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.context.currentText !== "" && !root.context.unlockInProgress)
                                root.context.tryUnlock()
                        }
                    }
                }
            }

            Text {
                id: errorText
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: passwordRow.bottom
                    topMargin: 10
                }
                opacity: root.context.showFailure ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                text: root.failedAttempts > 0
                    ? "Incorrect password (" + root.failedAttempts + "/3)"
                    : "Incorrect password"
                color: Theme.error
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Row {
                id: capsLockIndicator
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: passwordRow.bottom
                    topMargin: 10
                }
                opacity: root.capsLockOn && !root.context.showFailure && !root.lockedOut ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                spacing: 4

                Image {
                    source: root.iconPathBase + "capslock.svg"
                    width: 14
                    height: 14
                    sourceSize.width: 14
                    sourceSize.height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: "white" }
                }

                Text {
                    text: "Caps Lock is on"
                    color: "white"
                    font.pixelSize: 13
                    font.weight: Font.Normal
                }
            }

            Text {
                id: lockoutText
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: passwordRow.bottom
                    topMargin: 10
                }
                opacity: root.lockedOut ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                text: "Too many attempts — wait " + formatTime(root.lockoutRemaining)
                color: alpha(Theme.error, 0.8)
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        // ── MUSIC PLAYER ──
        LockMusicPlayer {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: passwordSection.bottom
                topMargin: 72
            }
            homeDir: root.homeDir
        }

        // ── BOTTOM-LEFT: SESSION USER ──
        UserPill {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 36
            }
            iconsPath: root.iconPathBase
            userName: root.userName
        }

        // ── BOTTOM-RIGHT: POWER MENU ──
        LockPowerMenu {
            anchors.fill: parent
            homeDir: root.homeDir
        }
    }
    }

    // ═══════════════════════════════════════════════════════════
    // ENTRY FADE
    // ═══════════════════════════════════════════════════════════
    NumberAnimation {
        id: entryFade
        target: entryRoot
        property: "opacity"
        from: 0
        to: 1
        duration: 400
        easing.type: Easing.OutCubic
    }

    Connections {
        target: context
        function onUnlocked() {
            root.failedAttempts = 0
            root.lockedOut = false
            root.lockoutRemaining = 0
            lockoutTimer.running = false
            unlockBtn.successPulse = true
            pulseReset.start()
            exitFade.start()
        }
    }

    Timer {
        id: pulseReset
        interval: 400
        onTriggered: unlockBtn.successPulse = false
    }

    // ═══════════════════════════════════════════════════════════
    // EXIT FADE
    // ═══════════════════════════════════════════════════════════
    NumberAnimation {
        id: exitFade
        target: entryRoot
        property: "opacity"
        to: 0
        duration: 500
        easing.type: Easing.InOutCubic
        onFinished: root.exitAnimationFinished()
    }

    Component.onCompleted: {
        wallpaperQuery.running = true
        userResolver.running = true
        capsLockChecker.running = true
        entryFade.start()
    }

    Connections {
        target: context
        function onShowFailureChanged() {
            if (context.showFailure) {
                root.context.clearText()
                root.failedAttempts++
                root.attemptMade = true
                if (root.failedAttempts >= 3) {
                    root.lockedOut = true
                    root.lockoutRemaining = 300
                    lockoutTimer.running = true
                }
            }
        }
    }
}
