import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../components"

Rectangle {
    id: root
    required property string title
    required property var points
    required property real startTime
    required property real endTime
    property bool dischargeOnly: false
    property string unit: "%"
    property real maximum: 100
    readonly property var shownPoints: root.points.filter(p => !root.dischargeOnly || p.state === 2)
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 28
    color: Colors.layer
    radius: Motion.rounding.large

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Motion.fontSize.title
        }
        Canvas {
            id: plot
            Layout.fillWidth: true
            Layout.preferredHeight: 132
            property var points: root.points
            property color lineColor: Colors.primary
            property color gridColor: Colors.outlineVariant
            property color labelColor: Colors.outline
            onPointsChanged: requestPaint()
            onLineColorChanged: requestPaint()
            onGridColorChanged: requestPaint()
            onLabelColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: root
                function onStartTimeChanged() { plot.requestPaint(); }
                function onEndTimeChanged() { plot.requestPaint(); }
                function onMaximumChanged() { plot.requestPaint(); }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const left = 43, top = 8, w = width - left - 8, h = height - 28;
                if (w <= 0 || h <= 0) return;
                ctx.font = "11px sans-serif";
                ctx.fillStyle = labelColor.toString();
                ctx.strokeStyle = gridColor.toString();
                ctx.lineWidth = 1;
                for (let i = 0; i <= 2; ++i) {
                    const y = top + h * i / 2;
                    ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(left + w, y); ctx.stroke();
                    ctx.fillText((root.maximum * (1-i/2)).toFixed(root.unit === "W" ? 1 : 0) + root.unit, 0, y + 4);
                }
                ctx.fillText(new Date(root.startTime * 1000).toLocaleString(Qt.locale(), "ddd HH:mm"), left, height - 2);
                ctx.textAlign = "right";
                ctx.fillText("Now", left+w, height-2);
                ctx.strokeStyle = lineColor.toString();
                ctx.lineWidth = 2;
                let previous = null;
                for (const point of points) {
                    if ((root.dischargeOnly && point.state !== 2) || point.state === 0) {
                        previous = null;
                        continue;
                    }
                    const x = left + (point.ts-root.startTime) / Math.max(1,root.endTime-root.startTime) * w;
                    const y = top + h * (1 - Math.min(root.maximum,Math.max(0,point.value))/root.maximum);
                    if (previous && point.ts-previous.ts <= 900) {
                        ctx.beginPath(); ctx.moveTo(previous.x,previous.y); ctx.lineTo(x,y); ctx.stroke();
                    }
                    ctx.beginPath(); ctx.arc(x,y,2,0,Math.PI*2); ctx.fillStyle = lineColor.toString(); ctx.fill();
                    previous = {ts:point.ts,x:x,y:y};
                }
            }
            StyledText {
                anchors.centerIn: parent
                visible: root.shownPoints.length === 0
                text: root.dischargeOnly ? "No battery discharge recorded in this period" : "No battery history in this period"
                color: Colors.outline
                width: parent.width - 60
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: root.dischargeOnly ? "Whole laptop · charging and gaps are excluded" : "Gaps indicate missing samples or sleep"
            color: Colors.outline
            font.pixelSize: Motion.fontSize.body
            wrapMode: Text.Wrap
        }
    }
}
