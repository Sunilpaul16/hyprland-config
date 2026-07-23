# Dashboard Panel Configurable Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user set an explicit width and/or height for the `SUPER+D` dashboard overlay in `config.json`, with every tab's cards reflowing to fit via layout bindings that already exist — no per-tab rework.

**Architecture:** Two independent `"auto"|"fixed"` mode switches in `Config.qml` (width, height). Width already flows top-down through existing `Layout.fillWidth` bindings, so fixed-width mode only needs a new formula on the panel `Rectangle`. Fixed-height mode requires flipping the height direction in `DashboardPanel.qml` — from content-driven (today) to panel-driven — so the active tab's `Loader` hands its available height down instead of measuring content height up. A new `clip: true` on the panel absorbs any content that can't shrink further.

**Tech Stack:** QML / Quickshell (`pragma Singleton`, `FileView` + `JsonAdapter`, `QtQuick.Layouts`).

**Full design reference:** `docs/superpowers/specs/2026-07-23-dashboard-panel-sizing-design.md`

## Global Constraints

- Auto mode (the default for both width and height) must remain byte-for-byte identical to today's rendered behavior — this is a regression risk to check explicitly, not assume.
- Follow this repo's `Config.qml` convention exactly: `property alias` on the singleton delegating to a `JsonAdapter` property; any property with a fixed set of valid string values gets a trailing `// "a" | "b"` comment (CLAUDE.md convention, already used for `Recorder.qml`'s `mode`, etc.).
- No test suite in this repo — verify every task live: `qmllint` the touched file (informational only — `Config.qml` is expected to hit the documented exit-255/no-output quirk for bare same-directory singleton references; that is not a failure), then restart `qs` (`pkill -x qs; qs -n -c shell`) and confirm a clean `Configuration Loaded` line with no `ERROR:`.
- `~/.config/quickshell/config.json` is hand-edited to seed new keys, mirroring how last session's dashboard sizing tokens were added — `JsonAdapter` only writes a key back to disk once it changes, so new keys with code-side defaults won't appear in the live file until either hand-added or changed once via the running shell.
- Only the final task commits. This is one cohesive feature — match this repo's own convention (confirmed by the user) of one commit per logical change, not one commit per micro-step.

---

### Task 1: `Config.qml` — panel size mode/value properties

**Files:**
- Modify: `quickshell/shell/services/Config.qml`
- Modify: `~/.config/quickshell/config.json` (hand-edit, outside the repo)

**Interfaces:**
- Produces: `Config.dashboardPanelWidthMode` (string, `"auto"|"fixed"`), `Config.dashboardPanelWidth` (int, pixels), `Config.dashboardPanelHeightMode` (string, `"auto"|"fixed"`), `Config.dashboardPanelHeight` (int, pixels) — all read by Task 2 and Task 3.

- [ ] **Step 1: Add the property aliases to the singleton**

In `quickshell/shell/services/Config.qml`, immediately after the existing dashboard-sizing alias block (after the `dashboardMediaProgressSweep` alias, before the `userAvatarPath` comment), insert:

```qml
    // Dashboard panel size — "auto" measures/fills as today; "fixed" uses the
    // paired pixel value below, clamped to 95% of screen size as a safety ceiling
    property alias dashboardPanelWidthMode: adapter.dashboardPanelWidthMode   // "auto" | "fixed"
    property alias dashboardPanelWidth: adapter.dashboardPanelWidth
    property alias dashboardPanelHeightMode: adapter.dashboardPanelHeightMode // "auto" | "fixed"
    property alias dashboardPanelHeight: adapter.dashboardPanelHeight
```

- [ ] **Step 2: Add the matching `JsonAdapter` defaults**

In the same file, inside the `JsonAdapter { id: adapter ... }` block, immediately after the existing `property int dashboardMediaProgressSweep: 180` line, insert:

```qml
            property string dashboardPanelWidthMode: "auto"
            property int dashboardPanelWidth: 1190
            property string dashboardPanelHeightMode: "auto"
            property int dashboardPanelHeight: 700
```

- [ ] **Step 3: Seed the live config file**

Add the four new keys to `~/.config/quickshell/config.json` (alphabetically, matching the existing file's key ordering):

```json
    "dashboardPanelHeight": 700,
    "dashboardPanelHeightMode": "auto",
    "dashboardPanelWidth": 1190,
    "dashboardPanelWidthMode": "auto",
```

- [ ] **Step 4: Lint**

Run: `qmllint quickshell/shell/services/Config.qml`
Expected: exit 255, no output (the documented bare-singleton-reference quirk — not a real error for this file; this is the same result this file already produces before this change).

- [ ] **Step 5: Restart `qs` and verify clean load**

Run: `pkill -x qs; qs -n -c shell`
Expected: stdout/stderr shows `Configuration Loaded` with no `ERROR:` line. This confirms the JSON and the new `JsonAdapter` properties parse correctly together — `Config.qml` doesn't crash on the new keys.

No commit yet — this task has no independently visible behavior change (nothing reads these properties until Task 2).

---

### Task 2: `DashboardPanel.qml` — fixed-width panel sizing

**Files:**
- Modify: `quickshell/shell/modules/dashboard/DashboardPanel.qml`

**Interfaces:**
- Consumes: `Config.dashboardPanelWidthMode`, `Config.dashboardPanelWidth` (from Task 1).
- Produces: `root.widthFixed` (bool) — read again in Task 3's height work for symmetry, though not required by it.

- [ ] **Step 1: Add the `widthFixed` property**

In `quickshell/shell/modules/dashboard/DashboardPanel.qml`, inside the `PanelWindow { id: root ... }` component, immediately after the existing:

```qml
                property int currentTab: 0
```

add:

```qml
                readonly property bool widthFixed: Config.dashboardPanelWidthMode === "fixed"
```

- [ ] **Step 2: Replace the panel `Rectangle`'s fixed width formula**

Find, inside the `panel` Rectangle:

```qml
                        width: Math.min((root.screen?.width ?? 1280) * 0.85, 1400)
```

Replace with:

```qml
                        width: root.widthFixed
                            ? Math.min(Config.dashboardPanelWidth, (root.screen?.width ?? 1280) * 0.95)
                            : Math.min((root.screen?.width ?? 1280) * 0.85, 1400)
```

- [ ] **Step 3: Lint**

Run: `qmllint quickshell/shell/modules/dashboard/DashboardPanel.qml`
Expected: exit 255, no output (same bare-singleton-import quirk documented in CLAUDE.md — this file already produced this before the change; not a regression indicator).

- [ ] **Step 4: Restart `qs` and verify auto mode is unchanged**

Run: `pkill -x qs; qs -n -c shell`, confirm clean `Configuration Loaded`.
Then: `qs -c shell ipc call dashboard open`, check `hyprctl monitors -j | jq '.[] | {name, focused}'` to find the focused monitor, and `grim -o <focused-monitor> /tmp/claude-1001/-home-spaul16-hyprland-config/aab3fc20-31f1-4c4e-acf8-c8afa17f38fd/scratchpad/panel-auto-width.png`.
Expected: panel renders at the same width as before this change (still ~85% of screen width, capped at 1400px) — `dashboardPanelWidthMode` defaults to `"auto"` so nothing should visibly change yet.

- [ ] **Step 5: Verify fixed mode with a small width**

Edit `~/.config/quickshell/config.json`: set `"dashboardPanelWidthMode": "fixed"` and `"dashboardPanelWidth": 700`. Quickshell's `FileView.watchChanges: true` picks this up live — no restart needed, but restart anyway for a clean log check: `pkill -x qs; qs -n -c shell`.
Then: `qs -c shell ipc call dashboard open`, screenshot the focused monitor to `/tmp/claude-1001/-home-spaul16-hyprland-config/aab3fc20-31f1-4c4e-acf8-c8afa17f38fd/scratchpad/panel-fixed-width-700.png`.
Expected: panel renders noticeably narrower (~700px), Dashboard tab's cards (Weather/User/Media columns) visibly narrower than the auto-width screenshot, tab bar still spans the full (narrower) panel width, nothing crashes or renders at 0 width.

- [ ] **Step 6: Revert the live config back to auto for the next task**

Edit `~/.config/quickshell/config.json` back to `"dashboardPanelWidthMode": "auto"`, `"dashboardPanelWidth": 1190`.

No commit yet — bundled into Task 4's single commit.

---

### Task 3: `DashboardPanel.qml` — fixed-height propagation + clip

**Files:**
- Modify: `quickshell/shell/modules/dashboard/DashboardPanel.qml`

**Interfaces:**
- Consumes: `Config.dashboardPanelHeightMode`, `Config.dashboardPanelHeight` (from Task 1), `root.widthFixed` pattern established in Task 2 (for the analogous `heightFixed` property).
- Produces: `root.heightFixed` (bool). No later task depends on it — this is the last piece of the feature.

- [ ] **Step 1: Add the `heightFixed` property**

Immediately after the `widthFixed` property added in Task 2:

```qml
                readonly property bool heightFixed: Config.dashboardPanelHeightMode === "fixed"
```

- [ ] **Step 2: Replace the panel `Rectangle`'s height formula and add `clip`**

Find:

```qml
                        // Content-driven, not a fixed screen fraction — so a tab whose
                        // cards need less room than the ceiling doesn't get stretched
                        // into dead space (caelestia's Wrapper.qml sizes the same way)
                        height: Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline
```

Replace with:

```qml
                        // Content-driven, not a fixed screen fraction — so a tab whose
                        // cards need less room than the ceiling doesn't get stretched
                        // into dead space (caelestia's Wrapper.qml sizes the same way).
                        // Fixed mode flips this: the panel dictates height down to the
                        // active tab instead (see tabView / paneLoader below).
                        height: root.heightFixed
                            ? Math.min(Config.dashboardPanelHeight, (root.screen?.height ?? 800) * 0.95)
                            : Math.min(contentColumn.implicitHeight + 40, (root.screen?.height ?? 800) * 0.85, 900)
                        radius: 18
                        color: Colors.background
                        border.width: 1
                        border.color: Colors.outline
                        clip: true
```

- [ ] **Step 3: Make `tabView` height panel-driven in fixed mode**

Find, on the `Flickable { id: tabView ... }`:

```qml
                                Layout.fillWidth: true
                                Layout.preferredHeight: currentPaneHeight

                                Behavior on currentPaneHeight {
```

Replace with:

```qml
                                Layout.fillWidth: true
                                Layout.fillHeight: root.heightFixed
                                Layout.preferredHeight: root.heightFixed ? -1 : currentPaneHeight

                                Behavior on currentPaneHeight {
```

- [ ] **Step 4: Make `paneLoader`'s height panel-driven in fixed mode**

Find, on the `Loader { id: paneLoader ... }` delegate inside `repeater`:

```qml
                                            x: index * tabView.paneWidth
                                            width: tabView.paneWidth
                                            // Own natural content height, not the tallest tab's —
                                            // tabView.currentPaneHeight then follows whichever pane
                                            // is current, animated on switch
                                            height: item ? item.implicitHeight : 0
```

Replace with:

```qml
                                            x: index * tabView.paneWidth
                                            width: tabView.paneWidth
                                            // Own natural content height, not the tallest tab's —
                                            // tabView.currentPaneHeight then follows whichever pane
                                            // is current, animated on switch. Fixed-height mode
                                            // flips this: the pane instead fills tabView's
                                            // panel-driven height, and its own fillHeight cards
                                            // (Calendar, Resources, Media, DateTime) reflow to fit.
                                            height: root.heightFixed ? tabView.height : (item ? item.implicitHeight : 0)
```

- [ ] **Step 5: Lint**

Run: `qmllint quickshell/shell/modules/dashboard/DashboardPanel.qml`
Expected: exit 255, no output (same known quirk as Task 2 — unchanged from before this task's edits).

- [ ] **Step 6: Restart `qs` and verify auto mode is still unchanged**

Run: `pkill -x qs; qs -n -c shell`, confirm clean `Configuration Loaded`.
Screenshot the Dashboard tab (default `currentTab: 0`) at the focused monitor to `/tmp/claude-1001/-home-spaul16-hyprland-config/aab3fc20-31f1-4c4e-acf8-c8afa17f38fd/scratchpad/panel-auto-height.png`.
Expected: identical to last session's already-verified auto-mode screenshot — panel height still tracks content, no dead space, no clipping.

- [ ] **Step 7: Verify fixed mode across all 4 tabs**

Edit `~/.config/quickshell/config.json`: set `"dashboardPanelHeightMode": "fixed"` and `"dashboardPanelHeight": 500` (short enough to force visible reflow/clipping on at least one tab). Restart `qs` for a clean log check.

For each tab, temporarily edit the `currentTab: 0` default in `DashboardPanel.qml` to `1`, `2`, then `3` (Media, Performance, Weather), restarting `qs` between each, and screenshot the focused monitor after `qs -c shell ipc call dashboard open`:
- `/tmp/claude-1001/-home-spaul16-hyprland-config/aab3fc20-31f1-4c4e-acf8-c8afa17f38fd/scratchpad/panel-fixed-height-dashboard.png` (currentTab 0)
- `.../panel-fixed-height-media.png` (currentTab 1)
- `.../panel-fixed-height-performance.png` (currentTab 2)
- `.../panel-fixed-height-weather.png` (currentTab 3)

Expected for each: panel is visibly shorter (~500px) than the auto-mode screenshot; `Layout.fillHeight` cards (Calendar, Resources, Media, DateTime, Performance's `CardSlot`s) are visibly compressed to fit; content that can't compress further (e.g. Dashboard tab's `SmallWeatherCard` fixed 200px block, Weather tab's forecast row) is cleanly cropped at the panel's rounded edge — no overlapping text, no content rendering outside the panel's rounded corners, no QML errors in the `qs` log.

- [ ] **Step 8: Revert all temporary test edits**

Set `currentTab` back to `property int currentTab: 0` in `DashboardPanel.qml`. Edit `~/.config/quickshell/config.json` back to `"dashboardPanelHeightMode": "auto"`, `"dashboardPanelHeight": 700`.

No commit yet — bundled into Task 4.

---

### Task 4: Final regression pass + single commit

**Files:**
- No new edits — this task only verifies and commits the work from Tasks 1–3.

**Interfaces:**
- Consumes: everything produced by Tasks 1–3.
- Produces: nothing further — this closes out the feature.

- [ ] **Step 1: Diff review — confirm no leftover test edits**

Run: `git diff -- quickshell/shell/services/Config.qml quickshell/shell/modules/dashboard/DashboardPanel.qml`
Expected: the diff contains only the additions from Tasks 1–3 (four `Config.qml` aliases + four `JsonAdapter` properties; `widthFixed`/`heightFixed` properties, the two `Rectangle` size formulas, `clip: true`, `tabView`'s `Layout.fillHeight`/`preferredHeight`, `paneLoader`'s `height` binding). No stray `currentTab` value other than `0`, no leftover debug rectangles/text, no config test values.

- [ ] **Step 2: Full regression screenshot in auto mode**

Confirm `~/.config/quickshell/config.json` has `dashboardPanelWidthMode`/`dashboardPanelHeightMode` both `"auto"`. Restart `qs` (`pkill -x qs; qs -n -c shell`), confirm clean `Configuration Loaded`. Open the dashboard and screenshot all 4 tabs (Dashboard/Media/Performance/Weather) — same procedure as Task 3 Step 7 but reading `currentTab` back at `0` and hardcoding 1/2/3 temporarily as before, reverting after.
Expected: pixel-equivalent to the screenshots taken at the end of last session's tab-bar/height-fix work — auto mode must show zero behavior change from before this feature existed.

- [ ] **Step 3: Commit**

```bash
git add quickshell/shell/services/Config.qml quickshell/shell/modules/dashboard/DashboardPanel.qml
git commit -m "$(cat <<'EOF'
dashboard: configurable panel width/height

Add dashboardPanelWidthMode/dashboardPanelHeightMode ("auto"|"fixed")
plus paired pixel values to Config.qml. Width already flowed top-down
through existing Layout.fillWidth bindings, so fixed width only needed
a new formula on the panel Rectangle. Fixed height required flipping
the direction from last session's content-driven sizing: tabView and
each tab's Loader now hand down panel-driven height when fixed, and
existing Layout.fillHeight cards reflow into it. A new clip: true
absorbs anything that can't shrink further. Auto mode (the default)
is unchanged.
EOF
)"
```

- [ ] **Step 4: Verify commit**

Run: `git status`
Expected: `nothing to commit, working tree clean`, branch ahead of `origin/main` by one more commit than before this feature.
