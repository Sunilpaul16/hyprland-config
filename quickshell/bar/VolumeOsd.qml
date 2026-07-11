import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Volume OSD: bar + percentage + mute state, shown briefly on the
// focused monitor when the default sink's volume/mute changes. Placement
// is centered-bottom rather than caelestia's slide-in-from-the-right-
// sidebar strip (modules/osd/Wrapper.qml) -- that placement is anchored to
// their sidebar/session layout, which this bar-only config has no
// equivalent of; centered-bottom is the natural fit for a horizontal-bar
// setup with no sidebar to dock against, and matches the common desktop
// volume-OSD convention (GNOME/KDE both do bottom-center or similar).
//
// Same per-monitor/focused-only pattern as Launcher.qml/Cheatsheet.qml, but
// with no keyboard focus at all (WlrKeyboardFocus.None) -- this is a purely
// passive indicator, nothing to type into or click.
PanelWindow {
    id: root
    property var screen

    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor

    // Only true once a real onVolumeChanged/onMutedChanged fires -- never
    // set from the initial Audio.volume/Audio.muted binding evaluation
    // itself, so nothing shows just because the window came into being.
    property bool triggered: false
    readonly property bool active: root.triggered && root.isFocusedScreen

    // Startup grace: Pipewire.defaultAudioSink resolves asynchronously
    // after the shell starts (same lesson as DesktopEntries/Hyprland.
    // toplevels elsewhere in this config) -- its `.audio.volume`/`.muted`
    // can genuinely change value once during that initial settle, which
    // would otherwise fire onVolumeChanged/onMutedChanged and pop the OSD
    // up right at startup. Real user-driven changes don't happen in the
    // first second of the shell's life, so anything reported before this
    // flag flips is startup noise, not a real change -- confirmed this
    // trap is real by testing without the guard first (see verification
    // notes).
    property bool startupGraceOver: false
    Timer {
        interval: 1000
        running: true
        onTriggered: root.startupGraceOver = true
    }

    property real showProgress: active ? 1 : 0
    Behavior on showProgress {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    anchors {
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusiveZone: 0
    implicitHeight: 120
    visible: showProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-volume-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: Audio
        function onVolumeChanged() {
            if (!root.startupGraceOver)
                return;
            root.triggered = true;
            hideTimer.restart();
        }
        function onMutedChanged() {
            if (!root.startupGraceOver)
                return;
            root.triggered = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.triggered = false
    }

    readonly property int barWidth: 160
    readonly property int barHeight: 6
    readonly property string icon: {
        if (Audio.muted || Audio.volume <= 0)
            return "\u{1F507}"; // muted speaker
        if (Audio.volume < 0.5)
            return "\u{1F508}"; // low volume speaker
        return "\u{1F50A}"; // full volume speaker
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        radius: height / 2
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        opacity: root.showProgress
        scale: 0.96 + 0.04 * root.showProgress
        transformOrigin: Item.Center

        implicitWidth: row.implicitWidth + 28
        implicitHeight: 44

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                font.pixelSize: 18
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: root.barHeight
                radius: height / 2
                color: Colors.background

                Rectangle {
                    height: parent.height
                    radius: height / 2
                    color: Audio.muted ? Colors.textMuted : Colors.primary
                    width: track.width * Math.max(0, Math.min(1, Audio.volume))

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutSine } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (Audio.muted ? "muted · " : "") + Math.round(Audio.volume * 100) + "%"
                color: Audio.muted ? Colors.textMuted : Colors.text
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
