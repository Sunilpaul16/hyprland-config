import QtQuick
import "../../services"

// Session/power actions column — right-edge drawer content
Column {
    id: root

    spacing: Motion.spacing.xlarge

    // Focus the first action button — called once from SessionScreen.qml
    // when the drawer opens, so Up/Down/Enter work without a click first
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

    // Decorative slot — bongocat gif
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
