pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Polkit agent
Singleton {
    id: root

    readonly property bool isRegistered: agent.isRegistered
    readonly property bool isActive: agent.isActive
    readonly property var flow: agent.flow

    // Pinned monitor
    property string ownerScreen: ""
    readonly property bool open: root.isActive

    onIsActiveChanged: if (root.isActive) ScreenOwner.claim(root)

    PolkitAgent {
        id: agent
    }
}
