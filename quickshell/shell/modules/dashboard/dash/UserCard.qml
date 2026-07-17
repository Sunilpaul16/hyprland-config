import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../services"

// Distro name + uptime + WM/desktop. No profile picture — this repo has no
// ~/.face + FileDialog editor like caelestia's dash/User.qml — a generic
// Material "person" icon stands in instead. No M3Shapes pill/gem badges,
// plain rounded-rect chips.
Rectangle {
    id: root

    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Unknown"

    property string osName: "Unknown OS"
    property string uptimeStr: "up —"

    function formatUptime(totalSeconds: real): string {
        const days = Math.floor(totalSeconds / 86400);
        const hours = Math.floor((totalSeconds % 86400) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);

        let str = "";
        if (days > 0)
            str += `${days} day${days === 1 ? "" : "s"}`;
        if (hours > 0)
            str += `${str ? ", " : ""}${hours} hour${hours === 1 ? "" : "s"}`;
        if (minutes > 0 || !str)
            str += `${str ? ", " : ""}${minutes} minute${minutes === 1 ? "" : "s"}`;
        return "up " + str;
    }

    function refreshUptime(): void {
        uptimeFile.reload();
        const content = uptimeFile.text();
        if (!content)
            return;
        const seconds = parseFloat(content.split(" ")[0]);
        if (!isNaN(seconds))
            root.uptimeStr = root.formatUptime(seconds);
    }

    radius: 18
    color: Colors.surface
    border.width: 1
    border.color: Colors.outline
    // Content-driven height so the outer grid can size this card to its
    // own content instead of stretching it to fill leftover row height
    implicitHeight: content.implicitHeight + content.anchors.margins * 2

    // Distro name — read once, not polled
    FileView {
        id: osReleaseFile

        path: "/etc/os-release"
        onLoaded: {
            const content = text();
            const match = content.match(/^PRETTY_NAME=(.+)$/m);
            if (match)
                root.osName = match[1].replace(/"/g, "").trim();
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
    }

    // Uptime doesn't need to be precise — refresh once a minute, not every second
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshUptime()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            implicitWidth: 56
            implicitHeight: 56
            radius: 28
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            Text {
                anchors.centerIn: parent
                text: "person"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 28
                color: Colors.textMuted
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.osName
            color: Colors.text
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }

        Chip {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.uptimeStr
        }

        Chip {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.wmName
        }
    }

    component Chip: Rectangle {
        id: chip

        required property string text

        Layout.preferredHeight: chipLabel.implicitHeight + 12
        radius: 10
        color: Colors.background
        border.width: 1
        border.color: Colors.outline

        Text {
            id: chipLabel
            anchors.centerIn: parent
            width: parent.width - 16
            text: chip.text
            color: Colors.textMuted
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
