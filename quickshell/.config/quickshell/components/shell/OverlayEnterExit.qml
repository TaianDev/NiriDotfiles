import QtQuick

Item {
    id: root

    property bool active: false
    property real slideDistance: 16
    property real enterOpacity: 1
    property real enterOffset: 0

    readonly property bool exitRunning: exitAnim.running

    default property alias content: contentHost.data

    anchors.fill: parent

    Item {
        id: contentHost
        anchors.fill: parent
        opacity: root.enterOpacity
    }

    onActiveChanged: {
        if (active)
            enterAnim.restart()
        else
            exitAnim.restart()
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: root; property: "enterOpacity"
            from: 0; to: 1
            duration: 180; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "enterOffset"
            from: root.slideDistance; to: 0
            duration: 220; easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: root; property: "enterOpacity"
            from: 1; to: 0
            duration: 140; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root; property: "enterOffset"
            from: 0; to: root.slideDistance
            duration: 140; easing.type: Easing.InCubic
        }
        onStopped: root.exitFinished()
    }

    signal exitFinished()
}
