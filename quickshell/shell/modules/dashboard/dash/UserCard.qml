import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"
import "../../../components"

// User card
Rectangle {
    id: root

    readonly property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Unknown"
    readonly property real avatarSize: Config.dashboard.user.avatarSize
    readonly property real logoBadgeSize: Config.dashboard.user.logoSize + 12
    readonly property real uptimeBadgeSize: Config.dashboard.user.uptimeSize + 8

    // Avatar path fallback
    readonly property string facePath: {
        const configured = Directories.resolve(Config.dashboard.user.avatarPath);
        if (configured.length > 0)
            return configured;
        return faceProbe.exists ? Directories.faceIcon : Directories.bongocatGif;
    }

    // Container tones
    readonly property color logoBg: Colors.tint(Colors.surface, Colors.primary, 0.30)
    readonly property color uptimeBg: Colors.tint(Colors.surface, Colors.hueShift(Colors.primary, 40), 0.30)
    readonly property color wmBg: Colors.tint(Colors.surface, Colors.hueShift(Colors.primary, -30), 0.24)

    // Hue rotate
    radius: Motion.rounding.large
    color: Colors.layer
    border.width: 1
    border.color: Colors.outline
    implicitHeight: root.avatarSize + 32

    // ~/.face probe
    FileView {
        id: faceProbe

        property bool exists: false

        path: Directories.faceIcon
        printErrors: false
        onLoaded: exists = true
        onLoadFailed: exists = false
    }

    // Distro logo badge
    Rectangle {
        id: logoBadge

        x: 16
        y: 12
        z: 1
        implicitWidth: root.logoBadgeSize
        implicitHeight: root.logoBadgeSize
        radius: width / 2
        color: root.logoBg

        StyledText {
            anchors.centerIn: parent
            text: SysInfo.osGlyph
            font.family: Fonts.glyphFamily
            font.pixelSize: Config.dashboard.user.logoSize * 0.62
            color: Colors.primary
        }
    }

    // Avatar
    Rectangle {
        id: avatar

        anchors.left: logoBadge.right
        anchors.leftMargin: -root.logoBadgeSize * 0.45
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.avatarSize
        implicitHeight: root.avatarSize
        radius: width / 2
        color: Colors.background

        MaterialIcon {
            anchors.centerIn: parent
            visible: pfp.status !== Image.Ready
            text: "person"
            font.pixelSize: root.avatarSize * 0.45
            color: Colors.textMuted
        }

        // Animated avatar
        AnimatedImage {
            id: pfp

            anchors.fill: parent
            anchors.margins: Motion.spacing.tiny
            source: root.facePath.length > 0 ? "file://" + root.facePath : ""
            fillMode: Image.PreserveAspectFit
            playing: true
            asynchronous: true
            cache: false
        }
    }

    // Uptime badge
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

        MaterialIcon {
            anchors.centerIn: parent
            text: "clock_arrow_up"
            font.pixelSize: Config.dashboard.user.uptimeSize * 0.55
            color: Colors.primary
        }
    }

    StyledText {
        anchors.left: uptimeBadge.right
        anchors.leftMargin: Motion.spacing.normal
        anchors.right: parent.right
        anchors.rightMargin: Motion.spacing.xlarge
        anchors.verticalCenter: uptimeBadge.verticalCenter
        text: SysInfo.uptimeLong
        font.pixelSize: Motion.fontSize.body
        elide: Text.ElideRight
    }

    // WM pill
    Rectangle {
        id: wmPill

        anchors.left: avatar.right
        anchors.leftMargin: 22
        anchors.top: parent.top
        anchors.topMargin: Motion.spacing.wide
        implicitWidth: Math.min(wmLabel.implicitWidth + 20, parent.width - x - 16)
        implicitHeight: wmLabel.implicitHeight + 12
        radius: Motion.rounding.normal
        color: root.wmBg

        Row {
            id: wmLabel

            anchors.centerIn: parent
            spacing: Motion.spacing.tiny

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "select_window"
                font.pixelSize: Motion.fontSize.label
                color: Colors.primary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wmName
                font.pixelSize: Motion.fontSize.body
                // Measured off config
                width: Math.min(implicitWidth, Config.dashboard.user.width - wmPill.x - 56)
                elide: Text.ElideRight
            }
        }
    }

    // Bubble tail dots
    Rectangle {
        id: bubbleLarge

        anchors.left: avatar.right
        anchors.leftMargin: Motion.spacing.normal
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
