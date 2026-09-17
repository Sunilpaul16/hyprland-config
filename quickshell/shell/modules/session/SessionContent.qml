import QtQuick
import "../../services"

// Session actions column
Column {
    id: root

    spacing: Motion.spacing.xlarge

    // Keyboard in use
    property bool keyNav: false

    // Focus first button
    function focusFirst(): void {
        logoutBtn.forceActiveFocus();
    }

    SessionActionButton {
        id: logoutBtn
        icon: "logout"
        command: Session.logoutCommand
        warnIfBusy: true
        keyNav: root.keyNav
        onNavigated: byKey => root.keyNav = byKey
        KeyNavigation.down: poweroffBtn
    }

    SessionActionButton {
        id: poweroffBtn
        icon: "power_settings_new"
        command: Session.poweroffCommand
        warnIfBusy: true
        keyNav: root.keyNav
        onNavigated: byKey => root.keyNav = byKey
        KeyNavigation.up: logoutBtn
        KeyNavigation.down: lockBtn
    }

    // Bongocat slot
    Item {
        implicitWidth: 64
        implicitHeight: 64
        clip: true

        AnimatedImage {
            anchors.centerIn: parent
            source: "file://" + Directories.bongocatGif
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
        keyNav: root.keyNav
        onNavigated: byKey => root.keyNav = byKey
        KeyNavigation.up: poweroffBtn
        KeyNavigation.down: rebootBtn
    }

    SessionActionButton {
        id: rebootBtn
        icon: "restart_alt"
        command: Session.rebootCommand
        warnIfBusy: true
        keyNav: root.keyNav
        onNavigated: byKey => root.keyNav = byKey
        KeyNavigation.up: lockBtn
    }
}
