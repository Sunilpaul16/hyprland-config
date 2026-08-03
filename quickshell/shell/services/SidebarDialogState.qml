pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Overlaid toggle dialog
Singleton {
    id: root

    property string openDialog: "" // "" | "bluetooth" | "volume"

    function openBluetooth(): void {
        root.openDialog = "bluetooth";
    }

    function openVolume(): void {
        root.openDialog = "volume";
    }

    function close(): void {
        root.openDialog = "";
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

        function close(): void {
            root.close();
        }
    }
}
