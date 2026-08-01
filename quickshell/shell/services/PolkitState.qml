pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Wraps the native polkit agent (UI in modules/polkit/PolkitDialog.qml), registering on creation at /org/quickshell/Polkit
// Receives nothing while hyprpolkitagent.service is the session's active agent — deliberately not stopped here
Singleton {
    id: root

    readonly property bool isRegistered: agent.isRegistered
    readonly property bool isActive: agent.isActive
    readonly property var flow: agent.flow

    // Monitor this dialog is pinned to while shown. The agent drives visibility,
    // so it claims on isActive rather than through an open property
    property string ownerScreen: ""
    readonly property bool open: root.isActive

    onIsActiveChanged: if (root.isActive) ScreenOwner.claim(root)

    PolkitAgent {
        id: agent
    }
}
