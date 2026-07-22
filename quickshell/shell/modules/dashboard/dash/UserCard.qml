import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../../services"

// Distro name + uptime + WM/desktop + profile picture. Picker is a stock
// QtQuick.Dialogs FileDialog — no portal round-trip, no C++ needed.
Rectangle {
    id: root

    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Unknown"
    readonly property string facePath: Directories.faceIcon

    property string osName: "Unknown OS"
    property string uptimeStr: "up —"
    // Bumped on every successful copy to cache-bust the avatar Image, which
    // otherwise wouldn't notice the file at the same path changed underneath it
    property int faceGeneration: 0

    function urlToPath(url): string {
        const s = url.toString();
        return s.startsWith("file://") ? decodeURIComponent(s.slice(7)) : s;
    }

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

    // Profile picture picker
    FileDialog {
        id: facePicker
        title: "Select a profile picture"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: copyProc.exec(["cp", root.urlToPath(selectedFile), root.facePath])
    }

    // Copies the picked file to ~/.face
    Process {
        id: copyProc
        onExited: exitCode => {
            if (exitCode === 0) {
                root.faceGeneration++;
                Quickshell.execDetached(["notify-send", "-a", "quickshell", "Profile picture updated", "The User card now shows your new picture."]);
            } else {
                Quickshell.execDetached(["notify-send", "-a", "quickshell", "-u", "critical", "Failed to update profile picture", "Could not copy the selected file to ~/.face."]);
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Avatar (click to pick a new ~/.face picture)
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

            // Fallback icon — shown until a real ~/.face loads
            Text {
                anchors.centerIn: parent
                visible: pfp.status !== Image.Ready
                text: "person"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 28
                color: Colors.textMuted
            }

            // ~/.face, circle-cropped
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
                    source: "file://" + root.facePath + "?" + root.faceGeneration
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            // Hover scrim + edit affordance (fade idiom matches this shell's
            // existing hover conventions — see IconAction.qml/TogglePill.qml)
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.background
                opacity: avatarHover.containsMouse ? 0.75 : 0

                Behavior on opacity { NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

                Text {
                    anchors.centerIn: parent
                    text: "photo_camera"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: Colors.text
                    opacity: parent.opacity
                }
            }

            MouseArea {
                id: avatarHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: facePicker.open()
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
