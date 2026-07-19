import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import "../../../services"

// Network throughput: auto-scaling sparkline (down/up) + current speed row.
// Sparkline is a native QML Shape/PathPolyline off NetworkUsage's capped
// history array.
Rectangle {
    id: root

    readonly property int historyLength: NetworkUsage.historyLength

    readonly property real maxSample: {
        const dl = NetworkUsage.downloadHistory;
        const ul = NetworkUsage.uploadHistory;
        let max = 1024; // floor so a near-idle network doesn't flatten the scale oddly
        for (let i = 0; i < dl.length; i++)
            max = Math.max(max, dl[i]);
        for (let i = 0; i < ul.length; i++)
            max = Math.max(max, ul[i]);
        return max;
    }

    function buildPoints(history: list<real>, w: real, h: real): var {
        if (history.length < 2 || w <= 0 || h <= 0)
            return [];

        const points = [];
        const stepX = w / (root.historyLength - 1);
        const offset = root.historyLength - history.length;

        for (let i = 0; i < history.length; i++) {
            const x = (offset + i) * stepX;
            const y = h - (history[i] / root.maxSample) * h;
            points.push(Qt.point(x, y));
        }
        return points;
    }

    function formatSpeed(bytes: real): string {
        const fmt = NetworkUsage.formatBytes(bytes);
        return fmt.value.toFixed(1) + " " + fmt.unit;
    }

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline

    Component.onCompleted: NetworkUsage.ref()
    Component.onDestruction: NetworkUsage.unref()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Text {
            text: "Network"
            color: Colors.text
            font.pixelSize: 14
            font.bold: true
        }

        // Sparkline
        Item {
            id: sparkline

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 40

            Shape {
                anchors.fill: parent
                asynchronous: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Colors.textMuted
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: root.buildPoints(NetworkUsage.uploadHistory, sparkline.width, sparkline.height)
                    }
                }

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Colors.primary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: root.buildPoints(NetworkUsage.downloadHistory, sparkline.width, sparkline.height)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: NetworkUsage.downloadHistory.length < 2
                text: "Collecting data…"
                color: Colors.textMuted
                font.pixelSize: 11
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: "↓ " + root.formatSpeed(NetworkUsage.downloadSpeed)
                color: Colors.primary
                font.pixelSize: 12
            }

            Text {
                text: "↑ " + root.formatSpeed(NetworkUsage.uploadSpeed)
                color: Colors.textMuted
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }
        }
    }
}
