# Hyprland configuration

Personal Arch Linux desktop configuration built around Hyprland's Lua config,
Quickshell, Matugen, Kitty, and Zsh. It includes a bar, launcher, notification
daemon, dashboard, workspace overview, lock/idle handling, wallpaper theming,
screen capture, recording, clipboard history, and session controls.

The checked-in defaults describe a two-monitor NVIDIA desktop. Review the
machine-specific settings before using them elsewhere.

## Fresh-install checklist

- [ ] Boot Arch Linux with a regular user that has `sudo` access.
- [ ] Get networking online and install `git`, `base-devel`, and `yay`.
- [ ] Install the GPU driver appropriate for the machine.
- [ ] Clone this repository over HTTPS or SSH.
- [ ] Run `./setup.sh` and complete the guided steps.
- [ ] Review the detected monitor layout and keyboard layout.
- [ ] Put at least one image or video in `~/wallpaper`.
- [ ] Select the Hyprland/UWSM session, then choose the initial wallpaper.
- [ ] Run `./setup.sh --status`; resolve anything still marked `[ ]` or `[!]`.

Private runtime data is not part of this checklist. Shell history, notification
history, notes, app usage, current wallpaper state, and the machine profile stay
under `~/.local/state` and are not committed.

## Guided setup

Clone the repository anywhere under your home directory and start the wizard:

```bash
git clone https://github.com/Sunilpaul16/hyprland-config.git
cd hyprland-config
./setup.sh
```

The wizard is resumable: it detects completed steps and only offers missing
ones. It can install declared packages, create links, seed first-login themes,
create the Python environment, clone Oh My Zsh and Powerlevel10k, write an
untracked monitor/keyboard profile, enable NetworkManager and Bluetooth, change
the login shell, select a wallpaper when Hyprland is running, and validate the
result.

At any point, display the non-mutating checklist with:

```bash
./setup.sh --status
```

The hardware profile is written to
`~/.local/state/hyprland-config/machine.lua`. It overrides the repository's
DP-2/DP-3 fallback without changing tracked files.

## Non-interactive install

The lower-level installer remains available for scripted or selective setup:

```bash
./install.sh --help
./install.sh --check
```

On Arch Linux, a complete setup is:

```bash
./install.sh --packages
./install.sh --link --python
./install.sh --check
```

`--packages` uses `pacman` for [repository packages](packages/arch.txt) and
`yay` for [AUR packages](packages/aur.txt). Install an appropriate GPU driver
separately; the package list deliberately does not guess the machine's GPU.

`--link` creates individual links under `~/.config`, `~/.local/bin`, and the Zsh
locations. Existing destinations are moved to timestamped directories under
`~/.local/state/hyprland-config/backups`; they are never silently overwritten.
It also creates the wallpaper, screenshot, and recording directories. Neutral
Kitty, Hyprland, and Hyprlock colours are seeded if live Matugen output does not
exist, keeping the first login usable before a wallpaper is selected.

`--python` creates `~/.local/state/quickshell/.venv` from
[requirements.txt](requirements.txt). The wallpaper colour pipeline expects
that exact environment.

After linking, select the Hyprland/UWSM session. Hyprland starts `hypridle` and
the `quickshell.service` user unit from `hypr/execs.lua`; the service is
intentionally not enabled independently.

NetworkManager and Bluetooth are system services rather than dotfiles. Enable
the ones used on the machine separately, for example:

```bash
sudo systemctl enable --now NetworkManager bluetooth
```

## Personalise

- Monitor names, positions, workspaces, keyboard layout: rerun the wizard after
  moving or removing `~/.local/state/hyprland-config/machine.lua`
- Programs and key bindings: `hypr/variables.lua`
- Window rules: `hypr/rules.lua`
- Shell behaviour and appearance: `quickshell/config.json` or `Super+I`
- Wallpapers: `~/wallpaper`

`quickshell/config.json` and Matugen's generated outputs are ignored because
they are live per-user state. The templates that produce them remain tracked.
The Matugen configuration also writes a local Vencord theme when Vencord is
installed; Vencord itself is not installed by the bootstrap script.

The weather service uses configured coordinates when present. With empty
coordinates it requests IP-based location from `ipinfo.io`, then fetches the
forecast from Open-Meteo. Media cover art may also be downloaded by the shell.

## Validation

Run:

```bash
./scripts/check-config
```

This checks Bash, Zsh, Python, JSON, theme-role consistency, QML when `qmllint`
is available, ShellCheck when installed, and whitespace errors.

## Hyprland notes

Tearing has its master switch enabled, but Hyprland also requires an
`immediate = true` window rule for each game that should tear. No broad rule is
included because applying experimental tearing to the wrong client can cause
graphics problems.

Hyprland's optional compositor permission enforcement is not enabled. If it is
enabled, add explicit screencopy rules for the trusted capture tools,
Quickshell, and `xdg-desktop-portal-hyprland`, then restart Hyprland; permission
rules are intentionally not reloadable.

## Credits and licensing

The preset colour corpus has its own provenance and licensing notes in
`matugen/schemes/`. No repository-wide licence has been selected yet.
