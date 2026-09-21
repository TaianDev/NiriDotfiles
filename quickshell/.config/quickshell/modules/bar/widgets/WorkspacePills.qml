import QtQuick
import Quickshell
import "../../../core"
import "../../../services"
import "../../../components"

PillBase {
    gradient: true
    id: capsule

    property string outputName: ""
    // Compatibility: in niri workspaces are derived from the output, not from
    // a fixed index range as in Hyprland.
    property string primaryMonitorName: "HDMI-A-1"

    readonly property int pillHeight: 22
    readonly property int pillVPad: (height - pillHeight) / 2

    content: Item {
        id: wsContainer
        implicitWidth: wsRow.implicitWidth
        implicitHeight: capsule.pillHeight

        Row {
            id: wsRow
            z: 1
            spacing: 6

            Repeater {
                model: NiriData.workspacesForOutput(capsule.outputName)

                Rectangle {
                    id: pill
                    required property var modelData

                    property int wsId: modelData?.id ?? -1
                    property string wsName: modelData?.name ?? ""
                    property bool isActive: modelData?.is_active ?? false
                    property bool isUrgent: modelData?.is_urgent ?? false

                    property bool isOccupied: iconsList.count > 0
                        || NiriData.windowsForWorkspace(wsId).length > 0

                    readonly property int iconSlot: 16
                    readonly property int iconSpacing: 3
                    readonly property int iconPadding: 6
                    readonly property int emptyPillWidth: 14
                    readonly property int iconsRowWidth: {
                        const n = iconsList.count
                        if (n === 0)
                            return 0
                        return n * iconSlot + Math.max(0, n - 1) * iconSpacing + iconPadding * 2
                    }

                    ListModel { id: iconsList }

                    function syncIcons() {
                        const icons = NiriData.iconsForWorkspace(wsId)
                        var i = 0
                        while (i < icons.length && i < iconsList.count) {
                            if (iconsList.get(i).iconPath !== icons[i])
                                iconsList.set(i, { iconPath: icons[i] })
                            i++
                        }
                        while (iconsList.count > icons.length)
                            iconsList.remove(iconsList.count - 1, 1)
                        while (iconsList.count < icons.length)
                            iconsList.append({ iconPath: "" })
                        for (var j = 0; j < icons.length; j++) {
                            if (iconsList.get(j).iconPath !== icons[j])
                                iconsList.set(j, { iconPath: icons[j] })
                        }
                    }

                    Connections {
                        target: NiriData
                        function onWindowsChanged() {
                            pill.syncIcons()
                        }
                    }

                    height: capsule.pillHeight
                    radius: height / 2
                    clip: isOccupied
                    width: {
                        if (isOccupied)
                            return Math.max(iconSlot + iconPadding * 2, iconsRowWidth)
                        return emptyPillWidth
                    }

                    color: {
                        if (isActive)
                            return Theme.primary
                        if (isUrgent)
                            return Theme.err
                        if (isOccupied)
                            return Theme.alpha(Theme.primary, 0.25)
                        return Theme.surfaceVariant
                    }

                    border.width: isActive ? 0 : Theme.barPillBorderWidth
                    border.color: Theme.barPillBorderColor()
                    opacity: isUrgent && !isActive ? urgentPulse.value : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: 220
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Component.onCompleted: pill.syncIcons()

                    Row {
                        anchors.centerIn: parent
                        spacing: pill.iconSpacing
                        visible: pill.isOccupied

                        Repeater {
                            model: iconsList

                            Item {
                                required property var model
                                width: pill.iconSlot
                                height: pill.iconSlot
                                implicitWidth: pill.iconSlot
                                implicitHeight: pill.iconSlot

                                Image {
                                    anchors.centerIn: parent
                                    width: pill.iconSlot
                                    height: pill.iconSlot
                                    source: model.iconPath
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: pill.iconSlot * 2
                                    sourceSize.height: pill.iconSlot * 2
                                    mipmap: true
                                    smooth: true
                                    antialiasing: true
                                    opacity: pill.isActive ? 1 : 0.92
                                }
                            }
                        }
                    }

                    QtObject {
                        id: urgentPulse
                        property real value: 1.0
                    }

                    SequentialAnimation {
                        running: pill.isUrgent && !pill.isActive
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 1.0; to: 0.45
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 0.45; to: 1.0
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        // By Id: `niri msg action focus-workspace "1"` treats
                        // the number as an index and would focus the wrong workspace.
                        onClicked: NiriData.focusWorkspaceById(pill.wsId)
                    }
                }
            }
        }

    }
}
