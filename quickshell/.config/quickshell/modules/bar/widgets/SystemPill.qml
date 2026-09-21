import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../core"
import "../../../services"
import "../../../components"

PillBase {
    gradient: true
    id: root

    property int cpuUsage:  SystemMonitorService.cpuUsage
    property int ramUsage:  SystemMonitorService.ramUsage
    property int tempValue: SystemMonitorService.tempValue

    content: RowLayout {
        id: contentRow
        spacing: 16

        ResourceMeter {
            value: root.cpuUsage
            iconPath: Qt.resolvedUrl("../../../assets/icons/cpu.svg")
            activeColor: Theme.primary
            suffix: "%"
        }
        ResourceMeter {
            value: root.ramUsage
            iconPath: Qt.resolvedUrl("../../../assets/icons/ram.svg")
            activeColor: Theme.secondary
            suffix: "%"
        }
        ResourceMeter {
            value: root.tempValue
            iconPath: Qt.resolvedUrl("../../../assets/icons/temperature.svg")
            activeColor: Theme.tertiary
            suffix: "°"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["kitty", "--class", "kitty-floating-btop", "btop"])
        }
    }
}
