import QtQuick
import "../../services"

// Session actions column
Column {
    id: root

    spacing: Motion.spacing.xlarge

    // Focus first button
    function focusFirst(): void {
        logoutBtn.forceActiveFocus();
    }

    SessionActionButton {
        id: logoutBtn
        icon: "logout"
        command: Session.logoutCommand
        warnIfBusy: true
        KeyNavigation.down: poweroffBtn
    }

    SessionActionButton {
        id: poweroffBtn
        icon: "power_settings_new"
        command: Session.poweroffCommand
        warnIfBusy: true
        KeyNavigation.up: logoutBtn
        KeyNavigation.down: lockBtn
    }

    // Bongocat slot
    Item {
        implicitWidth: 64
        implicitHeight: 64

        AnimatedImage {
            anchors.centerIn: parent
            source: Qt.resolvedUrl(Directories.bongocatGif)
            playing: parent.visible
            fillMode: Image.PreserveAspectFit
            width: 64
            height: 64
        }
    }

    SessionActionButton {
        id: lockBtn
        icon: "lock"
        command: Session.lockCommand
        KeyNavigation.up: poweroffBtn
        KeyNavigation.down: rebootBtn
    }

    SessionActionButton {
        id: rebootBtn
        icon: "cached"
        command: Session.rebootCommand
        warnIfBusy: true
        KeyNavigation.up: lockBtn
    }
}
