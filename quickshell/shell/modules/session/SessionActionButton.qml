import QtQuick
import Quickshell
import "../../services"
import "../../components"

// Session action button
Rectangle {
    id: root

    required property string icon
    required property var command
    // Warn if busy
    property bool warnIfBusy: false
    // Awaiting confirmation
    property bool armed: false

    implicitWidth: 64
    implicitHeight: 64
    radius: width / 2
    // Resting fill
    color: root.armed ? Colors.tint(Colors.layer, Colors.error, 0.4) : (hoverArea.containsMouse ? Colors.tint(Colors.layer, Colors.primary, 0.18) : Colors.layer)
    border.width: root.activeFocus ? 2 : 0
    border.color: Colors.primary

    Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }

    function activate(): void {
        if (root.warnIfBusy && !root.armed && (SessionWarnings.downloadRunning || SessionWarnings.packageManagerRunning)) {
            const reasons = [];
            if (SessionWarnings.downloadRunning)
                reasons.push("a download may still be running");
            if (SessionWarnings.packageManagerRunning)
                reasons.push("your package manager is running");
            Quickshell.execDetached(["notify-send", "-a", "quickshell", "-u", "critical", "Careful — press again to confirm", reasons.join(" and ") + "."]);
            root.armed = true;
            disarmTimer.restart();
            return;
        }
        Quickshell.execDetached(root.command);
        SessionState.open = false;
    }

    // Confirmation window
    Timer {
        id: disarmTimer
        interval: 4000
        onTriggered: root.armed = false
    }

    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: Colors.text
        font.pixelSize: 28
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}
