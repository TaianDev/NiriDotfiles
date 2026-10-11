import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../core"
import "../../services"
import "../../components"

// Avatar circular + datos tipo fastfetch (info del sistema).
Item {
    id: root

    readonly property var rows: [
        { label: "", value: SystemInfoService.user !== "" ? SystemInfoService.user : "user", strong: true },
        { label: "OS", value: SystemInfoService.distro },
        { label: "Kernel ", value: SystemInfoService.kernel },
        { label: "OS Age 󰏖", value: SystemInfoService.osAge },
        { label: "Uptime 󰅐", value: SystemInfoService.uptime },
        { label: "CPU ", value: SystemInfoService.cpu },
        { label: "GPU 󰢮", value: SystemInfoService.gpu },
        { label: "Disk 󰋊", value: SystemInfoService.diskFree !== "" ? SystemInfoService.diskFree + " free" : "" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96

            // Fondo circular (placeholder)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surfaceVariant
            }

            // Foto recortada al círculo
            Image {
                id: avatarImg
                anchors.fill: parent
                source: SystemInfoService.avatarSource
                sourceSize.width: 192
                sourceSize.height: 192
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 96; height: 96; radius: 48 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.alpha(Theme.primary, 0.5)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.rows

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8

                    AppText {
                        text: modelData.label
                        color: Theme.inkSurfVar
                        font.pixelSize: 10
                        Layout.preferredWidth: 46
                        elide: Text.ElideRight
                        visible: modelData.label !== ""
                    }

                    AppText {
                        Layout.fillWidth: true
                        text: modelData.value !== "" ? modelData.value : "—"
                        color: modelData.strong ? Theme.primary : Theme.inkSurf
                        font.pixelSize: modelData.strong ? 13 : 11
                        font.weight: modelData.strong ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        horizontalAlignment: modelData.label === "" ? Text.AlignHCenter : Text.AlignLeft
                    }
                }
            }
        }

        PrivacyModule {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
