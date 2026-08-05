pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Overlaid toggle dialog
Singleton {
    id: root

    property string openDialog: "" // "" | "bluetooth"
    // Inline mixer card
    property bool mixerOpen: false

    function openBluetooth(): void {
        root.openDialog = "bluetooth";
    }

    function openVolume(): void {
        root.mixerOpen = true;
    }

    function toggleMixer(): void {
        root.mixerOpen = !root.mixerOpen;
    }

    function close(): void {
        root.openDialog = "";
        root.mixerOpen = false;
    }

    // IPC handler
    IpcHandler {
        target: "sidebarDialog"

        function openBluetooth(): void {
            root.openBluetooth();
        }

        function openVolume(): void {
            root.openVolume();
        }

        function toggleMixer(): void {
            root.toggleMixer();
        }

        function close(): void {
            root.close();
        }
    }
}
