import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../core"

Row {
    id: root
    spacing: 6

    property int value: 0
    property string iconPath: ""
    property color activeColor: Theme.primary
    property string suffix: ""

    onValueChanged: canvas.requestPaint()

    Item {
        width: 22
        height: 22
        anchors.verticalCenter: parent.verticalCenter

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var radius = (width / 2) - 2;
                var centerX = width / 2;
                var centerY = height / 2;

                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                ctx.lineWidth = 2;
                ctx.strokeStyle = Theme.alpha(Theme.outline, 0.4);
                ctx.stroke();

                if (root.value > 0) {
                    ctx.beginPath();
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle + (Math.min(root.value, 100) / 100) * 2 * Math.PI;
                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = root.activeColor;
                    ctx.stroke();
                }
            }
        }

        Image {
            id: icn
            anchors.centerIn: parent
            width: 12
            height: 12
            source: root.iconPath
            sourceSize.width: 12
            sourceSize.height: 12
            fillMode: Image.PreserveAspectFit
            visible: false
        }

        ColorOverlay {
            anchors.fill: icn
            source: icn
            color: Theme.inkSurf
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value + root.suffix
        color: Theme.inkSurf
        font.pixelSize: 13
        font.bold: true
    }
}
