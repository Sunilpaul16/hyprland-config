# Settings Panel — Remaining Rows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire 12 of the settings panel's 14 remaining mock rows to real behaviour, taking the panel from 14 red rows to 2.

**Architecture:** Eleven new keys land in **existing** `Config` groups, so no new `property alias` is needed. Each row then binds to its key, and the consuming component reads it. Three rows need more than a binding: the volume OSD gains a mirrored left-edge layout, the toast stack gains four anchor positions, and a new `Fonts` service backs the monospace picker.

**Tech Stack:** Quickshell (Qt 6 / QML), `FileView` + `JsonAdapter` config, bash (`switchwall`), matugen templates.

## Global Constraints

- **No test suite, no CI, no build.** Verification is: lint the touched QML → restart the shell → exercise it live. Never report a row done from a code read.
- **Lint with Qt 6's qmllint**, never `/usr/bin/qmllint` (that is Qt 5's):
  ```
  /usr/lib/qt6/bin/qmllint -I quickshell/shell -I /usr/lib/qt6/qml \
    --missing-property disable --import disable --unqualified disable \
    --unresolved-type disable --missing-type disable --incompatible-type disable \
    --uncreatable-type disable <file>
  ```
  Ignore the one known false positive: `Type QProcess::ExitStatus ... was not found` on every `Process.onExited`.
- **Restart explicitly** after every change; hot reload is not trustworthy for verification:
  ```
  pkill -x qs; qs -n -c shell
  ```
  Count `Configuration Loaded` in the log to prove a reload happened. A clean lint does **not** prove signal wiring — the runtime is what rejects a bad handler with `Cannot assign to non-existent property`.
- **One commit per logical change.** Commit messages follow the repo's existing voice: lowercase scope prefix (`shell:`, `settings:`, `docs:`), imperative, no trailing period.
- **Every row wired must gain `live: true`.** A row without it renders red — that is the panel's progress board.
- **String properties with a fixed value set** carry a trailing `// "a" | "b"` comment.
- **Never write private-use-area glyphs as literals.** Use `"\uf303"`-style escapes. A whole-file `Write` preserves the byte but `Read` renders it invisible, which makes literals unreviewable; a targeted `Edit` is the safe tool near them.
- **Overlay panels only render on the Hyprland-focused monitor.** Before reading a blank screenshot as failure, check `hyprctl monitors -j | jq '.[] | {name, focused}'`.
- **Do not edit `~/.config/quickshell/config.json` with `jq > tmp && mv`.** The inode swap breaks `FileView`'s watch and the shell later writes its stale in-memory copy back over the file. Use `cat tmp > config.json`.

---

## File Structure

**Modified — services:**
- `services/Config.qml` — 11 new keys across 7 existing groups
- `services/Audio.qml` — configurable volume ceiling
- `services/Fuzzy.qml` — substring fallback when fuzzy is off
- `services/SidebarRightState.qml` — `quickTogglesEditMode`, close-on-settings
- `services/Updates.qml` — notify on growth

**Modified — modules:**
- `modules/volumeOsd/VolumeOsd.qml` — enable/timeout/edge
- `modules/volumeOsd/VolumeOsdContent.qml` — slider ceiling
- `modules/notifications/NotifPopups.qml` — four toast positions
- `modules/sidebarRight/QuickTogglesRow.qml` — edit mode moves to the singleton
- `modules/bar/Bar.qml` — updates indicator slot
- `modules/settings/{AudioPage,PanelsPage,ServicesPage,UpdatesPage,WallpaperStylePage}.qml` — the rows
- `modules/settings/AppVolumeRow.qml` — slider ceiling
- 5 font sites (listed in Task 11)

**Created:**
- `services/Fonts.qml` — installed monospace families
- `modules/bar/UpdatesIndicator.qml` — bar pill

**Modified — outside the shell:**
- `scripts/switchwall` — respect `wallpaper.display`

**Not created:** `matugen/templates/hyprland/colors.lua` already emits `misc.background_color` (verified: `hypr/colors.lua:13` renders `rgba(191114FF)`). Spec §8 part 3 needs no work.

---

### Task 1: Config keys

**Files:**
- Modify: `quickshell/shell/services/Config.qml`

**Interfaces:**
- Produces: `Config.audio.{allowBoost,osdEnabled,osdTimeout,osdEdge}`, `Config.notifications.popupPosition`, `Config.launcher.fuzzy`, `Config.sidebar.closeOnSettings`, `Config.updates.{notify,showInBar}`, `Config.appearance.fontMono`, `Config.wallpaper.display`

All seven groups already exist and already have `property alias` lines, so **no alias work is needed** — adding a scalar to an existing group is safe.

- [ ] **Step 1: Add the audio keys**

In the `audio` `JsonObject`, after `unmuteOnChange`:

```qml
                property bool allowBoost: false   // let the sink exceed unity gain
                property bool osdEnabled: true    // show the volume OSD on change
                property int osdTimeout: 1500     // ms before the OSD auto-hides
                property string osdEdge: "right"  // "right" | "left"
```

- [ ] **Step 2: Add the remaining keys to their groups**

`launcher`, after `maxClipResults`:
```qml
                property bool fuzzy: true      // subsequence matching; off = plain substring
```

`updates`, after `aurHelper`:
```qml
                property bool notify: true     // desktop notification when the pending count grows
                property bool showInBar: false // pending-count pill in the bar
```

`sidebar`, after `calendarCollapsed`:
```qml
                property bool closeOnSettings: true // close the sidebar when settings opens
```

`notifications`, at the end of the group:
```qml
                property string popupPosition: "top-right" // "top-right" | "top-left" | "bottom-right" | "bottom-left"
```

`appearance`, at the end of the group:
```qml
                property string fontMono: "JetBrainsMono Nerd Font"
```

`wallpaper`, after `previewDelay`:
```qml
                property bool display: true    // false kills mpvpaper and shows misc:background_color
```

- [ ] **Step 3: Lint**

Run the Global Constraints lint command on `quickshell/shell/services/Config.qml`.
Expected: exit 0.

- [ ] **Step 4: Restart and prove the keys resolve**

```bash
pkill -x qs; qs -n -c shell 2>&1 | tee /tmp/qs.log &
sleep 5
grep -c "Configuration Loaded" /tmp/qs.log
grep -i "TypeError\|Cannot assign" /tmp/qs.log
```
Expected: at least one `Configuration Loaded`, and **no** `TypeError` (a missing alias surfaces as `TypeError: Cannot read property '...' of undefined`, not a load error).

- [ ] **Step 5: Confirm defaults reach disk**

Toggle any already-live setting so the adapter writes, then:
```bash
jq '{audio, launcher, updates, sidebar: .sidebar.closeOnSettings, wallpaper}' ~/.config/quickshell/config.json
```
Expected: the new keys present with the defaults above. Defaults match today's behaviour, so nothing should visibly change.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/services/Config.qml
git commit -m "shell: add config keys for the settings panel's remaining rows"
```

---

### Task 2: Volume OSD — show toggle and dismiss delay

**Files:**
- Modify: `quickshell/shell/modules/volumeOsd/VolumeOsd.qml`
- Modify: `quickshell/shell/modules/settings/AudioPage.qml:161-190`

**Interfaces:**
- Consumes: `Config.audio.osdEnabled`, `Config.audio.osdTimeout` (Task 1)

- [ ] **Step 1: Gate the OSD on the toggle**

In `VolumeOsd.qml`, change `show()` so a disabled OSD never triggers (this also keeps it out of `RightEdgeStack`, rather than animating an invisible drawer):

```qml
                function show(): void {
                    if (!root.startupGraceOver || !Config.audio.osdEnabled)
                        return;
                    root.triggered = true;
                    armHideTimer();
                }
```

And harden `visible` so disabling it mid-show hides it immediately:
```qml
                visible: Config.audio.osdEnabled && showProgress > 0.001
```

- [ ] **Step 2: Make the auto-hide delay configurable**

Replace the hardcoded interval:
```qml
                // Auto-hide timer
                Timer {
                    id: hideTimer
                    interval: Config.audio.osdTimeout
                    onTriggered: root.triggered = false
                }
```

- [ ] **Step 3: Wire the two rows**

In `AudioPage.qml`, the "Show volume OSD" row:
```qml
        SettingRow {
            first: true
            live: true
            label: "Show volume OSD"

            ToggleSwitch {
                checked: Config.audio.osdEnabled
                onToggled: v => Config.audio.osdEnabled = v
            }
        }
```

The "Dismiss after" row — `SelectPill` becomes a `NumberControl`, matching how every other millisecond setting in the panel is presented (the polling rows). `labelWidth`'s default of 78 already fits `"5000 ms"`:
```qml
        SettingRow {
            live: true
            label: "Dismiss after"

            NumberControl {
                value: Config.audio.osdTimeout
                from: 500
                to: 5000
                stepSize: 250
                suffix: " ms"
                onMoved: v => Config.audio.osdTimeout = Math.round(v)
            }
        }
```

- [ ] **Step 4: Lint and restart**

Lint both files, then restart per Global Constraints and confirm `Configuration Loaded`.

- [ ] **Step 5: Exercise live**

```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
```
Expected: the OSD drawer appears. Time its disappearance against the configured value, then set "Dismiss after" to 500 ms and 5000 ms and confirm the change. Turn "Show volume OSD" off, repeat the `wpctl` call, and confirm nothing appears.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/modules/volumeOsd/VolumeOsd.qml quickshell/shell/modules/settings/AudioPage.qml
git commit -m "settings: wire the volume OSD's show toggle and dismiss delay"
```

---

### Task 3: Volume OSD — edge

**Files:**
- Modify: `quickshell/shell/modules/volumeOsd/VolumeOsd.qml`
- Modify: `quickshell/shell/modules/settings/AudioPage.qml` ("Position" row)

**Interfaces:**
- Consumes: `Config.audio.osdEdge` (Task 1)

The OSD is a right-edge **drawer** — flush at `restingMargin: 0`, square right corners, two `Corner` fillets bridging into the screen edge, and the third member of `RightEdgeStack`'s `["sidebar", "session", "volume"]` order. Only left/right are offered; free positioning would mean abandoning that idiom.

- [ ] **Step 1: Add the edge property to the drawer**

Inside `Item { id: drawer ... }`, beside the other readonly constants:
```qml
                    readonly property bool onRight: Config.audio.osdEdge !== "left"
```

- [ ] **Step 2: Mirror the anchors**

Replace the drawer's three anchor lines. Assigning `undefined` clears an anchor, which is how the same item serves both edges:
```qml
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: drawer.onRight ? parent.right : undefined
                    anchors.left: drawer.onRight ? undefined : parent.left
                    anchors.rightMargin: drawer.onRight ? (closedMargin + (restingMargin - closedMargin) * root.showProgress + stackOffset) : 0
                    anchors.leftMargin: drawer.onRight ? 0 : (closedMargin + (restingMargin - closedMargin) * root.showProgress)
```

The left edge omits `stackOffset` deliberately — nothing stacks there.

- [ ] **Step 3: Mirror the backdrop's squared corners**

```qml
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        topRightRadius: drawer.onRight ? 0 : 20
                        bottomRightRadius: drawer.onRight ? 0 : 20
                        topLeftRadius: drawer.onRight ? 20 : 0
                        bottomLeftRadius: drawer.onRight ? 20 : 0
                        color: Colors.panel
                    }
```

- [ ] **Step 4: Mirror the two fillets**

```qml
                    Corner {
                        anchors {
                            right: drawer.onRight ? parent.right : undefined
                            left: drawer.onRight ? undefined : parent.left
                            bottom: parent.top
                        }
                        size: drawer.cornerSize
                        color: Colors.panel
                        corner: drawer.onRight ? "bottomRight" : "bottomLeft"
                    }

                    Corner {
                        anchors {
                            right: drawer.onRight ? parent.right : undefined
                            left: drawer.onRight ? undefined : parent.left
                            top: parent.bottom
                        }
                        size: drawer.cornerSize
                        color: Colors.panel
                        corner: drawer.onRight ? "topRight" : "topLeft"
                    }
```

- [ ] **Step 5: Keep RightEdgeStack right-edge-only**

All three `RightEdgeStack.register` calls pass `root.active && drawer.onRight` as the open flag, so a left-edge OSD never pushes the sidebar or session drawer. Update the root-level handler:
```qml
                onActiveChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, drawer.registeredWidth)
```

And inside `drawer`, replace the two registration lines and add one for the edge flipping while open:
```qml
                    onRegisteredWidthChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)
                    onOnRightChanged: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)
                    Component.onCompleted: RightEdgeStack.register(root.screen, "volume", root.active && drawer.onRight, registeredWidth)
```

- [ ] **Step 6: Wire the row**

`SelectPill` cycles rather than opening a menu, which suits a two-member enum exactly:
```qml
        SettingRow {
            last: true
            live: true
            label: "Position"

            SelectPill {
                options: [
                    { value: "right", label: "Right edge" },
                    { value: "left", label: "Left edge" }
                ]
                current: Config.audio.osdEdge
                onSelected: v => Config.audio.osdEdge = v
            }
        }
```

- [ ] **Step 7: Lint and restart**

- [ ] **Step 8: Exercise live**

```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 40%
hyprctl layers -j | jq '.. | objects | select(.namespace? == "quickshell-volume-osd") | {x, y, w, h}'
```
Expected on `right`: `x` near the right screen edge. Switch the row to "Left edge", repeat: `x` should be `0`. Screenshot with `grim` and confirm the fillets curve the correct way and the flat side hugs the screen edge with no gap.

Then check the stack interaction: open the right sidebar (`qs -c shell ipc call sidebarRight open`) and trigger the OSD. On `right` it must sit left of the sidebar; on `left` it must be unaffected by the sidebar being open.

- [ ] **Step 9: Commit**

```bash
git add quickshell/shell/modules/volumeOsd/VolumeOsd.qml quickshell/shell/modules/settings/AudioPage.qml
git commit -m "shell: let the volume OSD drawer sit on either screen edge"
```

---

### Task 4: Allow volume above 100%

**Files:**
- Modify: `quickshell/shell/services/Audio.qml:67-101`
- Modify: `quickshell/shell/modules/volumeOsd/VolumeOsdContent.qml:75`
- Modify: `quickshell/shell/modules/settings/AudioPage.qml:40,86` and the "Allow over 100%" row
- Modify: `quickshell/shell/modules/settings/AppVolumeRow.qml:40`

**Interfaces:**
- Consumes: `Config.audio.allowBoost` (Task 1)
- Produces: `Audio.maxVolume` (real) — the ceiling every volume slider binds its `to` to

A cap the sliders cannot reach would be a dead setting, so the four sites pinned to `to: 1` move in the same commit.

- [ ] **Step 1: Add the ceiling to Audio.qml**

Beside the other readonly properties near the top of `Singleton { id: root`:
```qml
    // Ceiling for both setters and for every slider that drives them. 1.5 rather
    // than a larger boost because PipeWire clips hard above it on most sinks
    readonly property real maxVolume: Config.audio.allowBoost ? 1.5 : 1
```

- [ ] **Step 2: Apply it in both setters**

Update the comment, which currently claims a fixed `[0, 1]`:
```qml
    // Sink volume — clamped [0, maxVolume]. PipeWire can report NaN on
    // resume-from-suspend; Math.min/max propagate it straight through the
    // clamp, so guard before it reaches the sink.
    function setVolume(newVolume: real): void {
        if (isNaN(newVolume))
            return;
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(root.maxVolume, newVolume));
    }
```

And the mic setter:
```qml
        if (source?.ready && source?.audio)
            source.audio.volume = Math.max(0, Math.min(root.maxVolume, newVolume));
```

- [ ] **Step 3: Raise the four sliders**

At `VolumeOsdContent.qml:75`, `AudioPage.qml:40`, `AudioPage.qml:86`, and `AppVolumeRow.qml:40`, change `to: 1` to:
```qml
            to: Audio.maxVolume
```

`AppVolumeRow` writes its node's volume directly rather than through `Audio.setVolume`, so it is not clamped by the cap — raising its `to` is what lets a per-app stream be boosted at all, and is intentional.

- [ ] **Step 4: Wire the row**

```qml
        SettingRow {
            live: true
            label: "Allow over 100%"
            subtext: "Lets the sink boost past unity gain"

            ToggleSwitch {
                checked: Config.audio.allowBoost
                onToggled: v => Config.audio.allowBoost = v
            }
        }
```

- [ ] **Step 5: Lint and restart**

- [ ] **Step 6: Exercise live**

With the toggle **off**:
```bash
wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%
qs -c shell ipc call media next >/dev/null 2>&1 || true
wpctl get-volume @DEFAULT_AUDIO_SINK@
```
Raise volume past unity from the shell (scroll the bar's volume zone or drag the OSD slider to its maximum) and confirm `wpctl get-volume` reports `1.00` and no higher.

Turn the toggle **on**, drag the slider to maximum, and confirm `wpctl get-volume` reports up to `1.50`. Confirm the OSD slider physically travels further than before.

- [ ] **Step 7: Commit**

```bash
git add quickshell/shell/services/Audio.qml quickshell/shell/modules/volumeOsd/VolumeOsdContent.qml \
        quickshell/shell/modules/settings/AudioPage.qml quickshell/shell/modules/settings/AppVolumeRow.qml
git commit -m "settings: make the volume ceiling configurable past unity gain"
```

---

### Task 5: Launcher fuzzy-matching opt-out

**Files:**
- Modify: `quickshell/shell/services/Fuzzy.qml`
- Modify: `quickshell/shell/modules/settings/PanelsPage.qml:176-184`

**Interfaces:**
- Consumes: `Config.launcher.fuzzy` (Task 1)

All four consumers (`Apps`, `Commands`, `Wallpapers`, `Cliphist`) call `Fuzzy.go(...).map(r => r.obj)`. Putting the fallback **inside** `go` means one edit and no consumer changes. `Config` is a same-directory singleton, so it resolves without an extra import — `Updates.qml` already references it the same way.

- [ ] **Step 1: Add the substring fallback**

Replace the body of `services/Fuzzy.qml`:
```qml
pragma Singleton
import QtQuick
import "./fuzzysort.js" as Fuzzysort

// Thin wrapper around the vendored fuzzysort.js — lets the four importers
// (Apps/Wallpapers/Cliphist/Commands) reference one singleton instead of
// each importing the .js file directly
QtObject {
    function go(query, list, options) {
        if (!Config.launcher.fuzzy)
            return root.substringGo(query, list, options);
        return Fuzzysort.go(query, list, options);
    }

    // Plain case-insensitive substring match, wrapped to fuzzysort's {obj}
    // result shape so no caller has to know which mode is active. Keeps the
    // list's own order rather than ranking
    function substringGo(query, list, options) {
        const key = options?.key ?? "";
        const needle = String(query).toLowerCase();
        return list
            .filter(o => String(o[key] ?? "").toLowerCase().includes(needle))
            .map(o => ({ obj: o }));
    }
}
```

Note `QtObject` has no `id`. Add `id: root` to it so `root.substringGo` resolves:
```qml
QtObject {
    id: root
```

- [ ] **Step 2: Wire the row**

```qml
        SettingRow {
            first: true
            live: true
            label: "Fuzzy matching"
            subtext: "Off matches plain substrings only"

            ToggleSwitch {
                checked: Config.launcher.fuzzy
                onToggled: v => Config.launcher.fuzzy = v
            }
        }
```

- [ ] **Step 3: Lint and restart**

- [ ] **Step 4: Exercise live**

```bash
qs -c shell ipc call launcher openApps
```
With fuzzy **on**, type a subsequence that is not a substring — e.g. `frfx` for "Firefox", or `sysmon` for "System Monitor". Expect a match.
Turn fuzzy **off**, repeat: expect **no** match for the subsequence, but `fire` still matches "Firefox".
Also check the clipboard source, which keys on `text` rather than `name`:
```bash
qs -c shell ipc call launcher openClip
```
Type a substring of a known clipboard entry and confirm it still filters in both modes.

- [ ] **Step 5: Commit**

```bash
git add quickshell/shell/services/Fuzzy.qml quickshell/shell/modules/settings/PanelsPage.qml
git commit -m "settings: let the launcher fall back to plain substring matching"
```

---

### Task 6: Close the sidebar when settings opens

**Files:**
- Modify: `quickshell/shell/services/SidebarRightState.qml`
- Modify: `quickshell/shell/modules/settings/PanelsPage.qml:249-258`

**Interfaces:**
- Consumes: `Config.sidebar.closeOnSettings` (Task 1)

- [ ] **Step 1: Add the Connections block**

In `SidebarRightState.qml`, after the `toggle()` function and before the `IpcHandler`:
```qml
    // Close when the settings panel opens
    Connections {
        target: SettingsState

        function onOpenChanged() {
            if (SettingsState.open && Config.sidebar.closeOnSettings)
                root.open = false;
        }
    }
```

This is one-directional — `SettingsState` does not reference `SidebarRightState`, so there is no singleton cycle.

- [ ] **Step 2: Wire the row**

```qml
        SettingRow {
            last: true
            live: true
            label: "Close when settings opens"

            ToggleSwitch {
                checked: Config.sidebar.closeOnSettings
                onToggled: v => Config.sidebar.closeOnSettings = v
            }
        }
```

- [ ] **Step 3: Lint and restart**

- [ ] **Step 4: Exercise live**

```bash
qs -c shell ipc call sidebarRight open
qs -c shell ipc call settings toggle
```
Expected with the toggle on: the sidebar closes as settings opens. Turn the row off, repeat, and confirm both stay open simultaneously.

- [ ] **Step 5: Commit**

```bash
git add quickshell/shell/services/SidebarRightState.qml quickshell/shell/modules/settings/PanelsPage.qml
git commit -m "settings: close the right sidebar when the settings panel opens"
```

---

### Task 7: Quick toggles row navigates to sidebar edit mode

**Files:**
- Modify: `quickshell/shell/services/SidebarRightState.qml`
- Modify: `quickshell/shell/modules/sidebarRight/QuickTogglesRow.qml:13,156,162,163,172,203,216`
- Modify: `quickshell/shell/modules/settings/PanelsPage.qml:226-236`

**Interfaces:**
- Produces: `SidebarRightState.quickTogglesEditMode` (bool)

`QuickTogglesRow.editMode` is a plain local property, so settings cannot reach it. It moves to the singleton. A `property alias` will not work here — aliases must target an `id` in scope, and a singleton is not one — so the local property is removed and every reference reads the singleton directly.

- [ ] **Step 1: Add the state**

In `SidebarRightState.qml`, after `ownerScreen`:
```qml
    // Quick-toggles edit mode; settings navigates here rather than holding a value
    property bool quickTogglesEditMode: false
```

Extend the existing `onOpenChanged` so edit mode never persists into the next open:
```qml
    onOpenChanged: {
        if (root.open)
            ScreenOwner.claim(root);
        else
            root.quickTogglesEditMode = false;
    }
```

- [ ] **Step 2: Point QuickTogglesRow at the singleton**

Delete line 13 (`property bool editMode: false`), then replace every `root.editMode` with `SidebarRightState.quickTogglesEditMode`. The occurrences are at lines 156, 162, 163, 203 and 216, plus the click handler at 172, which becomes:
```qml
                onClicked: SidebarRightState.quickTogglesEditMode = !SidebarRightState.quickTogglesEditMode
```

Verify none remain:
```bash
grep -n "root.editMode\|property bool editMode" quickshell/shell/modules/sidebarRight/QuickTogglesRow.qml
```
Expected: no output.

- [ ] **Step 3: Make the settings row a navigation action**

The row stops pretending to hold a value. Settings closes **first** so the action cannot fight Task 6's close-on-settings rule:
```qml
        SettingRow {
            first: true
            live: true
            label: "Quick toggles"
            subtext: "Opens the sidebar's edit mode"

            SelectPill {
                value: "Edit"
                icon: "chevron_right"
                onClicked: {
                    SettingsState.open = false;
                    ScreenOwner.claim(SidebarRightState);
                    SidebarRightState.open = true;
                    SidebarRightState.quickTogglesEditMode = true;
                }
            }
        }
```

`ScreenOwner.claim` is what pins the sidebar to the focused monitor — it mirrors what `SidebarRightState`'s own IPC `open()` does.

- [ ] **Step 4: Lint and restart**

- [ ] **Step 5: Exercise live**

```bash
qs -c shell ipc call settings open
```
Navigate to Panels, click the "Quick toggles" row. Expected: settings closes, the right sidebar opens, and the quick-toggles edit affordances are active (the edit button shows `check`, and the hidden-toggle "add back" palette is visible).

Then confirm the in-sidebar button still works standalone: click `check` to leave edit mode, click `edit` to re-enter. Close the sidebar while in edit mode and reopen it — it must come back **not** in edit mode.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/services/SidebarRightState.qml \
        quickshell/shell/modules/sidebarRight/QuickTogglesRow.qml \
        quickshell/shell/modules/settings/PanelsPage.qml
git commit -m "settings: navigate to the sidebar's quick-toggle edit mode"
```

---

### Task 8: Toast position

**Files:**
- Modify: `quickshell/shell/modules/notifications/NotifPopups.qml:26-75`
- Modify: `quickshell/shell/modules/settings/ServicesPage.qml:50-58`

**Interfaces:**
- Consumes: `Config.notifications.popupPosition` (Task 1)

The `PanelWindow` already spans the whole screen (all four layershell anchors true); only the inner `stack` is positioned. Two things deliberately need no change: swipe-to-dismiss is already symmetric (`ToastCard.qml:51` tests `Math.abs(card.x)`), and `mask: Region { item: stack }` stays a **static** reference — making it conditional would silently break the surface's rendering, not just its input.

- [ ] **Step 1: Derive the two axes**

On the `PanelWindow`, beside the other layout constants:
```qml
                // Popup corner
                readonly property bool atTop: Config.notifications.popupPosition.startsWith("top")
                readonly property bool atRight: Config.notifications.popupPosition.endsWith("right")
```

- [ ] **Step 2: Anchor the stack to the chosen corner**

Replace `stack`'s four anchor lines:
```qml
                    anchors.top: root.atTop ? parent.top : undefined
                    anchors.bottom: root.atTop ? undefined : parent.bottom
                    anchors.right: root.atRight ? parent.right : undefined
                    anchors.left: root.atRight ? undefined : parent.left
                    anchors.topMargin: root.atTop ? root.topGap : 0
                    anchors.bottomMargin: root.atTop ? 0 : root.topGap
                    anchors.rightMargin: root.atRight ? root.sideGap : 0
                    anchors.leftMargin: root.atRight ? 0 : root.sideGap
```

- [ ] **Step 3: Grow the list away from the edge**

On the inner `ListView`, so the newest toast stays nearest the screen edge in the bottom positions:
```qml
                        verticalLayoutDirection: root.atTop ? ListView.TopToBottom : ListView.BottomToTop
```

- [ ] **Step 4: Wire the row**

Four options is past `SelectPill`'s cycling comfort (its own comment scopes it to two or three), so this uses `SelectMenu`:
```qml
        SettingRow {
            last: true
            live: true
            label: "Popup position"

            SelectMenu {
                options: [
                    { value: "top-right", label: "Top right" },
                    { value: "top-left", label: "Top left" },
                    { value: "bottom-right", label: "Bottom right" },
                    { value: "bottom-left", label: "Bottom left" }
                ]
                current: Config.notifications.popupPosition
                onSelected: v => Config.notifications.popupPosition = v
            }
        }
```

- [ ] **Step 5: Lint and restart**

- [ ] **Step 6: Exercise live**

For each of the four values:
```bash
notify-send -a test "Toast one" "First body"
notify-send -a test "Toast two" "Second body"
grim /tmp/toast.png
```
Expected: both toasts render in the selected corner, and in the bottom positions the **newer** toast sits closest to the screen edge. Confirm the toasts are still click-through outside their own bounds (the mask still works) by clicking a window behind the empty area beside them.

Then confirm swipe still dismisses in a left-hand position — drag a toast sideways past 30% of its width in both directions.

- [ ] **Step 7: Commit**

```bash
git add quickshell/shell/modules/notifications/NotifPopups.qml quickshell/shell/modules/settings/ServicesPage.qml
git commit -m "settings: let notification toasts sit in any screen corner"
```

---

### Task 9: Notify when updates land

**Files:**
- Modify: `quickshell/shell/services/Updates.qml`
- Modify: `quickshell/shell/modules/settings/UpdatesPage.qml:141-149`

**Interfaces:**
- Consumes: `Config.updates.notify` (Task 1)

The shell already sends notifications this way — `SessionActionButton.qml:33` is the precedent. `Quickshell` is already imported in `Updates.qml`.

- [ ] **Step 1: Track what has been announced**

After the `_repoDone` / `_aurDone` properties:
```qml
    // Last count announced, so a re-check finding the same updates stays quiet
    property int _lastNotifiedTotal: 0
```

- [ ] **Step 2: Fire on growth only**

Extend `_settle()` and add the helper beside it:
```qml
    function _settle(): void {
        if (!root._repoDone || !root._aurDone)
            return;
        root.checking = false;
        root.lastChecked = Date.now();
        root._notifyIfGrown();
    }

    function _notifyIfGrown(): void {
        if (Config.updates.notify && root.total > root._lastNotifiedTotal)
            Quickshell.execDetached(["notify-send", "-a", "quickshell",
                "-i", "system-software-update",
                `${root.total} update${root.total === 1 ? "" : "s"} available`,
                `${root.repoCount} from the repos, ${root.aurCount} from the AUR.`]);
        root._lastNotifiedTotal = root.total;
    }
```

Assigning `_lastNotifiedTotal` unconditionally means an upgrade that drops the count re-arms the notification for the next batch.

- [ ] **Step 3: Wire the row**

```qml
        SettingRow {
            first: true
            live: true
            label: "Notify when updates land"

            ToggleSwitch {
                checked: Config.updates.notify
                onToggled: v => Config.updates.notify = v
            }
        }
```

- [ ] **Step 4: Lint and restart**

- [ ] **Step 5: Exercise live**

The real check is slow and depends on there genuinely being updates, so drive the state directly. With the toggle on, force a check and watch for the toast:
```bash
qs -c shell ipc call settings page 4
```
Click "Check now" on the Updates page. Expected, **if** the count is non-zero and higher than the last announced: a notification toast appears with the count in its summary.

To exercise the growth rule deterministically without waiting for real packages, temporarily set `_lastNotifiedTotal` low by restarting the shell (it initialises to 0), then trigger a check — a non-zero total must notify. Trigger a second check immediately: it must **not** notify again.

Turn the toggle off and repeat: no toast.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/services/Updates.qml quickshell/shell/modules/settings/UpdatesPage.qml
git commit -m "shell: notify when the pending update count grows"
```

---

### Task 10: Pending-update count in the bar

**Files:**
- Create: `quickshell/shell/modules/bar/UpdatesIndicator.qml`
- Modify: `quickshell/shell/modules/bar/Bar.qml:170-180`
- Modify: `quickshell/shell/modules/settings/UpdatesPage.qml:151-159`

**Interfaces:**
- Consumes: `Config.updates.showInBar` (Task 1), `Updates.total`, `Updates.repoCount`, `Updates.aurCount`
- Produces: `UpdatesIndicator.active` (bool) — the bar reads it to hide the wrapping `SectionPill`

Modelled on `NotifIndicator.qml`, including its collapse-to-zero-width animation. It uses `MaterialIcon` rather than a Nerd Font glyph, which sidesteps the private-use-area literal problem entirely.

- [ ] **Step 1: Create the indicator**

```qml
import QtQuick
import "../../services"
import "../../components"

// Pending-update count, hidden while there is nothing pending
Item {
    id: root

    readonly property bool active: Config.updates.showInBar && Updates.total > 0

    // Collapses to zero width rather than just hiding, so the bar's RowLayout
    // reclaims the space — same approach as NotifIndicator
    implicitWidth: active ? icon.implicitWidth + count.implicitWidth + 4 : 0
    implicitHeight: icon.implicitHeight
    visible: implicitWidth > 0
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing }
    }

    MaterialIcon {
        id: icon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "update"
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 15

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    Text {
        id: count

        anchors.left: icon.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: Updates.total > 99 ? "99+" : Updates.total
        color: hoverArea.containsMouse ? Colors.text : Colors.textMuted
        font.pixelSize: 12

        Behavior on color { ColorAnimation { duration: Motion.quickDuration; easing.type: Motion.quickEasing } }
    }

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SettingsState.currentPageIdx = 4; // Updates, per Content.qml's pageModel
            ScreenOwner.claim(SettingsState);
            SettingsState.open = true;
        }
    }
}
```

- [ ] **Step 2: Add it to the bar**

In `Bar.qml`'s right-side `RowLayout`, directly after the `SectionPill` wrapping `NotifIndicator`:
```qml
                        SectionPill {
                            Layout.alignment: Qt.AlignVCenter
                            horizontalPadding: 8
                            visible: updatesIndicator.active

                            UpdatesIndicator {
                                id: updatesIndicator
                            }
                        }
```

- [ ] **Step 3: Wire the row**

```qml
        SettingRow {
            live: true
            label: "Show count in the bar"

            ToggleSwitch {
                checked: Config.updates.showInBar
                onToggled: v => Config.updates.showInBar = v
            }
        }
```

- [ ] **Step 4: Lint and restart**

Lint the new file too. Note `Updates` is a `pragma Singleton` that only exists once referenced — `shell.qml`'s `Component.onCompleted` already pokes it with `backgroundChecking = true`, and that poke is still required, because the indicator is inert when `showInBar` is false.

- [ ] **Step 5: Exercise live**

Turn the row on. If `Updates.total` is currently 0 the pill is correctly invisible; force a check from the Updates page first.
```bash
qs -c shell ipc call settings page 4
```
Expected with a non-zero total: an update pill appears in the bar between the notification bell and the tray, showing the count. Hover it — the icon and count should brighten. Click it — settings must open on the Updates page.

Turn the row off and confirm the pill collapses away and the bar's other right-side items close the gap.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/modules/bar/UpdatesIndicator.qml quickshell/shell/modules/bar/Bar.qml \
        quickshell/shell/modules/settings/UpdatesPage.qml
git commit -m "shell: show the pending-update count in the bar"
```

---

### Task 11: Monospace font

**Files:**
- Create: `quickshell/shell/services/Fonts.qml`
- Modify: `quickshell/shell/modules/sidebarRight/SystemHeaderCard.qml:24`
- Modify: `quickshell/shell/modules/settings/AboutPage.qml:34`
- Modify: `quickshell/shell/modules/bar/NotifIndicator.qml:27`
- Modify: `quickshell/shell/modules/dashboard/dash/UserCard.qml:70`
- Modify: `quickshell/shell/modules/sidebarRight/NotificationsCard.qml:35`
- Modify: `quickshell/shell/modules/settings/WallpaperStylePage.qml:227-234`

**Interfaces:**
- Consumes: `Config.appearance.fontMono` (Task 1)
- Produces: `Fonts.monoFamilies` (list<string>) — sorted, deduplicated installed monospace families

`components/MaterialIcon.qml`'s `"Material Symbols Rounded"` is **not** included — it is an icon font, not a text font.

- [ ] **Step 1: Create the font service**

Follows the `Process` + `StdioCollector` pattern used by `Wallpapers.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Installed monospace families, for the settings font picker
Singleton {
    id: root

    property list<string> monoFamilies: []

    Component.onCompleted: scanProc.running = true

    // Scan installed monospace families
    Process {
        id: scanProc
        command: ["fc-list", ":spacing=100", "family"]

        stdout: StdioCollector {
            onStreamFinished: {
                const seen = ({});
                const out = [];
                for (const line of text.split("\n")) {
                    // fc-list emits comma-separated aliases per font; the first
                    // is the family name the QML font stack matches on
                    const family = line.split(",")[0].trim();
                    if (family.length === 0 || seen[family])
                        continue;
                    seen[family] = true;
                    out.push(family);
                }
                root.monoFamilies = out.sort();
            }
        }
    }
}
```

This singleton's only consumer is the settings page, which is a UI consumer — so unlike `Updates` it needs no wake-up poke in `shell.qml`.

- [ ] **Step 2: Replace the five hardcoded families**

At each of the five sites, replace the literal `"JetBrainsMono Nerd Font"` with `Config.appearance.fontMono`. Four are a direct swap:
```qml
                font.family: Config.appearance.fontMono
```

`NotificationsCard.qml:35` is a conditional and keeps its shape:
```qml
            font.family: sb.glyph.length > 0 ? Config.appearance.fontMono : Qt.application.font.family
```

Confirm none remain:
```bash
grep -rn '"JetBrainsMono Nerd Font"' quickshell/shell/
```
Expected: no output.

- [ ] **Step 3: Wire the row**

The family list is long, so this is a `SelectMenu`. The subtext carries the warning rather than filtering the list, because Nerd Font coverage cannot be reliably detected from `fc-list`:
```qml
        SettingRow {
            last: true
            live: true
            label: "Monospace font"
            subtext: "Used for glyphs too — a non-Nerd font blanks the distro logo"

            SelectMenu {
                options: Fonts.monoFamilies.map(f => ({ value: f, label: f }))
                current: Config.appearance.fontMono
                onSelected: v => Config.appearance.fontMono = v
            }
        }
```

- [ ] **Step 4: Lint and restart**

Lint the new service and all six modified files.

- [ ] **Step 5: Exercise live**

Confirm the scan actually produced families before trusting the dropdown:
```bash
fc-list ":spacing=100" family | sed 's/,.*//' | sort -u | head
```
Open settings → Wallpaper & style. Expected: the dropdown lists those families, with `JetBrainsMono Nerd Font` selected.

Pick a different monospace family. Expected: the About page's monospace text, the sidebar's system header, and the dashboard user card all change family. Screenshot to confirm:
```bash
qs -c shell ipc call sidebarRight open
grim /tmp/font.png
```
Deliberately pick a **non**-Nerd font (e.g. `DejaVu Sans Mono`) and confirm the distro logo glyph blanks — that is the documented trade-off, not a regression. Set it back to `JetBrainsMono Nerd Font` and confirm the glyph returns.

- [ ] **Step 6: Commit**

```bash
git add quickshell/shell/services/Fonts.qml quickshell/shell/modules/ quickshell/shell/
git commit -m "settings: make the shell's monospace font configurable"
```

---

### Task 12: Display wallpaper

**Files:**
- Modify: `scripts/switchwall:115-123`
- Modify: `quickshell/shell/modules/settings/WallpaperStylePage.qml:42-49`

**Interfaces:**
- Consumes: `Config.wallpaper.display` (Task 1)

Three parts in the spec; only two are work. `matugen/templates/hyprland/colors.lua` **already** emits `misc.background_color` (verified rendered at `hypr/colors.lua:13` as `rgba(191114FF)`), so the bare desktop already shows a wallpaper-derived colour.

- [ ] **Step 1: Teach switchwall the setting**

`switchwall` already reads `config.json` through its `cfg` helper for the `theming.*` group; this reuses it rather than adding a second state file.

The gate must let `--preview` through unconditionally — it is the explicit "display this wallpaper now" path the settings toggle calls, and gating it on the config would deadlock against `Config`'s debounced write. Replace the step-1 condition:
```bash
# --- 1. Wallpaper display: mpvpaper on both monitors ------------------------
# --preview is an explicit display request and always spawns; a normal run
# respects the wallpaper.display setting
if ! $NOSWITCH && ! $COLORS_PREVIEW && { $PREVIEW || [[ "$(cfg '.wallpaper.display' true)" != "false" ]]; }; then
    pkill -f -9 mpvpaper >/dev/null 2>&1 || true
    for mon in "${MONITORS[@]}"; do
        mpvpaper -o "$MPV_OPTS" "$mon" "$wallpaper" &
        sleep 0.1
    done
fi
```

- [ ] **Step 2: Add the apply process to the page**

Inside `WallpaperStylePage.qml`'s root, beside its other non-visual children:
```qml
    // Applies the wallpaper-display toggle without waiting for the next
    // switchwall run. --preview sets the wallpaper and exits before any colour
    // generation, so re-displaying costs nothing and keeps the mpvpaper
    // invocation in switchwall alone
    Process {
        id: wallpaperDisplayProc
    }

    function applyWallpaperDisplay(on: bool): void {
        wallpaperDisplayProc.command = on
            ? ["sh", "-c", "switchwall --preview \"$(cat \"$HOME/.local/state/quickshell/current_wallpaper\")\""]
            : ["pkill", "-f", "mpvpaper"];
        wallpaperDisplayProc.running = true;
    }
```

Add `import Quickshell.Io` to the file if it is not already imported.

- [ ] **Step 3: Wire the row**

```qml
        SettingRow {
            live: true
            label: "Display wallpaper"
            subtext: "Off shows the themed background colour instead"

            ToggleSwitch {
                checked: Config.wallpaper.display
                onToggled: v => {
                    Config.wallpaper.display = v;
                    root.applyWallpaperDisplay(v);
                }
            }
        }
```

- [ ] **Step 4: Lint and restart**

- [ ] **Step 5: Exercise live**

```bash
pgrep -a mpvpaper
```
Expected before: one process per monitor. Toggle "Display wallpaper" off:
```bash
sleep 1; pgrep -a mpvpaper; grim /tmp/nowall.png
```
Expected: no mpvpaper processes, and the screenshot shows the flat themed background colour rather than the image.

Toggle it back on:
```bash
sleep 2; pgrep -a mpvpaper; grim /tmp/wall.png
```
Expected: processes return and the wallpaper is visible again.

Finally confirm the setting survives a full theme run — with the toggle **off**:
```bash
scripts/switchwall --noswitch
sleep 2; pgrep -a mpvpaper
```
Expected: still no mpvpaper (the `--noswitch` path never spawns), and colours regenerate normally. Then set a wallpaper outright with the toggle still off:
```bash
scripts/switchwall ~/Pictures/Wallpapers/<some-image>
sleep 2; pgrep -a mpvpaper
```
Expected: no mpvpaper spawned, because the setting is off — but the theme still updates from that image.

- [ ] **Step 6: Commit**

```bash
git add scripts/switchwall quickshell/shell/modules/settings/WallpaperStylePage.qml
git commit -m "settings: let the wallpaper display be turned off"
```

---

### Task 13: Update the status docs

**Files:**
- Modify: `INDEX.md`

**Interfaces:**
- Consumes: every preceding task

- [ ] **Step 1: Confirm exactly two red rows remain**

```bash
cd quickshell/shell/modules/settings
for f in *Page.qml *SubPage.qml; do
  awk -v F="$f" '
    /SettingRow \{|PillButton \{/ { inblk=1; depth=0; islive=0; name="" }
    inblk {
      n=gsub(/\{/,"{"); depth+=n
      m=gsub(/\}/,"}"); depth-=m
      if ($0 ~ /live: true/) islive=1
      if (match($0, /label: *"[^"]*"/)) { name=substr($0, RSTART+8, RLENGTH-8) }
      if (depth<=0) { if(!islive) printf "%s:%d  %s\n", F, NR, name; inblk=0 }
    }
  ' "$f"
done
```
Expected: exactly two lines — `WallpaperStylePage.qml … Interface font"` and `UpdatesPage.qml … Terminal used for upgrades"`.

- [ ] **Step 2: Rewrite the settings entry**

Replace the "Settings panel" bullet under `## 🚧 In progress` with:

```markdown
- **Settings panel** — 9 pages. **2 rows are still mock and render red**; the other
  12 were wired 2026-07-31 (see
  `docs/superpowers/specs/2026-07-31-settings-remaining-rows-design.md`). Each
  remaining row is blocked on a subsystem that does not exist yet, not on a config key:
  - **Terminal used for upgrades** — `Updates.qml` only *checks*; there is no upgrade
    action at all. Blocked on an upgrade runner.
  - **Interface font** — needs shell-wide text styling, i.e. `review/comparison.md`
    #33's shared `StyledText` tier. `appearance.fontMono` already covers the
    monospace half.
  - Open question: scope. Shell settings only (end-4 shaped) vs system management —
    network/bluetooth pairing (caelestia's Nexus shaped).
  - Decided 2026-07-27: the panel *may* drive `state.json`-backed toggles (DND, night
    light) but only by binding to the singleton, never by writing the file, so both
    surfaces stay in sync. Momentary actions (start recording) stay sidebar-only;
    settings owns their *defaults*.
```

- [ ] **Step 3: Note the new config surface**

In the "Runtime config system" bullet, update the key count from `~102 keys` to the real number:
```bash
grep -c "property \(bool\|int\|real\|string\|var\) " quickshell/shell/services/Config.qml
```
Use that number in place of `~102`.

- [ ] **Step 4: Add the volume-OSD trap**

Under `## 🪤 Traps worth remembering`:
```markdown
- **The volume OSD is an edge *drawer*, not a floating pill** — it is flush at
  `restingMargin: 0` with squared corners plus `Corner` fillets, and is the third
  member of `RightEdgeStack`'s `["sidebar", "session", "volume"]` order. It supports
  left/right only, and registers with that stack **only on the right**. Free
  positioning would mean abandoning the idiom it shares with `SessionScreen`.
```

- [ ] **Step 5: Commit**

```bash
git add INDEX.md
git commit -m "docs: record the settings panel's remaining two mock rows"
```

---

## Self-Review

**Spec coverage** — every spec section maps to a task:

| Spec section | Task |
| --- | --- |
| Config keys (11) | 1 |
| §1 config plumbing — OSD enabled, timeout | 2 |
| §1 config plumbing — close on settings | 6 |
| §1 config plumbing — allow boost + slider audit | 4 |
| §2 fuzzy matching | 5 |
| §3 volume OSD edge | 3 |
| §4 toast position | 8 |
| §5 updates notify | 9 |
| §5 updates bar count | 10 |
| §6 quick toggles → edit mode | 7 |
| §7 monospace font | 11 |
| §8 display wallpaper | 12 |
| Outcome / INDEX.md | 13 |

**Corrections found against the spec while planning:**

1. **Spec §8 part 3 is already done.** `matugen/templates/hyprland/colors.lua` already emits `misc.background_color`, rendered at `hypr/colors.lua:13`. Task 12 drops it.
2. **Spec §8's ordering had a race.** The spec had the toggle write config then call `switchwall`, but `Config`'s writes are debounced, so `switchwall` could read the stale value and refuse to spawn. Task 12 instead exempts `--preview` from the gate entirely, which removes the ordering dependency.
3. **The spec's `SelectPill` assumption was wrong for one row.** `SelectPill` *cycles* through options and its own comment scopes it to two or three members. Toast position has four, so Task 8 uses `SelectMenu`; the OSD edge has two, so Task 3 keeps `SelectPill`.
4. **"Dismiss after" is better as a `NumberControl`.** The mock used a `SelectPill`, but every other millisecond setting in the panel uses `NumberControl`, and it avoids inventing an arbitrary preset list.
5. **`property alias` cannot target a singleton.** Task 7 removes `QuickTogglesRow.editMode` outright rather than aliasing it.

**Placeholder scan:** no TBD/TODO; every code step carries real code; the one "audit" the spec called for is resolved into four named line numbers in Task 4.

**Type consistency:** `Audio.maxVolume` (Task 4) is consumed by name in the same task only. `SidebarRightState.quickTogglesEditMode` (Task 7) is written in three files, all listed. `UpdatesIndicator.active` (Task 10) is read by `Bar.qml` in the same task. `Fonts.monoFamilies` (Task 11) is consumed in the same task. `Fuzzy.substringGo` (Task 5) is internal to its file and needs the `id: root` added in Step 1.

**Known risk carried forward:** Task 4's `1.5` ceiling is a judgement call, not a measured limit. If a sink clips badly below it, lower the constant in `Audio.qml` — it is a single readonly binding.
