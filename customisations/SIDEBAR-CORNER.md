# Restored sidebar corner click — 2026-11-10

The 20×20 logical-pixel top-right click target is restored and live. Left-click
once to open the sidebar and again to close it. Hover-to-open is disabled using
the upstream preference; native sidebar drag and shortcut controls remain.
The target is disabled for fullscreen windows or a disabled sidebar.

`shell/components/SidebarHotspot.qml` and `SidebarRegion.qml` hold the custom
implementation. Two integration hooks are tracked by the `sidebar-corner`
feature patch. The archived originals remain unchanged; active source uses
separate copies and does not link into the archive.

Validation: click, right-click, disabled-target, outside-target and resize tests
passed using QtTest; all 287 QML files compiled; the live shell restarted without
JavaScript errors and its sidebar open/close round trip passed. All four live
component/integration files match the source. Physical pointer delivery at the
screen corner was not injected into the desktop.

Previous files/preferences were backed up under:

```text
~/.local/state/caelestia-config-backups/sidebar-corner-20261110-115205-553182/
```
