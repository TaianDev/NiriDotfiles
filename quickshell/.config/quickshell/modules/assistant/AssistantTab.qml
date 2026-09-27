import QtQuick
import "../../core"
import "../../components"

Item {
    id: root

    AppText {
        anchors.centerIn: parent
        text: "Assistant"
        color: Theme.inkSurfVar
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }
}
