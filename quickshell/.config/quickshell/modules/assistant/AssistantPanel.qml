pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../components"
import "../../components/shell"

PanelWindow {
    id: panel

    required property var screen

    readonly property bool open: AssistantService.panelOpen
    readonly property int panelWidth: 400
    readonly property int edgeMargin: 14
    property real barPopupTopY: 42
    readonly property int panelVerticalMargin: Math.round((barPopupTopY + edgeMargin) / 2)
    property int currentTab: 0

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: panel.panelVerticalMargin
        bottom: panel.panelVerticalMargin
        right: panel.edgeMargin
    }

    implicitWidth: panel.panelWidth

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_assistant_" + screen.name
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: open || shell.exitRunning

    onOpenChanged: shell.active = open

    onVisibleChanged: {
        if (visible) Qt.callLater(() => focusHost.forceActiveFocus())
    }

    Connections {
        target: AssistantService
        function onShowTranslatorRequested(text) {
            panel.currentTab = 1
        }
    }

    PopupEscCapture {
        active: panel.open
        popupId: PopupManager.assistantId

        PopupEnterExit {
            id: shell
            anchors.fill: parent
            active: panel.open
            fromRight: true
            panelColor: "transparent"
            borderAlpha: 0

        Item {
            id: focusHost
            anchors.fill: parent
            focus: panel.open

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Theme.surface
                border.width: 1
                border.color: Theme.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Rectangle {
                                id: assistantTab
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: panel.currentTab === 0
                                       ? Theme.alpha(Theme.primary, 0.18)
                                       : (assistantTabMa.containsMouse
                                          ? Theme.alpha(Theme.inkSurf, 0.05)
                                          : "transparent")

                                RowLayout {
                                    id: assistantTabContent
                                    anchors.centerIn: parent
                                    spacing: 6

                                    SvgIcon {
                                        source: AppPaths.iconsDir + "ai.svg"
                                        size: 16
                                        tint: panel.currentTab === 0 ? Theme.primary : Theme.inkSurfVar
                                    }

                                    Text {
                                        text: "Assistant"
                                        color: panel.currentTab === 0 ? Theme.inkSurf : Theme.inkSurfVar
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: assistantTabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.currentTab = 0
                                }
                            }

                            Rectangle {
                                id: translatorTab
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: panel.currentTab === 1
                                       ? Theme.alpha(Theme.primary, 0.18)
                                       : (translatorTabMa.containsMouse
                                          ? Theme.alpha(Theme.inkSurf, 0.05)
                                          : "transparent")

                                RowLayout {
                                    id: translatorTabContent
                                    anchors.centerIn: parent
                                    spacing: 6

                                    SvgIcon {
                                        source: AppPaths.iconsDir + "translate.svg"
                                        size: 16
                                        tint: panel.currentTab === 1 ? Theme.primary : Theme.inkSurfVar
                                    }

                                    Text {
                                        text: "Translator"
                                        color: panel.currentTab === 1 ? Theme.inkSurf : Theme.inkSurfVar
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: translatorTabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.currentTab = 1
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.outlineVariant
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Item {
                            id: carousel
                            width: parent.width * 2
                            height: parent.height
                            x: panel.currentTab === 0 ? 0 : -parent.width
                            Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

                            AssistantTab {
                                width: parent.width / 2
                                height: parent.height
                                x: 0
                            }

                            TranslatorTab {
                                width: parent.width / 2
                                height: parent.height
                                x: parent.width / 2
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
