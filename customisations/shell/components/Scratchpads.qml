import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    required property var backend
    readonly property var workspaces: backend.workspaces
    readonly property var focusedMonitor: backend.focusedMonitor

    readonly property var populatedSpecialWorkspaces: workspaces.values
        .filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0)
        .sort((a, b) => {
            const rank = n => n === "special:magic" ? 0 : n === "special:special" ? 1 : 2;
            return rank(a.name) - rank(b.name) || a.name.localeCompare(b.name);
        })

    readonly property HyprlandToplevel activeToplevel: {
        const t = Hyprland.activeToplevel;
        const special = focusedMonitor?.lastIpcObject.specialWorkspace?.name ?? "";
        if (special)
            return t?.workspace?.name === special ? t : null;
        return Hyprland.focusedWorkspace?.toplevels.values.length > 0 ? t : null;
    }
    property string lastSpecialWorkspace: ""
    // Keep empty scratchpads reachable even after Hyprland removes their objects.
    property var scratchpadHistory: ["special:magic", "special:special"]
    readonly property var scratchpadNames: [...new Set([
        ...scratchpadHistory,
        ...populatedSpecialWorkspaces.map(w => w.name)
    ])]

    function runSpecialAction(name: string, direction: string, toggle: bool): void {
        lastSpecialWorkspace = name;
        restoreSpecialAnimation.stop();
        const switching = direction === "next" || direction === "previous";
        const style = switching ? (direction === "next" ? "slide right" : "slide left") : "slidefadevert 15%";
        const speed = switching ? 5 : 4;
        const curve = switching ? "standard" : "specialWorkSwitch";
        const animation = `hl.animation({ leaf = "specialWorkspace", enabled = true, speed = ${speed}, bezier = "${curve}", style = "${style}" })`;
        const action = toggle
            ? `hl.dsp.workspace.toggle_special(${JSON.stringify(name.replace(/^special:/, ""))})`
            : `hl.dsp.focus({ workspace = ${JSON.stringify(name)} })`;
        // Apply the animation and dispatch together so the transition uses the new style.
        Quickshell.execDetached(["hyprctl", "eval", animation + "; hl.dispatch(" + action + ")"]);
        if (switching)
            restoreSpecialAnimation.restart();
    }

    function openLastSpecialWorkspace(): void {
        const active = focusedMonitor?.lastIpcObject.specialWorkspace?.name ?? "";
        if (!active)
            root.runSpecialAction(lastSpecialWorkspace || "special:magic", "", false);
    }

    function toggleLastSpecialWorkspace(): void {
        const active = focusedMonitor?.lastIpcObject.specialWorkspace?.name ?? "";
        root.runSpecialAction(active || lastSpecialWorkspace || "special:magic", "", true);
    }

    Timer {
        id: restoreSpecialAnimation
        interval: 550
        onTriggered: Quickshell.execDetached(["hyprctl", "eval",
            'hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "specialWorkSwitch", style = "slidefadevert 15%" })'])
    }

    function cycleSpecialWorkspace(direction: string): void {
        const names = root.scratchpadNames.slice();
        const activeSpecial = focusedMonitor?.lastIpcObject.specialWorkspace?.name ?? "";

        if (!activeSpecial) {
            root.scratchpadHistory = names;
            root.runSpecialAction(names.includes(lastSpecialWorkspace) ? lastSpecialWorkspace : names[0], "", false);
            return;
        }

        if (!names.includes(activeSpecial))
            names.push(activeSpecial);

        const currentIndex = names.indexOf(activeSpecial);
        const nextIndex = direction === "next" ? currentIndex + 1 : Math.max(0, currentIndex - 1);
        if (nextIndex === names.length) {
            let number = names.length + 1;
            while (names.includes(`special:scratchpad${number}`))
                number++;
            names.push(`special:scratchpad${number}`);
        }

        root.scratchpadHistory = names;
        // Focusing the already open special workspace would toggle it closed.
        if (names[nextIndex] !== activeSpecial)
            root.runSpecialAction(names[nextIndex], direction, false);
    }

}
