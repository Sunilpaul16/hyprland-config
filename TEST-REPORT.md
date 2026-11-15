# Setup regression audit — 2026-10-09

The live laptop configuration and the `laptop-caelestia` checkout were audited.
Corrections are applied to the live configuration and copied into this checkout.
This audit has not been committed or pushed.

## Bugs reproduced and fixed

1. **First-use wallpaper Browse failed without a cache index.** Selecting an
   image now works before the first library scan.
2. **Videos outside Pictures/Wallpapers failed to select.** Frame generation now
   accepts external files and keeps their previews outside the library cleanup
   directory, so a subsequent refresh does not delete the selected frame.
3. **Settings could show an empty Local wallpapers grid.** The settings pages
   still compared preview paths with Pictures/Wallpapers. They now use the
   preview directory and hide cache hashes in displayed names.
4. **Game mode could be lost on shell restart and restart video playback.**
   Game mode now restores its session flag before scheduling playback or
   applying compositor options. This failed in the live test before the fix and
   passed after it.
5. **Scratchpad numbers and next/previous order could disagree.** The bar and
   cycling controller now share one ordered list of populated special
   workspaces. A test with deliberately shuffled workspace creation order
   reproduced the mismatch and passed after the fix.

The previously fixed hidden-video issue was also retested: enabling Display
wallpaper shows the still image and stops mpvpaper, including when selecting
another wallpaper, leaving game mode, or restoring the session.

## Automated regression checks

- 21 Python tests passed: wallpaper selection/cache handling, static/video/game
  gates, random selection, startup, bar settings and isolated restore/backups.
- 35 Lua checks passed: workspace bindings, screenshot commands, Copilot move
  callbacks, zoom bounds and gesture callback behavior.
- 8 JavaScript checks passed: application-name fallback, empty desktop,
  single/multiple scratchpad labels, and next/previous scratchpad ordering.
- All 22 live Lua config files parsed; Zsh configuration and the cheatsheet
  launcher passed syntax checks. JSON configs parsed successfully.
- The Kitty search helper imported successfully inside Kitty's Python runtime.

Run the isolated tests:

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
lua tests/test_shortcuts.lua "$PWD/caelestia"
node tests/test_bar_and_scratchpads.js
```

## Live checks

| Area | Result and limit |
|---|---|
| Hyprland | No config errors; 73 registered bindings, no duplicate key/modifier registrations. |
| Display/input | eDP-1 2560×1600, approximately 60 Hz, scale 1.25; touchpad scroll factor 0.8 and relative swipe mode enabled. |
| Static/video/game mode | All five tested state transitions passed; static mode remained stopped after selecting a wallpaper; game mode survived a shell restart without launching video. Original preferences restored. |
| Wi-Fi | An isolated copy of both live network pages logged zero rescan requests on entry and beyond the former 15-second interval. Explicit scan produced one request. Routine list queries used `--rescan no`. Network connection was not disabled or changed. |
| Wallpaper Settings | Grid loaded all five cached wallpapers; screenshot inspection confirmed visible thumbnails and readable filenames without hashes. |
| Cheatsheet | Loaded without QML errors; open/close/reopen toggles passed. Removed groups and Shell-to-System move verified in regenerated data. |
| Bar | Live hide/show setting round-trip passed and original visibility restored. |
| Screenshot | Fullscreen command produced a valid 2560×1600 PNG in cache and identical image on clipboard. Explicit tiny-region capture launched Swappy, as the CLI is designed to do. Clipboard restored and audit captures/editor removed. Physical Print/Copilot events were not injected. |
| Brightness | Shell brightness value agreed with brightnessctl hardware value. Physical brightness keys were not pressed. |
| Services | NetworkManager, Bluetooth, power profiles, PipeWire, WirePlumber and pipewire-pulse active. No duplicate Blueman/nm-applet or Dunst process found. Caelestia owned notifications. |
| Lock/idle | Lock IPC available; native idle monitors configured in Caelestia, so a separate hypridle process is not required. CanSuspend reported yes. CanHibernate reported unavailable; reviewed upstream code falls back to suspend. No lock/suspend was triggered. |
| Restore | Isolated temporary HOME test passed: old configs backed up, third-party Oh My Zsh preserved, cheatsheet regenerated, portable `%h` wallpaper unit installed. Fresh OS installation not tested. |

## Remaining checks and observations

- Actual touchpad motion, physical Copilot/AltGr/Print/media keys, locking and
  authenticating, lid-close suspend/resume, and reboot/login need hands-on
  verification. Callback tests do not prove hardware event delivery.
- The live tests restarted Caelestia, not the whole laptop. Default-session
  startup on a fresh machine remains unverified.
- Caelestia CLI emits `Unable to create /etc/opt/chrome/policies/managed directory`
  during theme application. Core dynamic colours and wallpaper selection work;
  its optional Chrome managed-policy integration is not configured. No system
  policy files were changed.
- Quickshell emitted occasional Wayland text-input focus warnings when test
  windows opened/closed; no corresponding QML exceptions or failed UI actions
  were observed.
- Hibernate is still not configured. Animated playback still has the previously
  measured power cost when explicitly enabled; static mode now runs no video
  process.

`tests/live_wallpaper.py` repeats the live wallpaper/game-mode matrix, temporarily
changes those preferences, restarts the shell, and restores preferences in a
finally block. It is excluded from unittest discovery because it controls the
running desktop.
