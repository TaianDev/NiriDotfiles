import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"
import "../../services"
import "../../utils"
import "../../components"

Item {
    id: root

    property var entry: null

    readonly property bool isImage: entry?.type === "image"
    readonly property bool isText: entry?.type === "text"

    function formatBytes(n) {
        if (!n || n <= 0)
            return ""
        if (n < 1024)
            return n + " B"
        if (n < 1024 * 1024)
            return (n / 1024).toFixed(1) + " KB"
        return (n / (1024 * 1024)).toFixed(1) + " MB"
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.alpha(Theme.surfaceVariant, 0.35)
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.25)
        clip: true

        // ── Empty state ──
        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 24, 160)
            spacing: 6
            visible: root.entry === null

            SvgIcon {
                x: (parent.width - width) / 2
                source: AppPaths.iconsDir + "clipboard-attachment.svg"
                size: 26
                tint: Theme.inkSurfVar
                opacity: 0.4
            }

            AppText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No selection"
                color: Theme.inkSurfVar
                font.pixelSize: 11
                opacity: 0.6
            }
        }

        // ── Preview ──
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            visible: root.entry !== null

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                AppText {
                    Layout.fillWidth: true
                    text: root.isImage ? "Image" : "Text"
                    color: Theme.inkSurf
                    font.pixelSize: 12
                    font.bold: true
                }

                AppText {
                    Layout.fillWidth: true
                    text: root.isImage
                        ? String(root.entry?.mime ?? "")
                        : ((root.entry?.length ?? 0) + " chars")
                    color: Theme.inkSurfVar
                    font.pixelSize: 10
                    opacity: 0.65
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                AppText {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(new Date((root.entry?.ts ?? 0) * 1000), "HH:mm")
                        + (root.isImage && root.formatBytes(root.entry?.size) !== ""
                            ? " \u00b7 " + root.formatBytes(root.entry?.size) : "")
                    color: Theme.inkSurfVar
                    font.pixelSize: 10
                    opacity: 0.5
                    maximumLineCount: 1
                }
            }

            // Image preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isImage
                radius: 8
                color: Theme.alpha(Theme.surface, 0.6)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 6
                    source: root.isImage && root.entry?.file
                        ? ("file://" + root.entry.file) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    sourceSize.width: 512
                    sourceSize.height: 512
                }
            }

            // Text preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isText
                radius: 8
                color: Theme.alpha(Theme.surface, 0.6)
                clip: true

                FileView {
                    id: previewFile
                    path: root.isText && root.entry?.file ? root.entry.file : ""
                    blockLoading: true
                    printErrors: false
                    onLoaded: previewArea.text = previewFile.text()
                    onTextChanged: previewArea.text = previewFile.text()
                }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true

                    TextArea {
                        id: previewArea
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        width: parent.width
                        color: Theme.inkSurf
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        leftPadding: 0
                        topPadding: 0
                        background: Item {}
                    }
                }
            }
        }
    }
}
