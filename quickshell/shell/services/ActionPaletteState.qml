pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Open state and searchable action catalogue for the experimental action palette.
Singleton {
    id: root

    property bool open: false
    property string ownerScreen: ""

    readonly property var actions: {
        // Keep the ticking countdown out of this model. Rebuilding a ListView
        // model every second would reset keyboard selection to the first row.
        const focusStatus = FocusMode.enabled ? "Active focus session · selecting this restarts the timer" : "Mute interruptions and keep the display awake";
        return [
            { id: "focus-25", label: "Focus for 25 minutes", description: focusStatus, icon: "timer", execute: () => FocusMode.start(25) },
            { id: "focus-50", label: "Focus for 50 minutes", description: focusStatus, icon: "center_focus_strong", execute: () => FocusMode.start(50) },
            { id: "focus-90", label: "Focus for 90 minutes", description: focusStatus, icon: "hourglass_top", execute: () => FocusMode.start(90) },
            { id: "focus-stop", label: "Stop focus mode", description: FocusMode.enabled ? "End the current session and restore previous settings" : "No focus session is active", icon: "timer_off", enabled: FocusMode.enabled, execute: () => FocusMode.stop(false) },
            ...WorkspaceScenes.scenes.map(scene => ({
                id: `scene-${scene.id}`,
                label: `Scene: ${scene.label}`,
                description: scene.description,
                icon: scene.icon,
                execute: scene.activate
            })),
            { id: "dnd", label: DndState.enabled ? "Disable Do Not Disturb" : "Enable Do Not Disturb", description: "Toggle notification popups", icon: DndState.enabled ? "notifications_active" : "do_not_disturb_on", execute: () => DndState.toggle() },
            { id: "awake", label: IdleInhibitState.enabled ? "Allow idle" : "Keep awake", description: "Toggle display and suspend inhibition", icon: IdleInhibitState.enabled ? "bedtime" : "coffee", execute: () => IdleInhibitState.toggle() },
            { id: "game", label: GameModeState.enabled ? "Disable game mode" : "Enable game mode", description: "Toggle low-overhead desktop effects", icon: "sports_esports", execute: () => GameModeState.toggle() },
            { id: "overview", label: "Open workspace overview", description: "See windows grouped by workspace", icon: "view_carousel", execute: () => OverviewState.toggle() },
            { id: "dashboard", label: "Open dashboard", description: "Media, weather and system performance", icon: "dashboard", execute: () => DashboardState.show() },
            { id: "settings", label: "Open settings", description: "Configure the shell", icon: "settings", execute: () => SettingsState.toggle() }
        ];
    }

    function query(text: string): var {
        const available = root.actions.filter(action => action.enabled !== false);
        const trimmed = text.trim();
        if (!trimmed)
            return available;
        return Fuzzy.go(trimmed, available, { key: "label", all: true }).map(result => result.obj);
    }

    function show(): void {
        ScreenOwner.claim(root);
        root.open = true;
    }

    function toggle(): void {
        if (root.open)
            root.open = false;
        else
            root.show();
    }

    IpcHandler {
        target: "actions"
        function open(): void { root.show(); }
        function toggle(): void { root.toggle(); }
        function close(): void { root.open = false; }
    }
}
