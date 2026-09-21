pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Side panel with a fade animation (enter and exit).
Item {
    id: root

    property real panelWidth: 0
    property bool shown: false
    property bool exitRunning: fadeOut.running

    default property alias content: inner.data

    clip: true
    width: shown || exitRunning ? Math.max(panelWidth, 1) : 0

    Item {
        id: inner
        anchors.fill: parent
        opacity: root.panelOpacity
    }

    property real panelOpacity: 0

    onShownChanged: {
        if (shown) {
            panelOpacity = 0
            fadeIn.restart()
        } else if (panelWidth > 0) {
            fadeOut.restart()
        }
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "panelOpacity"
        from: 0
        to: 1
        duration: 220
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "panelOpacity"
        from: root.panelOpacity
        to: 0
        duration: 180
        easing.type: Easing.InCubic
    }
}
