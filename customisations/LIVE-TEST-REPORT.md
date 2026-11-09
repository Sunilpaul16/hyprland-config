# Live activation and checks — 2026-11-09

The reorganised custom configuration is active in the existing Caelestia 2.5.0
session. This did not install the newer upstream shell or update system packages.
The shell was restarted successfully. All 307 installed shell files match the
repository sources, including the ten extracted QML/JavaScript components.
The installed standalone scripts and configuration also match their central
sources. Runtime files are ordinary copies; repository source paths are links.

## Backup

The previous shell, wallpaper service unit, shell/monitor preferences and session
metadata were preserved under:

```text
~/.local/state/caelestia-config-backups/custom-separation-20261109-161649-741782/
```

Only the shell tree and the wallpaper service's equivalent portable command path
needed replacement. Unrelated terminal, GTK, shell and Hyprland configuration
was left in place. No package installations or administrator changes were made.

## Live results

| Check | Result |
|---|---|
| Shell startup and IPC | Passed; one main Caelestia instance is running |
| Hyprland configuration | No configuration errors |
| Wallpaper playback | Video mode starts playback; static mode and game mode stop it |
| Game-mode restart | Game mode survived a shell restart without launching video |
| Wallpaper selection while static | Selecting the existing wallpaper kept playback stopped |
| Wallpaper launcher | Opened successfully with a populated wallpaper list |
| Sidebar | Open/close round trip through its shell IPC passed |
| Scratchpads | Open, next, previous, hide and reopen through the extracted controller passed |
| Bar helper | Persistent visibility preference toggled and restored |
| Night light | Live toggle and return to original state passed; Hyprsunset remains active |
| Settings | Opened; Escape sent specifically to the test window closed it |
| Cheatsheet | Opened, generated shortcut groups loaded, closed, and its log had no QML errors |
| Preferences after testing | Original shell and monitor preferences restored; game mode disabled and static wallpaper active, as before testing |

The live wallpaper matrix was run with `python3 tests/live_wallpaper.py`.
Targeted session checks exercised the other features. The test harness needed
the compositor's Lua dispatch API (`hl.dsp.send_shortcut` with a string `mods`
argument); correcting the harness required no shell implementation changes.
Panels, scratchpad visibility, night light, test windows and focus were restored
after those checks. The temporary cheatsheet instance was removed.

Before activation, 22 Python tests, 35 Lua checks, 36 JavaScript checks and
compilation of all 31 custom/integration QML files passed. The patch reconstruction
test and baseline rebuild verified the custom sources and generated shell.

## Existing session issues and verification limits

- Dunst owns `org.freedesktop.Notifications`, so Caelestia reports a notification
  registration warning. Dunst was already running when this deployment began;
  its service was not stopped or disabled. Notification delivery through
  Caelestia therefore remains unverified.
- No InputActions plugin is loaded. Its saved build ABI differs from the running
  Hyprland 0.57.2 ABI. The loader deliberately skips incompatible binaries. The
  optional two-finger Files gestures and four-finger media tap need a compatible
  rebuild; the native three/four-finger callbacks are separate.
- The shell log contains Wayland text-input warnings, asynchronous launcher
  delegate/context warnings during panel tests, and one missing network icon
  warning. No startup failure or JavaScript TypeError/ReferenceError was observed.
  The warnings' underlying causes were not established by these tests.
- Sidebar clicks, physical touchpad/key delivery, full screenshot capture,
  suspend/resume, unlocking and reboot/login were not exercised. Wi-Fi scan
  controls were compiled and installed; a live rescan was not triggered.
- Changes remain uncommitted and unpushed. The upstream shell migration is still
  a separate task.
