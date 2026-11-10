# Notification ownership fix — 2026-11-10

Dunst owned `org.freedesktop.Notifications` and reported that it was using its
default configuration. Caelestia logged a registration conflict, so notifications
went to Dunst's plain boxes instead of Caelestia's popup/history model. Do Not
Disturb was off.

An early Files-gestures warning was present in Dunst's history. Its startup
loader runs before the shell is necessarily ready and could activate Dunst via
D-Bus. The saved InputActions build does not match the running Hyprland ABI.

## Applied changes

- `dunst.service` is masked and stopped for this user. The system package remains
  installed; the user mask prevents automatic D-Bus/systemd activation.
- `customisations/standalone/links.json` records this service mask, and the
  configuration installer reapplies it on restore.
- The standalone gesture loader waits up to ten seconds for the notification
  D-Bus owner PID to match a running Caelestia instance before sending its warning.
  If the shell never becomes ready, it writes the warning to stderr rather than
  activating another notification daemon.

No upstream QML files were modified for this fix. The previous Dunst history and
gesture loader were backed up under:

```text
~/.local/state/caelestia-config-backups/notifications-20261110-114145-979526/
```

The Dunst history export is private to the user and was not imported into the
shell. Future notifications now reach Caelestia.

## Verified

- The notification server identifies as Quickshell and its D-Bus owner PID matches
  the active Caelestia process.
- A screenshot of the notification area confirmed the custom Caelestia popup.
- A test entry remained in the shell history after its popup expired.
- A startup-style shell restart preserved history and notification ownership.
- The deferred gesture warning reached the restarted shell's history, along with
  a new test notification. Dunst remained masked and inactive.
- The restarted shell log had no notification registration conflict,
  ReferenceError or TypeError.
- All 24 Python tests passed, including readiness/ownership and installer-mask
  regression checks.

The gesture plugin itself still needs a compatible rebuild. This fix prevents
its warning from taking over notifications; it does not load an incompatible
plugin. A full reboot after the fix has not been tested.
