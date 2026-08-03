import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import "../../../components"
import "../../../services"

// Network card
Rectangle {
    id: root

    readonly property int historyLength: NetworkUsage.historyLength

    readonly property real maxSample: {
        const dl = NetworkUsage.downloadHistory;
        const ul = NetworkUsage.uploadHistory;
        let max = 1024;  // scale floor
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

    // Session totals
    function formatTotal(bytes: real): string {
        const fmt = NetworkUsage.formatBytes(bytes);
        return fmt.value.toFixed(1) + fmt.unit.replace("/s", "");
    }

    radius: Motion.rounding.hero
    color: Colors.layer

    implicitWidth: 290
    implicitHeight: 215

    Component.onCompleted: NetworkUsage.ref()
    Component.onDestruction: NetworkUsage.unref()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        RowLayout {
            spacing: Motion.spacing.small

            MaterialIcon {
                text: "swap_vert"
                color: Colors.primary
                font.pixelSize: Motion.fontSize.header
            }

            StyledText {
                text: "Network"
                font.pixelSize: Motion.fontSize.title
                font.bold: true
            }
        }

        // Sparkline
        Item {
            id: sparkline

            Layout.topMargin: Motion.spacing.medium
            Layout.bottomMargin: Motion.spacing.normal
            Layout.fillWidth: true
            Layout.fillHeight: true

            Shape {
                anchors.fill: parent
                asynchronous: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Colors.secondary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: root.buildPoints(NetworkUsage.uploadHistory, sparkline.width, sparkline.height)
                    }
                }

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Colors.tertiary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: root.buildPoints(NetworkUsage.downloadHistory, sparkline.width, sparkline.height)
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: NetworkUsage.downloadHistory.length < 2
                text: "Collecting data..."
                color: Colors.outline
                font.pixelSize: Motion.fontSize.body
            }
        }

        StatRow {
            iconName: "download"
            iconColor: Colors.tertiary
            label: "Download"
            value: root.formatSpeed(NetworkUsage.downloadSpeed)
            valueColor: Colors.tertiary
        }

        StatRow {
            iconName: "upload"
            iconColor: Colors.secondary
            label: "Upload"
            value: root.formatSpeed(NetworkUsage.uploadSpeed)
            valueColor: Colors.secondary
        }

        StatRow {
            iconName: "history"
            iconColor: Colors.textMuted
            label: "Total"
            value: "↓" + root.formatTotal(NetworkUsage.downloadTotal) + " ↑" + root.formatTotal(NetworkUsage.uploadTotal)
            valueColor: Colors.textMuted
        }
    }

    // Stat row
    component StatRow: RowLayout {
        id: statRow

        required property string iconName
        required property color iconColor
        required property string label
        required property string value
        required property color valueColor

        Layout.fillWidth: true
        spacing: Motion.spacing.small

        MaterialIcon {
            text: statRow.iconName
            color: statRow.iconColor
            font.pixelSize: Motion.fontSize.large
        }

        StyledText {
            text: statRow.label
            color: Colors.textMuted
            font.pixelSize: Motion.fontSize.body
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: statRow.value
            color: statRow.valueColor
            font.pixelSize: Motion.fontSize.body
        }
    }
}
