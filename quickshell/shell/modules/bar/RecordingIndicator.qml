import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"

// Recording indicator widget
Item {
    id: root

    property bool recording: false
    property real recordingStartedAt: 0
    property int elapsedSeconds: 0

    visible: recording
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    // Poll + tick
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;
            if (root.recording)
                root.elapsedSeconds = Math.floor((Date.now() - root.recordingStartedAt) / 1000);
        }
    }

    // Poll for wf-recorder
    Process {
        id: pollProc
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: exitCode => {
            const nowRecording = exitCode === 0;
            if (nowRecording && !root.recording)
                root.recordingStartedAt = Date.now();
            root.recording = nowRecording;
            if (!nowRecording)
                root.elapsedSeconds = 0;
        }
    }

    // Dot + timer label
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Blinking dot
        Rectangle {
            id: dot
            Layout.alignment: Qt.AlignVCenter
            width: 10
            height: 10
            radius: 5
            color: "#e64553"

            SequentialAnimation on opacity {
                running: root.recording
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.3; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.3; to: 1; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: {
                const m = Math.floor(root.elapsedSeconds / 60);
                const s = root.elapsedSeconds % 60;
                return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
            }
            color: Colors.text
            font.pixelSize: 12
        }
    }

    // Click to stop recording
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/record", "stop"])
    }
}
