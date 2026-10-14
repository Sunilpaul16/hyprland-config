# Caelestia laptop setup

Current Arch Linux laptop configuration, saved on the `laptop-caelestia` branch.
This branch replaces the previous custom shell with Caelestia while keeping
personal Kitty, Zsh, keyboard shortcuts and touchpad gestures.

The configuration can also be restored on an Arch desktop after installing the
dependencies and adapting the monitor settings. You do not need to recreate the
terminal setup or shortcuts manually. See [Restore](#restore) and
[Using this on a desktop](#using-this-on-a-desktop).

## What is saved

| Configuration | Files in this branch |
|---|---|
| Zsh, Oh My Zsh settings, Git plugin, Yazi `y` function and completion matching | [`zsh/.zshrc`](zsh/.zshrc), [`.zshenv`](.zshenv) |
| Powerlevel10k prompt and Ctrl+R fuzzy history search | [`zsh/.p10k.zsh`](zsh/.p10k.zsh), [`zsh/fuzzy-history.zsh`](zsh/fuzzy-history.zsh) |
| Kitty appearance, copy/paste, search and font shortcuts | [`kitty/`](kitty/) |
| Personal keyboard shortcuts and application commands | [`caelestia/my-shortcuts.lua`](caelestia/my-shortcuts.lua), [`caelestia/my-shortcut-vars.lua`](caelestia/my-shortcut-vars.lua) |
| Touchpad gestures and scroll settings | [`caelestia/my-gestures.lua`](caelestia/my-gestures.lua), [`caelestia/hypr-vars.lua`](caelestia/hypr-vars.lua), [`inputactions/config.yaml`](inputactions/config.yaml) |
| Monitor layout, keyboard layout and startup hooks | [`caelestia/hypr-user.lua`](caelestia/hypr-user.lua), [`hypr/`](hypr/) |
| Custom Caelestia shell, settings and shortcut cheatsheet | [`quickshell/`](quickshell/), [`caelestia/shell.json`](caelestia/shell.json) |
| Wallpaper playback, screenshot saving and user service files | [`caelestia/`](caelestia/), [`systemd/user/`](systemd/user/) |
| GTK theme settings and CJK font fallback | [`gtk-3.0/`](gtk-3.0/), [`gtk-4.0/`](gtk-4.0/), [`fontconfig/`](fontconfig/) |

Oh My Zsh and the Powerlevel10k theme source are downloaded separately during
restore; their settings are saved here. Shell history, installed applications,
wallpapers and compiled plugins are not bundled.

## Included

- Hyprland Lua configuration: eDP-1, 2560×1600 at 60 Hz, scale 1.25, GB keyboard.
- Caelestia shell 2.5.0 with local QML customizations and its upstream license.
- Invisible 20 × 20 top-right click target toggles the sidebar; replaces sidebar drag/hover triggers.
- Japanese and simplified/traditional Chinese font fallback using Noto CJK fonts.
- App names in the bar; populated special workspaces labelled as scratchpads.
- Manual Wi-Fi scan buttons; routine network updates use cached results.
- Custom cheatsheet with key badges, category icons and system window styling.
- Kitty, Zsh, Powerlevel10k configuration and fuzzy history search.
- Case-insensitive Zsh file/folder completion and a `y` command that returns the
  shell to the directory selected in Yazi.
- Animated wallpapers through mpvpaper, with frame thumbnails and dynamic colours.
- Display wallpaper enabled: show the still image and stop video playback.
  Disabled: play the selected video, unless game mode is enabled.
- Game mode stops playback and shows a still image; leaving game mode restores
  playback only when Display wallpaper remains disabled.
- Night light: Hyprsunset at 5200K from 19:00–07:00, with one on/off switch in Settings → Services.
  Manual toggles last until the next scheduled profile change.
- Autostart overrides hiding duplicate Blueman and NetworkManager tray applets.
- GTK file pickers use the dark `adw-gtk-theme` with Caelestia-generated colours.
- Fullscreen and region screenshots automatically save to `~/Pictures/Screenshots`
  and copy to the clipboard. Region captures save before Swappy opens; editor
  saves update the same file.
- Two-finger sideways swipes in Files navigate folder history: right goes back,
  left goes forward, after lifting fingers. InputActions handles these gestures.

The vendored shell is the installed 2.5.0 configuration with our edits. Compiled
Caelestia plugins and Quickshell are supplied by system packages, not this repo.
The separate development clone was at commit
`5f1c59c0665aad66e94710f67e4bebaeb65c35f4` when this snapshot was taken.

The recorded laptop package snapshot includes Hyprland `0.56.2-4`,
Caelestia shell `2.5.0-1`, Caelestia CLI `1.1.3-1`, Quickshell Git
`0.3.2.r0.g4f508be-1` and Hyprsunset `0.4.0-3`. These are the versions recorded
in [`packages/installed-versions.txt`](packages/installed-versions.txt), not a
claim about the latest upstream releases.

## Restore

The saved defaults target the laptop. On another machine, adapt the settings in
[Using this on a desktop](#using-this-on-a-desktop) before the first Hyprland
login. Hyprland must support the Lua configuration API used by this branch.
An existing desktop setup should be backed up before restoring.

1. Install Arch Linux, networking, Git, Python, `base-devel`, and an AUR helper.
2. Install Hyprland, `caelestia-shell`, `caelestia-cli` and their dependencies.
   This setup uses `quickshell-git`; it conflicts with the stable `quickshell`
   package. The exact installed package versions are recorded under `packages/`.
3. Install `kitty`, `zsh`, `fzf`, `yazi`, `ffmpeg`, `mpvpaper`, `wl-clipboard`,
   `cliphist`, `grim`, `slurp`, `swappy`, `libnotify`, `nautilus`, `brightnessctl`,
   `networkmanager`, `bluez`, `bluez-utils`, `pipewire`, `wireplumber`,
   `pipewire-pulse`, `power-profiles-daemon`, `hypridle`, `hyprlock`,
   `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `gnome-keyring`,
   `polkit-gnome`, `hyprsunset`, `geoclue`, `playerctl`, `uwsm`,
   `ttf-jetbrains-mono-nerd`, `ttf-rubik-vf`, `noto-fonts-cjk`, `adw-gtk-theme`
   and Material Symbols fonts (`ttf-material-symbols-variable-git` in the
   recorded setup). Personal shortcuts expect the commands
   `google-chrome-stable` and `code`, supplied here by the AUR packages
   `google-chrome` and `visual-studio-code-bin`.
   Caelestia's configured explorer is Dolphin; install `dolphin` or change it to
   Nautilus under Settings → Apps. The Super + E shortcut already uses Nautilus.
4. Clone and restore the files:

   ```sh
   git clone --branch laptop-caelestia https://github.com/Sunilpaul16/hyprland-config.git
   cd hyprland-config
   # On a desktop, adapt the files described below before running the installer.
   python3 install.py
   ```

   The installer saves replaced configuration in a timestamped directory under
   `~/.local/state/caelestia-config-backups/`. It installs files, not packages,
   and does not enable system services or change your login shell.
   It copies the files rather than linking them: later edits in this checkout
   do not automatically update `~/.config`.

5. Install Oh My Zsh and Powerlevel10k if missing:

   ```sh
   mkdir -p ~/.config/zsh
   git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.config/zsh/oh-my-zsh
   git clone https://github.com/romkatv/powerlevel10k.git ~/.config/zsh/oh-my-zsh/custom/themes/powerlevel10k
   chsh -s /usr/bin/zsh
   ```

   Skip each clone if that installation already exists. The installer preserves
   an existing `~/.config/zsh/oh-my-zsh` directory. Powerlevel10k loads the saved
   prompt configuration, so the prompt wizard does not need to be repeated.
   Zsh history is stored locally in `~/.local/state/zsh/history` by default.

6. Enable NetworkManager, Bluetooth and power-profiles-daemon as appropriate.
   Log into Hyprland using UWSM so user services receive the Wayland environment.
   The Hyprland startup hook starts Caelestia and `hyprsunset.service`.
   Wallpaper playback is managed by the supplied user service and script.
7. Put your own videos or images in `~/Pictures/Wallpapers`, then run:

   ```sh
   caelestia scheme set -n dynamic
   python3 ~/.config/caelestia/animated-wallpaper.py random
   ```

   Video frames are generated once and cached. New files appear when opening the
   wallpaper picker or choosing a random wallpaper. The original videos remain
   in your Pictures folder. The selected wallpaper restores on the next login.

8. If using the optional two-finger Files gestures, build and load InputActions
   using [Files touchpad gestures](#files-touchpad-gestures). This is separate
   from the native three- and four-finger gestures.

## Using this on a desktop

Keep the Zsh, Kitty, shortcuts and shell customizations. Adapt these hardware
and application settings in the checkout before running `install.py`, or in
`~/.config` after restoring:

1. Find the desktop output names with `hyprctl monitors` in a running Hyprland
   session, such as `DP-1` or `HDMI-A-1`. In
   [`caelestia/hypr-user.lua`](caelestia/hypr-user.lua), replace `eDP-1` in the
   monitor, workspace and cursor settings; adjust resolution, refresh rate,
   position and scale. Add monitor declarations for additional screens. Review
   the laptop's 1000 × 700 file-dialog size rule too.
2. In [`caelestia/animated-wallpaper.py`](caelestia/animated-wallpaper.py), replace
   `eDP-1` in both the per-monitor settings path and the `mpvpaper` output.
   Move or copy `caelestia/monitors/eDP-1/shell.json` into a directory named for
   that output. The current wallpaper helper targets one output; it does not
   automatically configure independent animated wallpapers on multiple screens.
3. Change `kb_layout = "gb"` in `caelestia/hypr-user.lua` if needed. Copilot and
   AltGr + Copilot bindings assume the laptop's key events. Super + S and
   Super + Alt + S provide scratchpad controls on a keyboard without Copilot.
4. Change application commands in `caelestia/my-shortcut-vars.lua` and
   `caelestia/hypr-vars.lua` if using another browser, editor or file manager.
   Review Caelestia's app choices separately under Settings → Apps.
5. Skip the optional Files gesture plugin if the desktop has no touchpad.
   The loader skips an absent build. Brightness keys and power-profile controls
   depend on hardware support; enable Bluetooth only if the machine uses it.

Your wallpapers, credentials, browser profiles and personal files must be
transferred separately. This branch restores desktop preferences; it is not
a complete operating-system image.

## Main shortcuts

| Shortcut | Action |
|---|---|
| Super + \` | Kitty terminal |
| Super + E | Nautilus file manager |
| Super + W | Chrome |
| Super + C | VS Code |
| Super + Space | App launcher |
| Super + V | Clipboard history |
| Super + / | Cheatsheet |
| Super + I | Settings |
| Super + D | Dashboard |
| Super + T | Wallpaper picker |
| Super + Shift + T | Random wallpaper |
| Super + B | Toggle bar |
| Super + Q | Close window |
| Super + F | Toggle fullscreen |
| Super + Alt + Space | Toggle floating |
| Super + arrow keys | Focus window |
| Super + 1–9 / 0 | Switch to workspace 1–9 / 10 |
| Super + Shift + 1–9 / 0 | Move window to workspace 1–9 / 10 |
| Super + S | Toggle scratchpad |
| Super + Alt + S | Move window to scratchpad |
| Copilot | Toggle scratchpad |
| AltGr + Copilot | Move app into/out of scratchpad |
| Print / Super + Shift + S | Save focused-monitor screenshot and copy it |
| Shift + Print / Super + Ctrl + Shift + S | Region screenshot, save/copy, then edit in Swappy |
| Super + Alt + R | Toggle region recording |
| Super + Alt + Shift + R | Toggle fullscreen recording |
| Super + L | Lock |
| Super + Ctrl + R | Restart Caelestia |
| Super + Ctrl + Alt + R | Reload Hyprland configuration |
| Three fingers left/right | Sequential workspaces, including empty ones |
| Three fingers up | Toggle the main scratchpad |
| Three fingers down | Toggle the active scratchpad, or the main one if none is active |
| Four fingers up/down | Enter/leave fullscreen |
| Four fingers left/right | Next/previous populated scratchpad |
| Two fingers right/left in Files | Back/forward history; requires InputActions |

Personal keyboard bindings are loaded from `caelestia/my-shortcuts.lua`, with
key combinations and app commands in `caelestia/my-shortcut-vars.lua`. Native
gestures are in `caelestia/my-gestures.lua`. The cheatsheet intentionally shows a
smaller selection, omitting media and recording groups. Touchpad scroll factor
is 0.8.

In Kitty, Ctrl+C copies selected text or interrupts the command, Ctrl+V pastes,
Ctrl+F searches the terminal, Ctrl+plus/minus changes font size and Ctrl+0 resets
it. In Zsh, Ctrl+R searches command history with fzf; `y` opens Yazi and changes
the shell's working directory to the directory selected on exit.

## Files touchpad gestures

`inputactions/config.yaml` restricts two-finger horizontal swipes to
`org.gnome.Nautilus` with no keyboard modifiers held. The threshold is 70;
increase it for a longer swipe or decrease it for a shorter one. Other apps
and the existing three- and four-finger gestures keep their normal behavior.

The plugin is installed per user under `~/.local/share/inputactions/hyprland/`.
Its loader compares the running Hyprland ABI against the build metadata and
skips loading if Hyprland has changed. Compiled binaries are not included here.
The current build was tested with Hyprland 0.56.2 and InputActions source commit
`78f97531e8d86d32aafbaa7fa0b7fc205829271f`.

After restoring the configuration, build the plugin while logged into Hyprland:

```sh
python3 scripts/build-files-gestures.py
python3 ~/.config/caelestia/load-files-gestures.py
```

Build prerequisites include `base-devel`, `cmake`, `git`, `curl`, `libarchive`,
`pkgconf`, `qt6-declarative`, `libevdev`, and the installed Hyprland headers and
development dependencies. The build script downloads `extra-cmake-modules` and
`yaml-cpp` from the configured Arch repositories, verifies their package hashes,
and unpacks them temporarily without a system-wide installation. It fetches the
pinned upstream InputActions source and builds against the running compositor.
After a Hyprland upgrade, rebuilding may require updating the InputActions pin
if the upstream compositor API has changed.

To disable immediately (and before rebuilding a loaded plugin):

```sh
hyprctl plugin unload "$(python3 -c 'import json,pathlib; print(json.loads((pathlib.Path.home()/".local/share/inputactions/hyprland/build.json").read_text())["plugin"])')"
```

To disable across logins, remove the `load-files-gestures.py` startup command
from `caelestia/hypr-user.lua`. Configuration changes reload automatically.

## Excluded

No wallpaper videos, profile photo, credentials, browser data, shell history,
notifications, screenshots or runtime state are included. Hibernate is not
configured. Package inventories document this machine; they are not an
instruction to install every listed application.

After restoring, verify startup, locking, suspend/resume, brightness and game
mode on the target machine. Restoring on a fresh system has not been tested.

## Regression checks

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
lua tests/test_shortcuts.lua "$PWD/caelestia"
node tests/test_bar_and_scratchpads.js
```

Python checks isolate state in temporary directories and mock service commands.
The Lua checks exercise callbacks without sending keys to the live desktop.
See [`TEST-REPORT.md`](TEST-REPORT.md) for the dated live audit and remaining
physical-device checks. It describes the state at that audit; screenshot saving,
night light and Files gesture changes were added in later commits.

`python3 tests/live_wallpaper.py` exercises the running desktop: it temporarily
changes Display wallpaper and game mode, restarts the shell, and restores those
preferences in a `finally` block. Run it only while logged into this Hyprland
session and after saving work in settings dialogs.
