pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Wraps the native polkit agent — see modules/polkit/PolkitDialog.qml for
// the UI. Registers automatically on creation at the default D-Bus path
// (/org/quickshell/Polkit). NOTE: hyprpolkitagent.service is currently the
// session's active registered agent — this won't actually receive
// requests until that service is stopped (deliberately not done here).
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
