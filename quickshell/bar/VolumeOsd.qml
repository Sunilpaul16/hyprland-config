import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Volume OSD window
PanelWindow {
    id: root
    property var screen

    // Visibility state
    readonly property bool isFocusedScreen: Hyprland.monitorFor(root.screen) === Hyprland.focusedMonitor

    property bool triggered: false
    readonly property bool active: root.triggered && root.isFocusedScreen

    property bool startupGraceOver: false
    // Startup grace period
    Timer {
        interval: 1000
        running: true
        onTriggered: root.startupGraceOver = true
    }

    property real showProgress: active ? 1 : 0
    Behavior on showProgress {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    // Positioning
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

    // Show on volume change
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

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.triggered = false
    }

    // Bar sizing + icon selection
    readonly property int barWidth: 160
    readonly property int barHeight: 6
    readonly property string icon: {
        if (Audio.muted || Audio.volume <= 0)
            return "\u{1F507}"; // muted speaker
        if (Audio.volume < 0.5)
            return "\u{1F508}"; // low volume speaker
        return "\u{1F50A}"; // full volume speaker
    }

    // OSD card
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

        // Icon + bar + percent
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                font.pixelSize: 18
            }

            // Volume bar
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
