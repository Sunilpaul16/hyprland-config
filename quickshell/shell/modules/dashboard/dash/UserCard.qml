import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"

// Distro logo + avatar + uptime badge + WM pill, laid out horizontally like
// caelestia's dash/User.qml. Avatar path is config-driven (Config.userAvatarPath).
Rectangle {
    id: root

    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Unknown"
    readonly property real avatarSize: Config.dashboardAvatarSize
    readonly property real logoBadgeSize: Config.dashboardLogoSize + 12
    readonly property real uptimeBadgeSize: Config.dashboardUptimeSize + 8

    // Config path first, then ~/.face, then the bundled bongocat
    readonly property string facePath: {
        const configured = Directories.resolve(Config.userAvatarPath);
        if (configured.length > 0)
            return configured;
        return faceProbe.exists ? Directories.faceIcon : Directories.bongocatGif;
    }

    property string osId: ""
    property string uptimeStr: "up —"

    // Nerd Font distro glyphs, generic tux when the ID isn't mapped
    readonly property string osGlyph: {
        const map = {
            arch: "",
            endeavouros: "",
            manjaro: "",
            debian: "",
            ubuntu: "",
            fedora: "",
            nixos: "",
            gentoo: "",
            opensuse: ""
        };
        return map[root.osId] ?? "";
    }

    // Material Design container tones, derived from the single matugen primary
    readonly property color logoBg: Qt.tint(Colors.surface, Qt.alpha(Colors.primary, 0.30))
    readonly property color uptimeBg: Qt.tint(Colors.surface, Qt.alpha(root.hueShift(Colors.primary, 40), 0.30))
    readonly property color wmBg: Qt.tint(Colors.surface, Qt.alpha(root.hueShift(Colors.primary, -30), 0.24))

    // Rotates a colour's hue, passing achromatic colours through untouched
    function hueShift(c: color, degrees: real): color {
        if (c.hslSaturation <= 0.01)
            return c;
        return Qt.hsla((c.hslHue * 360 + degrees + 360) % 360 / 360, c.hslSaturation, c.hslLightness, c.a);
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
    implicitHeight: root.avatarSize + 32

    // Distro ID — read once, not polled
    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const match = text().match(/^ID=(.+)$/m);
            if (match)
                root.osId = match[1].replace(/"/g, "").trim().toLowerCase();
        }
    }

    // Probes whether ~/.face exists so facePath can fall through to the bongocat
    FileView {
        id: faceProbe

        property bool exists: false

        path: Directories.faceIcon
        printErrors: false
        onLoaded: exists = true
        onLoadFailed: exists = false
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

    // Distro logo badge — sits top-left, overlapped by the avatar
    Rectangle {
        id: logoBadge

        x: 16
        y: 12
        z: 1
        implicitWidth: root.logoBadgeSize
        implicitHeight: root.logoBadgeSize
        radius: width / 2
        color: root.logoBg

        Text {
            anchors.centerIn: parent
            text: root.osGlyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Config.dashboardLogoSize * 0.62
            color: Colors.primary
        }
    }

    // Avatar. Deliberately unclipped: ClippingRectangle's shader and a
    // layer/OpacityMask both render nothing inside this layershell overlay
    Rectangle {
        id: avatar

        anchors.left: logoBadge.right
        anchors.leftMargin: -root.logoBadgeSize * 0.45
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.avatarSize
        implicitHeight: root.avatarSize
        radius: width / 2
        color: Colors.background

        Text {
            anchors.centerIn: parent
            visible: pfp.status !== Image.Ready
            text: "person"
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.avatarSize * 0.45
            color: Colors.textMuted
        }

        // AnimatedImage so a .gif avatar actually plays. Fit, not Crop —
        // a wide source (the 200x126 bongocat) crops to empty centre pixels
        AnimatedImage {
            id: pfp

            anchors.fill: parent
            anchors.margins: 4
            source: root.facePath.length > 0 ? "file://" + root.facePath : ""
            fillMode: Image.PreserveAspectFit
            playing: true
            asynchronous: true
            cache: false
        }
    }

    // Uptime badge + label
    Rectangle {
        id: uptimeBadge

        anchors.left: avatar.right
        anchors.leftMargin: -root.uptimeBadgeSize * 0.5
        anchors.bottom: avatar.bottom
        z: 1
        implicitWidth: root.uptimeBadgeSize
        implicitHeight: root.uptimeBadgeSize
        radius: width / 2
        color: root.uptimeBg

        Text {
            anchors.centerIn: parent
            text: "clock_arrow_up"
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.dashboardUptimeSize * 0.55
            color: Colors.primary
        }
    }

    Text {
        anchors.left: uptimeBadge.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: uptimeBadge.verticalCenter
        text: root.uptimeStr
        color: Colors.text
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    // WM pill with its bubble tail trailing back toward the avatar
    Rectangle {
        id: wmPill

        anchors.left: avatar.right
        anchors.leftMargin: 22
        anchors.top: parent.top
        anchors.topMargin: 14
        implicitWidth: Math.min(wmLabel.implicitWidth + 20, parent.width - x - 16)
        implicitHeight: wmLabel.implicitHeight + 12
        radius: 12
        color: root.wmBg

        Row {
            id: wmLabel

            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "select_window"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: Colors.primary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wmName
                color: Colors.text
                font.pixelSize: 12
                // Measured off the configured card width, never wmPill.width —
                // that feeds wmPill.implicitWidth back through this Row and polish-loops
                width: Math.min(implicitWidth, Config.dashboardUserWidth - wmPill.x - 56)
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        id: bubbleLarge

        anchors.left: avatar.right
        anchors.leftMargin: 8
        anchors.verticalCenter: wmPill.bottom
        implicitWidth: 13
        implicitHeight: 13
        radius: width / 2
        color: root.wmBg
    }

    Rectangle {
        anchors.right: bubbleLarge.left
        anchors.rightMargin: 3
        anchors.top: bubbleLarge.bottom
        anchors.topMargin: 1
        implicitWidth: 8
        implicitHeight: 8
        radius: width / 2
        color: root.wmBg
    }
}
