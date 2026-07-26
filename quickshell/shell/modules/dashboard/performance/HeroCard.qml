import QtQuick
import QtQuick.Layouts
import "../../sidebarRight"
import "../../../services"

// CPU/GPU hero card: usage ring + icon top-left, name beside it, temperature
// readout and bar bottom-left, usage blob bottom-right. Ported from
// caelestia's performance/HeroCard.qml.
Rectangle {
    id: root

    required property string iconName
    required property string label
    required property string subLabel
    required property color accent
    required property real usage
    required property real temperature

    radius: 26
    color: Colors.surface

    implicitWidth: 320
    implicitHeight: Math.max(tempColumn.implicitHeight + usageRing.implicitHeight + 24, blob.implicitHeight + usageCaption.implicitHeight + 12) + 32

    // Usage ring with the device icon inside
    CircularProgress {
        id: usageRing

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 16

        implicitSize: 42
        strokeWidth: 4
        spacing: 3
        value: root.usage
        fgColor: root.accent

        MaterialIcon {
            anchors.centerIn: parent
            text: root.iconName
            color: root.accent
            font.pixelSize: 18
        }
    }

    // Device name
    ColumnLayout {
        anchors.left: usageRing.right
        anchors.right: blob.left
        anchors.verticalCenter: usageRing.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 1

        Text {
            text: root.label
            color: root.accent
            font.pixelSize: 17
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: root.subLabel
            color: Colors.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    // Temperature readout + bar
    ColumnLayout {
        id: tempColumn

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 18
        width: root.width * 0.55
        spacing: 4

        RowLayout {
            spacing: 4

            MaterialIcon {
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? Colors.error : root.accent
                font.pixelSize: 16
                fill: 1
            }

            Text {
                text: isNaN(root.temperature) || root.temperature <= 0 ? "--°C" : Math.ceil(root.temperature) + "°C"
                color: Colors.text
                font.pixelSize: 13
            }
        }

        // Temperature bar, scaled 0..100°C
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: height / 2
            color: Colors.secondaryContainer

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.temperature / 100))
                height: parent.height
                radius: height / 2
                color: root.accent

                Behavior on width { NumberAnimation { duration: Motion.deliberateDuration; easing.type: Motion.deliberateEasing } }
            }
        }
    }

    UsageBlob {
        id: blob

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14

        implicitSize: 76
        value: root.usage

        Text {
            id: usageCaption
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Usage"
            color: Colors.textMuted
            font.pixelSize: 11
        }

        Text {
            anchors.centerIn: parent
            text: isNaN(root.usage) ? "..." : Math.round(root.usage * 100) + "%"
            color: root.accent
            font.pixelSize: 22
            font.bold: true
        }
    }
}
