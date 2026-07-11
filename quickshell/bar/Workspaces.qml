import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

// Workspace pills, pinned 1..4 (or higher, see displaySlots) on *every* bar
// identically, regardless of which monitor a given workspace actually
// belongs to — so DP-3's bar and DP-2's bar always show the same slots,
// each reflecting that workspace's real occupied/active state wherever it
// actually lives.
//
// End-4-style three stacked layers (occupied-background pills, a sliding
// active highlight, then icons/numbers/click targets on top). Pill width
// isn't uniform -- a workspace with multiple distinct apps open widens to
// fit up to `maxIconsPerSlot` icons plus a "+N" overflow badge, so all three
// layers key off `slotLayout`'s precomputed per-slot x/width rather than a
// fixed `index * cell` grid.
Item {
    id: root
    property var screen

    // HyprlandMonitor for our screen. Each HyprlandWorkspace has a `.monitor`
    // reference (not a name string) — comparing objects, not strings.
    readonly property var monitor: Hyprland.monitorFor(root.screen)

    // Global, not filtered by monitor — both bars now pin the same 1..N
    // range regardless of which monitor actually owns each workspace (see
    // displaySlots below), so both need the full live workspace list.
    readonly property var allWorkspaces: Hyprland.workspaces.values

    readonly property int minSlots: 4

    // Pinned 1..N on *every* bar, identically, regardless of which monitor
    // each workspace actually belongs to (hypr/general.lua's workspace_rule
    // pins "2" to DP-2 and "1" to DP-3, but 3/4+ are unbound/dynamic) — both
    // Workspaces instances read the same global `allWorkspaces`, so they
    // naturally converge on the same slot set with no cross-instance
    // coordination needed. Grows past minSlots if a higher id exists
    // anywhere (e.g. SUPER+7 on either monitor), never shrinks below it.
    // Missing ids get a synthetic placeholder so the pill grid still has
    // something to render.
    readonly property var displaySlots: {
        const maxId = Math.max(root.minSlots, ...root.allWorkspaces.map(ws => ws.id), 0);
        const slots = [];
        for (let id = 1; id <= maxId; id++) {
            slots.push(root.allWorkspaces.find(ws => ws.id === id) ?? { id, active: false, isPlaceholder: true, monitor: null });
        }
        return slots;
    }

    readonly property int pillSize: 24
    readonly property int pillSpacing: 6
    readonly property real cell: pillSize + pillSpacing

    // "Active" means *this monitor's* current workspace specifically — a
    // pinned slot can be a real, occupied workspace that belongs to (and is
    // active on) the *other* monitor, and that's still not "active" from
    // this bar's point of view, just occupied. Each monitor only ever has
    // one active workspace, so this stays a single index exactly like
    // before, just scoped by `ws.monitor === root.monitor` now instead of
    // being implied by the old monitor-filtered `workspaces` list.
    readonly property int activeIndex: displaySlots.findIndex(ws => !ws.isPlaceholder && ws.monitor === root.monitor && ws.active)

    // Distinct app WM-classes open on a workspace, in window order (first
    // seen wins on duplicates) — one entry per *app*, not per window, so
    // three kitty windows on one workspace count once, matching "the icons
    // of the apps open on that workspace" rather than one icon per window.
    function appWmClasses(ws) {
        if (!ws || ws.isPlaceholder)
            return [];
        const seen = new Set();
        const classes = [];
        for (const tl of ws.toplevels.values) {
            const wmClass = tl.lastIpcObject?.class ?? "";
            if (!wmClass || seen.has(wmClass))
                continue;
            seen.add(wmClass);
            classes.push(wmClass);
        }
        return classes;
    }

    // WM-class -> icon resolution moved to AppIcons.qml (shared with
    // ActiveWindow.qml). "" means "no match", which the delegate below
    // falls back to the workspace number for.

    readonly property int maxIconsPerSlot: 3
    readonly property int iconSize: Math.round(pillSize * 0.62)
    readonly property int iconGap: 2

    // Per-slot layout: real pixel x/width for each displaySlot, computed
    // left-to-right so a wide multi-icon slot correctly pushes everything
    // after it over. Icons are resolved once here (not per-layer) so all
    // three Repeaters below agree on exactly the same widths/positions.
    readonly property var slotLayout: {
        let x = 0;
        const layout = [];
        for (const ws of root.displaySlots) {
            const wmClasses = root.appWmClasses(ws);
            const shownIcons = wmClasses.slice(0, root.maxIconsPerSlot).map(c => AppIcons.resolve(c)).filter(i => i.length > 0);
            const extra = Math.max(0, wmClasses.length - root.maxIconsPerSlot);
            const occupied = !ws.isPlaceholder && ws.toplevels.values.length > 0;

            let width = root.pillSize;
            if (shownIcons.length > 0 || extra > 0) {
                const iconsWidth = shownIcons.length * root.iconSize + Math.max(0, shownIcons.length - 1) * root.iconGap;
                const extraWidth = extra > 0 ? root.iconSize : 0;
                const gapBeforeExtra = (extra > 0 && shownIcons.length > 0) ? root.iconGap : 0;
                width = Math.max(root.pillSize, iconsWidth + gapBeforeExtra + extraWidth + root.iconGap * 2);
            }

            layout.push({ ws, x, width, occupied, shownIcons, extra });
            x += width + root.pillSpacing;
        }
        return layout;
    }

    implicitWidth: slotLayout.length > 0 ? (slotLayout[slotLayout.length - 1].x + slotLayout[slotLayout.length - 1].width) : 0
    implicitHeight: pillSize

    // Layer 1: occupied-workspace background pills. Hidden for whichever
    // slot is the active one *for this monitor* — the sliding highlight
    // (layer 2) covers that slot instead, so the two don't visually clash
    // (same trick end-4 uses: their per-slot background hides itself when
    // active). Can't just check `modelData.active` any more: a pinned slot
    // showing the *other* monitor's current workspace is genuinely `active`
    // (on that monitor), but shouldn't be treated as this bar's highlight
    // target — comparing against `root.activeIndex` (already scoped to
    // this monitor) gets that right, and also gives empty/unowned slots
    // the same subtler, no-background look the task asked for.
    Repeater {
        model: root.slotLayout

        Rectangle {
            // `required` matters here: a plain (non-required) `property var
            // modelData`/`index` does NOT get auto-filled by Repeater for
            // array models in this Quickshell/Qt version — it stays undefined.
            required property var modelData
            required property int index

            x: modelData.x
            width: modelData.width
            height: root.pillSize
            radius: height / 2
            color: Colors.surface
            opacity: (modelData.occupied && index !== root.activeIndex) ? 1 : 0

            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    // Layer 2: the active-workspace highlight. Used to interpolate between
    // fractional slot *indices* (end-4's AnimatedTabIndexPair two-speed
    // trick — stretch across the gap, then shrink back down) under the old
    // uniform-width grid, but pill widths aren't uniform any more now that
    // multi-icon slots widen (see slotLayout) — a fractional index doesn't
    // map to a pixel position without knowing every slot's width in
    // between. Animating the real x/width directly is simpler and still
    // correct regardless of slot width, at the cost of the old stretch-
    // across-the-gap flourish (now a plain slide + resize).
    Rectangle {
        id: highlight
        visible: root.activeIndex >= 0
        radius: height / 2
        color: Colors.primary
        height: root.pillSize

        readonly property var activeSlot: root.activeIndex >= 0 ? root.slotLayout[root.activeIndex] : null

        x: activeSlot ? activeSlot.x : 0
        width: activeSlot ? activeSlot.width : root.pillSize

        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }
    }

    // Layer 3: up to maxIconsPerSlot app icons plus a "+N" overflow badge
    // for the rest (when a workspace has more distinct apps than that),
    // falling back to the plain workspace number when nothing resolved to
    // an icon at all (genuinely empty, or occupied but unmatched) — always
    // on top of both layers above.
    Repeater {
        model: root.slotLayout

        Item {
            id: slot
            required property var modelData
            required property int index

            readonly property bool isActive: index === root.activeIndex
            readonly property bool hasIcons: modelData.shownIcons.length > 0 || modelData.extra > 0

            x: modelData.x
            width: modelData.width
            height: root.pillSize

            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutSine } }

            Row {
                visible: slot.hasIcons
                anchors.centerIn: parent
                spacing: root.iconGap

                Repeater {
                    model: slot.modelData.shownIcons

                    IconImage {
                        required property string modelData

                        asynchronous: true
                        source: Quickshell.iconPath(modelData, "")
                        implicitSize: root.iconSize
                    }
                }

                Text {
                    visible: slot.modelData.extra > 0
                    text: "+" + slot.modelData.extra
                    font.pixelSize: 10
                    font.bold: slot.isActive
                    color: slot.isActive ? Colors.background : Colors.textMuted
                }
            }

            Text {
                visible: !slot.hasIcons
                anchors.centerIn: parent
                text: modelData.ws.id
                font.pixelSize: 12
                font.bold: slot.isActive
                color: slot.isActive ? Colors.background : (modelData.occupied ? Colors.text : Colors.textMuted)

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // This custom Hyprland build's dispatch protocol takes Lua
                // expressions, not the classic "workspace N" string — see
                // hyprland/keybinds.lua for the same `hl.dsp.focus` pattern.
                // Every slot is clickable, including ones the *other*
                // monitor owns — confirmed via hyprctl that this dispatch
                // already focuses the right monitor and warps the cursor
                // there on its own.
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.ws.id} })`)
            }
        }
    }
}
