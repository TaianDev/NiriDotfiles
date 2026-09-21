pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    signal translationReady()

    readonly property var engines: [
        { code: "auto", name: "Auto" },
        { code: "google", name: "Google" },
        { code: "bing", name: "Bing" },
        { code: "yandex", name: "Yandex" },
        { code: "apertium", name: "Apertium" },
        { code: "aspell", name: "Aspell" },
        { code: "hunspell", name: "Hunspell" },
        { code: "spell", name: "Spell" }
    ]

    readonly property var languages: [
        { code: "auto", name: "Detect language" },
        { code: "en", name: "English" },
        { code: "es", name: "Spanish" },
        { code: "fr", name: "French" },
        { code: "de", name: "German" },
        { code: "pt", name: "Portuguese" },
        { code: "it", name: "Italian" },
        { code: "ja", name: "Japanese" },
        { code: "ko", name: "Korean" },
        { code: "zh-CN", name: "Chinese (Simplified)" },
        { code: "zh-TW", name: "Chinese (Traditional)" },
        { code: "ru", name: "Russian" },
        { code: "ar", name: "Arabic" },
        { code: "hi", name: "Hindi" },
        { code: "nl", name: "Dutch" },
        { code: "pl", name: "Polish" },
        { code: "tr", name: "Turkish" },
        { code: "uk", name: "Ukrainian" },
        { code: "el", name: "Greek" },
        { code: "sv", name: "Swedish" },
        { code: "da", name: "Danish" },
        { code: "fi", name: "Finnish" },
        { code: "no", name: "Norwegian" },
        { code: "cs", name: "Czech" },
        { code: "id", name: "Indonesian" },
        { code: "vi", name: "Vietnamese" },
        { code: "th", name: "Thai" },
        { code: "he", name: "Hebrew" },
        { code: "bg", name: "Bulgarian" },
        { code: "ro", name: "Romanian" },
        { code: "hu", name: "Hungarian" },
        { code: "ca", name: "Catalan" }
    ]

    property string engine: "google"
    property string sourceLang: "auto"
    property string targetLang: "en"
    property string input: ""
    property string output: ""
    property string error: ""
    property bool busy: false

    property bool pending: false
    property var pendingArgs: null

    function translate() {
        const text = root.input.trim()
        if (text === "") {
            root.output = ""
            root.error = ""
            return
        }

        const args = {
            text: text,
            source: root.sourceLang,
            target: root.targetLang,
            engine: root.engine
        }

        if (root.busy) {
            root.pending = true
            root.pendingArgs = args
            return
        }

        root._start(args)
    }

    function _start(args) {
        root.busy = true
        root.error = ""
        root.output = ""
        transProc.input = args.text
        transProc.langArg = args.source === "auto" ? ":" + args.target : args.source + ":" + args.target
        transProc.engineArg = args.engine
        transProc.running = false
        transProc.running = true
    }

    function _finish() {
        root.busy = false
        if (root.pending && root.pendingArgs) {
            const args = root.pendingArgs
            root.pending = false
            root.pendingArgs = null
            root._start(args)
        }
    }

    Process {
        id: transProc
        property string input: ""
        property string langArg: ""
        property string engineArg: ""

        command: ["trans", "-brief", "-no-ansi", "-e", engineArg, langArg, input]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const text = this.text.trim()
                if (text !== "") root.output = text
            }
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const text = this.text.trim()
                if (text !== "") root.error = text
            }
        }

        onExited: (code) => {
            if (code !== 0 && root.error === "")
                root.error = "Translation failed"
            root._finish()
        }
    }
}
