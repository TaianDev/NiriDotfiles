import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../core"
import "../../services"
import "../../components"

Item {
    id: root

    readonly property var sourceEntries: TranslationService.languages
    readonly property var targetEntries: {
        const list = []
        for (let i = 0; i < TranslationService.languages.length; i++) {
            if (TranslationService.languages[i].code !== "auto")
                list.push(TranslationService.languages[i])
        }
        return list
    }

    function closeDropdowns() {
        sourceDrop.open = false
        targetDrop.open = false
        engineDrop.open = false
    }

    Connections {
        target: sourceDrop
        function onOpened() {
            targetDrop.open = false
            engineDrop.open = false
        }
    }

    Connections {
        target: targetDrop
        function onOpened() {
            sourceDrop.open = false
            engineDrop.open = false
        }
    }

    Connections {
        target: engineDrop
        function onOpened() {
            sourceDrop.open = false
            targetDrop.open = false
        }
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: TranslationService.translate()
    }

    function onSourceSelected(code, name) {
        if (code === TranslationService.targetLang) {
            TranslationService.targetLang = TranslationService.sourceLang
        }
        TranslationService.sourceLang = code
        TranslationService.translate()
    }

    function onTargetSelected(code, name) {
        if (code === TranslationService.sourceLang) {
            TranslationService.sourceLang = TranslationService.targetLang
        }
        TranslationService.targetLang = code
        TranslationService.translate()
    }

    function onEngineSelected(code, name) {
        TranslationService.engine = code
        TranslationService.translate()
    }

    function swapLanguages() {
        const s = TranslationService.sourceLang
        TranslationService.sourceLang = TranslationService.targetLang
        TranslationService.targetLang = s === "auto" ? "en" : s
        TranslationService.translate()
    }

    function cleanInput() {
        TranslationService.input = ""
        TranslationService.translate()
        root.showToast(AppPaths.iconsDir + "trash.svg", "Input cleared")
    }

    function pasteClip() {
        const text = Quickshell.clipboardText
        if (text === "") {
            root.showToast(AppPaths.iconsDir + "clipboard-arrowdown.svg", "Clipboard is empty")
            return
        }
        TranslationService.input = text
        debounce.restart()
        root.showToast(AppPaths.iconsDir + "clipboard-arrowdown.svg", "Pasted from clipboard")
    }

    function copyClip() {
        const text = TranslationService.output
        if (text === "") {
            root.showToast(AppPaths.iconsDir + "clipboard-attachment.svg", "Nothing to copy")
            return
        }
        Quickshell.clipboardText = text
        root.showToast(AppPaths.iconsDir + "clipboard-attachment.svg", "Copied to clipboard")
    }

    function showToast(iconSource, text) {
        toastIcon.source = iconSource
        toastLabel.text = text
        if (toastFade.running) toastFade.stop()
        toastFade.restart()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            spacing: 8
            z: sourceDrop.open || targetDrop.open ? 100 : 0

            LanguageDropdown {
                id: sourceDrop
                Layout.fillWidth: true
                capsule: true
                currentCode: TranslationService.sourceLang
                entries: root.sourceEntries
                onSelected: (code, name) => root.onSourceSelected(code, name)
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                scale: swapMa.pressed ? 0.88 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                color: swapMa.containsMouse
                       ? Theme.alpha(Theme.outlineVariant, 0.85)
                       : Theme.alpha(Theme.surfaceVariant, 0.6)
                Behavior on color { ColorAnimation { duration: 150 } }

                AppText {
                    anchors.centerIn: parent
                    text: "⇄"
                    color: swapMa.containsMouse ? Theme.inkSurf : Theme.inkSurfVar
                    font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: swapMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.swapLanguages()
                }
            }

            LanguageDropdown {
                id: targetDrop
                Layout.fillWidth: true
                capsule: true
                currentCode: TranslationService.targetLang
                entries: root.targetEntries
                onSelected: (code, name) => root.onTargetSelected(code, name)
            }
        }

        RowLayout {
            spacing: 6
            z: engineDrop.open ? 100 : 0

            Item { Layout.fillWidth: true }

            IconButton {
                iconSource: AppPaths.iconsDir + "trash.svg"
                onClicked: root.cleanInput()
            }

            IconButton {
                iconSource: AppPaths.iconsDir + "clipboard-arrowdown.svg"
                onClicked: root.pasteClip()
            }

            Rectangle {
                id: engineCapsuleRect
                Layout.preferredHeight: 32
                Layout.preferredWidth: engineCapsule.implicitWidth + 24
                radius: 8
                color: Theme.alpha(Theme.secondaryContainer, 0.55)

                RowLayout {
                    id: engineCapsule
                    anchors.centerIn: parent
                    spacing: 8

                    AppText {
                        text: "Engine"
                        color: Theme.secondary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    AppText {
                        text: "|"
                        color: Theme.alpha(Theme.secondary, 0.6)
                        font.pixelSize: 14
                    }

                    LanguageDropdown {
                        id: engineDrop
                        capsule: false
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 28
                        currentCode: TranslationService.engine
                        entries: TranslationService.engines
                        onSelected: (code, name) => root.onEngineSelected(code, name)
                    }
                }
            }

            SequentialAnimation {
                running: TranslationService.busy && !engineDrop.open
                loops: Animation.Infinite
                NumberAnimation {
                    target: engineCapsuleRect
                    property: "scale"
                    from: 1.0
                    to: 0.94
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: engineCapsuleRect
                    property: "scale"
                    from: 0.94
                    to: 1.0
                    duration: 300
                    easing.type: Easing.InCubic
                }
            }

            IconButton {
                iconSource: AppPaths.iconsDir + "clipboard-attachment.svg"
                onClicked: root.copyClip()
            }

            IconButton {
                iconSource: AppPaths.iconsDir + "screenshot.svg"
                onClicked: root.showToast(AppPaths.iconsDir + "screenshot.svg", "Image translation coming soon")
            }

            Item { Layout.fillWidth: true }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 140
            Layout.minimumHeight: 90

            TextBox {
                id: inputBox
                anchors.fill: parent
                placeholderText: "Type to translate…"
                text: TranslationService.input
                borderColor: inputBox.focused ? Theme.primary : Theme.alpha(Theme.outline, 0.35)

                onTextEdited: (t) => {
                    TranslationService.input = t
                    debounce.restart()
                }

                onFocusStateChanged: (focused) => {
                    if (focused) root.closeDropdowns()
                }
            }

            Rectangle {
                id: toast
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                width: toastContent.implicitWidth + 16
                height: 28
                radius: 14
                color: Theme.primary
                z: 20
                opacity: 0

                RowLayout {
                    id: toastContent
                    anchors.centerIn: parent
                    spacing: 6

                    SvgIcon {
                        id: toastIcon
                        size: 14
                        tint: Theme.inkPrim
                    }

                    AppText {
                        id: toastLabel
                        color: Theme.inkPrim
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }
            }

            SequentialAnimation {
                id: toastFade
                NumberAnimation {
                    target: toast
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 150
                    easing.type: Easing.OutCubic
                }
                PauseAnimation { duration: 1400 }
                NumberAnimation {
                    target: toast
                    property: "opacity"
                    to: 0
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 140
            Layout.minimumHeight: 90

            TextBox {
                id: outputBox
                anchors.fill: parent
                readOnly: true
                placeholderText: "Translation will appear here"
                text: TranslationService.error !== ""
                      ? TranslationService.error
                      : TranslationService.output
                textColor: TranslationService.error !== "" ? Theme.err : Theme.inkSurf

                layer.enabled: TranslationService.busy
                layer.effect: FastBlur {
                    radius: 32
                }

                onFocusStateChanged: (focused) => {
                    if (focused) root.closeDropdowns()
                }
            }

            Item {
                anchors.fill: parent
                visible: TranslationService.busy
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                z: 10

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    SvgIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: AppPaths.iconsDir + "refresh.svg"
                        size: 26
                        tint: Theme.primary
                        RotationAnimation on rotation {
                            running: TranslationService.busy
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    AppText {
                        text: "Translating…"
                        color: Theme.primary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
