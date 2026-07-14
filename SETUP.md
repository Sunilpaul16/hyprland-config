# hyprland-config — setup index & progress checklist

Living reference for my Hyprland desktop. Purpose: paste into a browser Claude for
**planning + progress tracking** — it's a feature index, a status board, and a backlog
in one. Keep the status markers current as things change.

Companion docs (gitignored, in `references/`): `end4-reference.md`, `caelestia-reference.md`,
`comparison.md` — how my setup stacks up against the two upstreams I borrow from.

## Legend
✅ done / working · 🚧 partial or half-finished · 🐛 known bug · ❓ needs verifying · 💡 idea / not started

---

## Orientation

- **Repo ↔ runtime:** this repo mirrors `~/.config` (**not symlinked — synced copies**). Scripts here in `scripts/` deploy to `~/.local/bin/`. Edits must be applied in both places, or drift happens (see backlog).
- **Machine:** dual 2560×1440@144. `DP-3` primary (0×0), `DP-2` secondary rotated (transform 3, positioned above). Monitors hardcoded in `hypr/general.lua` **and** `~/.local/bin/switchwall` (`MONITORS=(DP-3 DP-2)`).
- **Lineage:** standalone minimal subset of end-4/dots-hyprland. Uses the same `hl.*` Hyprland Lua config framework. Quickshell shell is hand-written from scratch (not end-4's `ii`).
- **Shell launch:** `qs -n -c shell` (from `hypr/execs.lua`). IPC: `qs -c shell ipc call <target> <fn>`.
- **Theming entry point:** `~/.local/bin/switchwall <image|video>` → regenerates all colors + reloads. `--preview` = wallpaper only (used while browsing).

### Key external deps
`hyprland` + `hl` lua framework · `quickshell` (qs) · `matugen` · `materialyoucolor` (venv at `~/.local/state/quickshell/.venv`) · `mpvpaper` · `ffmpeg` · `hypridle` · `hyprlock` · `fuzzel` · `kitty` · `wf-recorder` + `slurp` · `cliphist` + `wl-clipboard` · `playerctl` · `wireplumber` (`wpctl`) · `brightnessctl` · `nautilus` · `gnome-keyring` · `jq` · `blueman` (bluetooth tray GUI, `bluetoothd` backend) · `xdg-desktop-portal-hyprland` + `xdg-desktop-portal-gtk` · `hyprpolkitagent` · `NetworkManager` + `nm-applet`

---

## Subsystem index

### Theming pipeline — ✅ working
- **Where:** `matugen/config.toml`, `matugen/colorgen/generate_colors_material.py`, `matugen/colorgen/terminal/{kitty-theme.conf,scheme-base.json}`, orchestrated by `~/.local/bin/switchwall`.
- **How:** `switchwall` sets wallpaper (mpvpaper, both monitors), runs `matugen image` (renders 6 templates), runs materialyoucolor for kitty's 16-color palette (separate path), then `hyprctl reload` + kitty SIGUSR1. Video wallpapers: ffmpeg extracts a frame for color source.
- **Generated files (do NOT hand-edit):** `hypr/colors.lua`, `hypr/hyprlock/colors.conf`, `fuzzel/fuzzel_theme.ini`, `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, `quickshell/shell/services/Colors.qml`, `kitty/theme.conf`.
- **State:** last wallpaper at `~/.local/state/quickshell/current_wallpaper` (replayed on login via `execs.lua` → `switchwall --preview`).

### Quickshell services — ✅ working
- **Where:** `quickshell/shell/services/` (singletons).
- **Notables:** `Colors.qml` (matugen-generated theme), `Binds.qml` (parses `hyprctl binds -j` → feeds cheatsheet), `Audio`, `Media`/`MediaState`, `Notif`/`Notifs`/`NotifPanelState`, `Cliphist`, `Wallpapers`, `Time`, `Apps`/`AppIcons`, `Commands`, `SessionState`, `TrayMenuState`, `CheatsheetState`, `LauncherState`, `LastActive`, `fuzzysort.js`.
- **Note:** pure QML, no C++ plugin. Cheatsheet auto-derives from live hyprctl binds (zero keybind duplication).

### Quickshell modules — ✅ working
- **Where:** `quickshell/shell/modules/`, entry `quickshell/shell/shell.qml` (per-monitor `Variants`).
- **Modules:** `bar/` (Bar, Workspaces, ActiveWindow, Clock, Media/Notif/Session buttons, Tray, Corner, SectionPill, RecordingIndicator) · `launcher/` (Launcher, Content, App/Command/Clip/Wallpaper items) · `notifications/` (Popups, Card, Panel) · `session/` (power menu) · `cheatsheet/` · `volumeOsd/` · `mediaPopup/` · `trayMenu/`.

### Hyprland config — ✅ working
- **Where:** `hypr/hyprland.lua` (entry) → requires `variables · env · general · execs · rules · colors · keybinds`. Single-level (no `custom/` override tree).
- **How:** `hl.*` lua API. `colors.lua` loaded last so matugen borders win. Monitors + input + look/feel + animations all in `general.lua`. Keybind combos live as named `kb*` variables in `variables.lua` (e.g. `kbLock`, `kbTerminal`), referenced bare from `keybinds.lua` — no more inline mod-string literals (caelestia-pattern extraction, done).

### GTK theming — ✅ working (asymmetric, now documented)
- **Where:** `gtk-3.0/gtk.css` (~38 lines, colors only), `gtk-4.0/gtk.css` (~541 lines: colors + static libadwaita/Nautilus widget CSS). Both matugen-generated. `gtk-3.0/bookmarks` = Nautilus sidebar.
- **Note:** GTK4 carries the widget restyling; GTK3 gets palette only, since GTK3 apps don't use libadwaita — intentional, not half-finished. Explained in a header comment in the `gtk-3.0/gtk.css` template itself now. Editing widget styles = edit the matugen *template*, not the live file.

### Kitty / terminal theming — ✅ working
- **Where:** `kitty/kitty.conf` (includes `theme.conf`), `kitty/search.py` (scrollback search kitten, uses `kitty/scroll_mark.py`). Palette generated separately (see Theming).
- **How:** materialyoucolor emits a 16-color ANSI palette; `switchwall` `sed`-substitutes it into `theme.conf` from the `kitty-theme.conf` template.

### Idle / lock / DPMS — ✅ working (timeouts fixed, dispatch verified, bg themed)
- **Where:** `hypr/hypridle.conf`, `hypr/hyprlock.conf` + `hypr/hyprlock/{colors.conf,status.sh,check-capslock.sh}`.
- **How:** timeouts **300 / 600 / 900 s** = lock → DPMS off → suspend. DPMS via `hyprctl dispatch 'hl.dsp.dpms({...})'`. Lock via `hyprlock`. Status/caps-lock labels via the two scripts.
- Confirmed live: the `hl.dsp.*()` eval-dispatch pattern works — SUPER+M's `hl.dsp.exit()` fallback correctly triggers logout, same dispatch mechanism the DPMS listener uses.
- `background { color = ... }` now sources `$background_color` (matugen `colors.surface.dark`, same role `hypr/colors.lua` uses for the desktop background) instead of a hardcoded `rgba(181818FF)` — lock screen follows the wallpaper palette. Verified visually via `hyprlock --grace 5`.

### Animations — ✅ working
- **Where:** `hypr/general.lua` (`hl.curve` + `hl.animation`, M3-expressive bezier set). Quickshell animations are hardcoded per-component.
- 💡 no central animation-token singleton (see backlog).

### Fuzzel / launcher — ✅ working (demoted to unthemed fallback)
- **Where:** `fuzzel/fuzzel.ini` + static `fuzzel/fuzzel_theme.ini`.
- **Design:** in-shell Quickshell launcher is **primary** (SUPER+Space apps, SUPER+V clipboard, SUPER+T wallpaper). **Fuzzel is a deliberate backup app menu** (SUPER+R) for when quickshell is unavailable — intentional fallback, not redundancy.
- **Theming:** no longer matugen-generated — removed from `matugen/config.toml`'s template list. `fuzzel_theme.ini` is now a frozen static file (last-generated palette, hand-editable, safe from `switchwall` overwrites). Fallback doesn't need to track the live wallpaper palette.

### Scripts — ✅ working
- **Where:** repo `scripts/` → deploys to `~/.local/bin/`: `switchwall` (theming orchestrator), `record` (wf-recorder toggle, region/full/stop, `--sound`), `screenshot` (full/region/region --edit).
- **How:** standalone bash, `set -euo pipefail`, dependency-checked, idempotent. Recording state = the running `wf-recorder` process itself.

---

## Cleanup backlog

- [x] **Idle timeouts** corrected to 300/600/900 (were 3000/6000/9000, 10× off) — applied to repo + live, verified via `hypridle -c` dry-run showing all three rules registered correctly.
- [x] **Sync repo copy** — repo and live `~/.config` are in sync for every hand-edited file (verified via full drift sweep). No automated sync script exists yet — every edit still needs manual dual-apply (edit repo → `cp` to live, or vice versa). Not currently a problem since all edits this session went through that discipline, but worth automating eventually.
- [x] **Dead border** in `hypr/general.lua` — removed the hardcoded cyan `active_border`; confirmed via `hyprctl getoption general:col.active_border` on the live system that the real value still comes from `colors.lua`, unaffected.
- [x] **Hyprlock bg themed** — `background { color = ... }` now sources matugen's `colors.surface.dark` via a new `$background_color` in `hyprlock/colors.conf`, instead of hardcoded `rgba(181818FF)`. Verified via `hyprlock --grace 5`.
- [x] **Stale template comment** — `matugen/templates/quickshell-shell/Colors.qml` header fixed to reference the real key (`quickshell_shell_colors`) and real output path (`quickshell/shell/services/Colors.qml`); leftover from the `bar/` → `shell/` rename.
- [x] **`hl.dsp.*` dispatch verified** — confirmed working on the live system: SUPER+M's `hl.dsp.exit()` fallback correctly triggers logout. Same eval-dispatch mechanism backs the DPMS listener, so that's sound too.
- [x] **Unused locals** — removed `suppressMaximizeRule` (`rules.lua`) and `closeWindowBind` (`keybinds.lua`); confirmed zero references repo-wide before deleting. The underlying `hl.window_rule()`/`hl.bind()` calls are unchanged.
- [x] **Hardcoded `/home/spaul16` paths** — replaced everywhere: `execs.lua`/`keybinds.lua` use a new `home = os.getenv("HOME")` Lua global (`variables.lua`), QML callers (`Wallpapers.qml`, `RecordingIndicator.qml`, `Content.qml`) use the already-established `Quickshell.env("HOME")`.
- [x] **Document GTK3/GTK4 asymmetry** — header comment added to the `gtk-3.0/gtk.css` matugen template explaining it's colors-only because GTK3 apps don't use libadwaita, not half-finished.
- [ ] 🐛 **Duplicate polkit agent** — `polkit-kde-agent` is installed but not running (`hyprpolkitagent` is the active one); left in place deliberately since it's a hard dependency of the `illogical-impulse-kde` meta-package (which also owns `bluedevil`, `dolphin`, `plasma-nm`, `systemsettings` — a bigger cleanup than just polkit). Latent risk only, not causing issues today.

## Ideas / potential ports (from `references/comparison.md`)

- [ ] 💡 **Single-source color state** — caelestia-style watched `scheme.json` instead of matugen's N-file fan-out. Biggest architectural rethink.
- [x] **Named keybind vars** — `kb*` variables in `variables.lua` (caelestia pattern), referenced bare from `keybinds.lua`. Verified zero behavioral drift: executed old vs. new `keybinds.lua` against a stub `hl` API and diffed all 62 resolved (description, combo) pairs — identical. Live `hyprctl reload` confirmed 62 binds registered.
- [ ] 💡 **`custom/`-style override layer** — end-4's parallel override tree merged at load, for update-safe config (separate from the named-vars idea above — this one's still open).
- [ ] 💡 **Animation token singleton** — end-4 `Appearance` / caelestia `Anim` enum vs my per-component hardcoded durations.
- [ ] 💡 **Config-driven in-shell idle** — caelestia `IdleMonitors` with audio/charging/inhibitor awareness, replacing static `hypridle.conf`.
- [ ] 💡 **Wallpaper-aware niceties** — least-busy-region clock placement + readable text-contrast (end-4 `least_busy_region.py`/`text_color.py`); freeze-then-pick screenshot (caelestia).

---

## Apply / test cheatsheet
- Full re-theme: `switchwall ~/path/to/wallpaper` · preview only: `switchwall --preview <path>`
- Reload Hyprland: `hyprctl reload` · Reload hypridle after edit: `systemctl --user restart hypridle` (or `pkill hypridle && hypridle &`)
- Quickshell hot-reloads on file change (any edit under `quickshell/shell/` reloads the shell).
- Kitty live recolor: `pkill -SIGUSR1 -x kitty`

---

## Session log (newest first)
Each fix was applied to repo + live `~/.config`, live-verified, and committed separately.

Read-only system audit (portals, polkit, network, bluetooth, seat mgmt, audio, exec-once
coverage, fonts, cliphist) found everything present & running except no Bluetooth GUI —
fixed in Task 2 below. Six-task cleanup round followed:

- `8b13bcb` document GTK3/GTK4 asymmetry as intentional
- `9b48312` theme hyprlock background with matugen surface color
- `cd2013f` remove unused locals in rules.lua and keybinds.lua
- `689564a` replace hardcoded /home/spaul16 paths with HOME lookups
- `5c68800` add blueman for bluetooth GUI
- (skipped) remove duplicate polkit agent — `polkit-kde-agent` is pinned by the
  `illogical-impulse-kde` meta-package; user chose to leave it rather than cascade-remove
  bluedevil/dolphin/plasma-nm/systemsettings along with it
- `974f4e5` fix stale template comment in quickshell-shell Colors.qml
- `298abaf` remove dead active_border override in general.lua
- `68bc90f` extract keybind combos into named variables (caelestia pattern)
- `61a29f6` demote fuzzel to unthemed fallback launcher
- `2437189` fix hypridle timeouts: 3000/6000/9000 -> 300/600/900 seconds

Remaining open items: duplicate polkit agent (deliberately left), and the bigger
architectural ideas below.
