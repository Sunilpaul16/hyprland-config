pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Facts the About page needs that only a subprocess can answer. Loaded on
// demand rather than at startup — nothing else reads these, and they'd cost
// three process spawns on every shell reload
Singleton {
    id: root

    property string gpuModel: ""
    property string hyprlandVersion: ""
    property string quickshellVersion: ""

    property bool loaded: false

    // Connected outputs, merged from Quickshell's screen list and Hyprland's
    // monitor JSON — the former has no refresh rate, the latter reports
    // pre-rotation dimensions
    readonly property var displays: Quickshell.screens.map(screen => {
        const ipc = Hyprland.monitorFor(screen)?.lastIpcObject ?? null;
        return {
            name: screen.name,
            model: screen.model,
            width: screen.width,
            height: screen.height,
            refreshRate: ipc?.refreshRate ?? 0
        };
    })

    function load(): void {
        if (root.loaded)
            return;
        root.loaded = true;
        gpuProc.running = true;
        hyprlandProc.running = true;
        quickshellProc.running = true;
    }

    // "NVIDIA Corporation" -> "NVIDIA"
    function cleanVendor(vendor: string): string {
        return vendor.replace(/\s*(Corporation|Corp\.|Inc\.|Technologies|Co\.,? Ltd\.?)\s*/gi, " ").replace(/\s+/g, " ").trim();
    }

    Process {
        id: gpuProc
        command: ["lspci", "-mm"]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => /"(VGA compatible controller|3D controller|Display controller)"/i.test(l));
                if (!line)
                    return;
                // -mm quotes each field: class, vendor, device, then subsystem.
                // Collected with exec() in a loop — QML's JS engine has no matchAll
                const fields = [];
                const field = /"([^"]*)"/g;
                let match;
                while ((match = field.exec(line)) !== null)
                    fields.push(match[1]);
                if (fields.length < 3)
                    return;
                // Marketing name sits in brackets ("GP104 [GeForce GTX 1070]")
                const bracketed = /\[([^\]]+)\]/.exec(fields[2]);
                root.gpuModel = `${root.cleanVendor(fields[1])} ${bracketed ? bracketed[1] : fields[2]}`.trim();
            }
        }
    }

    Process {
        id: hyprlandProc
        command: ["hyprctl", "version"]

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/^Hyprland (\S+)/m);
                if (match)
                    root.hyprlandVersion = match[1];
            }
        }
    }

    Process {
        id: quickshellProc
        command: ["qs", "--version"]

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Quickshell (\S+)/);
                if (match)
                    root.quickshellVersion = match[1];
            }
        }
    }
}
