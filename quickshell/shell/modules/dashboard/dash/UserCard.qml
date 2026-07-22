import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../../services"

// Distro name + uptime + WM/desktop + profile picture. Avatar path is
// config-driven (Config.userAvatarPath) — no in-app picker.
Rectangle {
    id: root

    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Unknown"
    readonly property string facePath: Config.userAvatarPath.length > 0 ? Config.userAvatarPath : Directories.faceIcon

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

    function applyUptime(content: string): void {
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

    // reload() is async — text() must be read from onLoaded, not right after calling reload()
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.applyUptime(text())
    }

    // Uptime doesn't need to be precise — refresh once a minute, not every second
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Avatar — source path set via Config.userAvatarPath
        Rectangle {
            id: avatar

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            implicitWidth: 56
            implicitHeight: 56
            radius: 28
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            // Fallback icon — shown until a real avatar image loads
            Text {
                anchors.centerIn: parent
                visible: pfp.status !== Image.Ready
                text: "person"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 28
                color: Colors.textMuted
            }

            // Avatar image, circle-cropped
            Rectangle {
                id: pfpClip
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                visible: pfp.status === Image.Ready
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: pfpClip.width
                        height: pfpClip.height
                        radius: pfpClip.radius
                    }
                }

                Image {
                    id: pfp
                    anchors.fill: parent
                    source: root.facePath.length > 0 ? "file://" + root.facePath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
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

        InfoRow {
            Layout.fillWidth: true
            icon: "schedule"
            text: root.uptimeStr
        }

        InfoRow {
            Layout.fillWidth: true
            icon: "select_window"
            text: root.wmName
        }
    }

    // Icon-badge + label style (caelestia's uptime/WM bubbles), plain
    // Rectangles rather than caelestia's M3Shapes clamshell/pill shapes
    component InfoRow: RowLayout {
        id: info

        required property string icon
        required property string text

        spacing: 8

        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 11
            color: Colors.background
            border.width: 1
            border.color: Colors.outline

            Text {
                anchors.centerIn: parent
                text: info.icon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: Colors.primary
            }
        }

        Text {
            Layout.fillWidth: true
            text: info.text
            color: Colors.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
