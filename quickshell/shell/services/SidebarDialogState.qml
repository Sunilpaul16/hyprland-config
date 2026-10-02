pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Inline quick toggle cards
Singleton {
    id: root

    property bool mixerOpen: false
    property bool wifiOpen: false
    property bool bluetoothOpen: false

    function openWifi(): void {
        root.wifiOpen = true;
        root.mixerOpen = false;
        root.bluetoothOpen = false;
    }

    function toggleWifi(): void {
        root.wifiOpen = !root.wifiOpen;
        if (root.wifiOpen) {
            root.mixerOpen = false;
            root.bluetoothOpen = false;
        }
    }

    function openBluetooth(): void {
        root.bluetoothOpen = true;
        root.wifiOpen = false;
        root.mixerOpen = false;
    }

    function toggleBluetooth(): void {
        root.bluetoothOpen = !root.bluetoothOpen;
        if (root.bluetoothOpen) {
            root.wifiOpen = false;
            root.mixerOpen = false;
        }
    }

    function openVolume(): void {
        root.mixerOpen = true;
        root.wifiOpen = false;
        root.bluetoothOpen = false;
    }

    function toggleMixer(): void {
        root.mixerOpen = !root.mixerOpen;
        if (root.mixerOpen) {
            root.wifiOpen = false;
            root.bluetoothOpen = false;
        }
    }

    function close(): void {
        root.bluetoothOpen = false;
        root.mixerOpen = false;
        root.wifiOpen = false;
    }

    // IPC handler
    IpcHandler {
        target: "sidebarDialog"

        function toggleWifi(): void {
            root.toggleWifi();
        }

        function openWifi(): void {
            root.openWifi();
        }

        function toggleBluetooth(): void {
            root.toggleBluetooth();
        }

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
