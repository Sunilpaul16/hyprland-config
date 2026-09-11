pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Deliberately conservative activity scenes: they never close or move existing windows.
Singleton {
    id: root

    readonly property var scenes: [
        {
            id: "deep-work",
            label: "Deep work",
            icon: "terminal",
            description: "Workspace 1 · editor + terminal · 50 minute focus",
            activate: () => root.deepWork()
        },
        {
            id: "quick-task",
            label: "Quick task",
            icon: "bolt",
            description: "Workspace 1 · terminal · 25 minute focus",
            activate: () => root.quickTask()
        },
        {
            id: "browse",
            label: "Browse",
            icon: "language",
            description: "Workspace 2 · browser · normal notifications",
            activate: () => root.browse()
        },
        {
            id: "gaming",
            label: "Gaming",
            icon: "sports_esports",
            description: "Workspace 5 · game mode · no app is launched",
            activate: () => root.gaming()
        },
        {
            id: "normal",
            label: "Return to normal",
            icon: "restart_alt",
            description: "Stop focus and game modes without touching windows",
            activate: () => root.normal()
        }
    ]

    function go(workspace: int): void {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspace} })`);
    }

    function launch(command: list<string>): void {
        Quickshell.execDetached(["uwsm", "app", "--", ...command]);
    }

    function announce(name: string): void {
        Notifs.toast(`${name} scene`, "Scene applied without disturbing existing windows", "dashboard_customize");
    }

    function deepWork(): void {
        if (GameModeState.enabled)
            GameModeState.setEnabled(false, false);
        root.go(1);
        root.launch(["code"]);
        root.launch([Config.apps.terminal]);
        FocusMode.start(50);
        root.announce("Deep work");
    }

    function quickTask(): void {
        if (GameModeState.enabled)
            GameModeState.setEnabled(false, false);
        root.go(1);
        root.launch([Config.apps.terminal]);
        FocusMode.start(25);
        root.announce("Quick task");
    }

    function browse(): void {
        if (FocusMode.enabled)
            FocusMode.stop(false);
        if (GameModeState.enabled)
            GameModeState.setEnabled(false, false);
        root.go(2);
        root.launch(["google-chrome-stable"]);
        root.announce("Browse");
    }

    function gaming(): void {
        if (FocusMode.enabled)
            FocusMode.stop(false);
        root.go(5);
        GameModeState.setEnabled(true, false);
        root.announce("Gaming");
    }

    function normal(): void {
        if (FocusMode.enabled)
            FocusMode.stop(false);
        if (GameModeState.enabled)
            GameModeState.setEnabled(false, false);
        root.announce("Normal");
    }

    function activate(id: string): void {
        const scene = root.scenes.find(item => item.id === id);
        if (scene)
            scene.activate();
    }

    IpcHandler {
        target: "scene"

        function deepWork(): void { root.deepWork(); }
        function quickTask(): void { root.quickTask(); }
        function browse(): void { root.browse(); }
        function gaming(): void { root.gaming(); }
        function normal(): void { root.normal(); }
    }
}
