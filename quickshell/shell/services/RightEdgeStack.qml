pragma Singleton
import QtQuick
import Quickshell

// Right-edge stacking coordinator — panels register open/width per screen, then read back how far panels nearer the edge push them left
Singleton {
    id: root

    readonly property var order: ["sidebar", "session", "volume"]

    // screen name -> { panelName -> { open, width } }
    property var registry: ({})

    function register(screen, name, open, width): void {
        const key = screen?.name ?? "";
        const forScreen = Object.assign({}, root.registry[key]);
        forScreen[name] = { open, width };
        root.registry = Object.assign({}, root.registry, { [key]: forScreen });
    }

    // Sum of widths of every open panel stacked outside `name` (i.e.
    // earlier in `order`) on the given screen
    function offsetFor(screen, name): real {
        const key = screen?.name ?? "";
        const forScreen = root.registry[key] ?? {};
        const idx = root.order.indexOf(name);
        let offset = 0;
        for (let i = 0; i < idx; i++) {
            const panel = forScreen[root.order[i]];
            if (panel?.open)
                offset += panel.width;
        }
        return offset;
    }
}
