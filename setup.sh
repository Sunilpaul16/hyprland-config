#!/usr/bin/env bash

set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
VENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
OMZ_DIR="$HOME/.config/zsh/oh-my-zsh"
P10K_DIR="$OMZ_DIR/custom/themes/powerlevel10k"

green=''
yellow=''
red=''
reset=''
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    green='\033[32m'
    yellow='\033[33m'
    red='\033[31m'
    reset='\033[0m'
fi

mark_ok() { printf "${green}[x]${reset} %s\n" "$1"; }
mark_warn() { printf "${yellow}[!]${reset} %s\n" "$1"; }
mark_missing() { printf "${red}[ ]${reset} %s\n" "$1"; }

read_package_file() {
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

missing_packages() {
    command -v pacman >/dev/null 2>&1 || return 0
    mapfile -t packages < <(
        read_package_file "$ROOT/packages/arch.txt"
        read_package_file "$ROOT/packages/aur.txt"
    )
    pacman -T "${packages[@]}" 2>/dev/null || true
}

link_is_current() {
    [[ -L "$2" ]] && [[ "$(readlink -f "$2" 2>/dev/null || true)" == "$(readlink -f "$1")" ]]
}

links_ready() {
    link_is_current "$ROOT/hypr" "$HOME/.config/hypr" &&
        link_is_current "$ROOT/quickshell" "$HOME/.config/quickshell" &&
        link_is_current "$ROOT/zsh/.zshrc" "$HOME/.config/zsh/.zshrc" &&
        link_is_current "$ROOT/scripts/switchwall" "$HOME/.local/bin/switchwall"
}

python_ready() {
    [[ -x "$VENV/bin/python3" ]] && "$VENV/bin/python3" -c 'import PIL, materialyoucolor' >/dev/null 2>&1
}

frameworks_ready() {
    [[ -f "$OMZ_DIR/oh-my-zsh.sh" && -f "$P10K_DIR/powerlevel10k.zsh-theme" ]]
}

wallpaper_count() {
    if [[ -d "$HOME/wallpaper" ]]; then
        find "$HOME/wallpaper" -maxdepth 1 -type f | wc -l
    else
        printf '0\n'
    fi
}

theme_ready() {
    [[ -s "$HOME/.config/hypr/hyprlock/colors.conf" &&
        -s "$HOME/.config/hypr/colors.lua" &&
        -s "$HOME/.config/kitty/theme.conf" ]]
}

service_enabled() {
    systemctl is-enabled "$1" >/dev/null 2>&1
}

show_status() {
    local missing current_shell count current_wallpaper
    printf '\nInstallation checklist\n\n'

    if command -v pacman >/dev/null 2>&1; then
        missing="$(missing_packages)"
        if [[ -z "$missing" ]]; then
            mark_ok "Declared Arch and AUR packages"
        else
            mark_missing "Packages: $(tr '\n' ' ' <<<"$missing")"
        fi
    else
        mark_missing "Arch Linux package manager"
    fi

    command -v yay >/dev/null 2>&1 && mark_ok "AUR helper (yay)" || mark_missing "AUR helper (yay)"
    links_ready && mark_ok "Repository links" || mark_missing "Repository links"
    python_ready && mark_ok "Python colour environment" || mark_missing "Python colour environment"
    frameworks_ready && mark_ok "Oh My Zsh and Powerlevel10k" || mark_missing "Oh My Zsh and Powerlevel10k"

    if [[ -s "$ROOT/hypr/general.lua" && -s "$ROOT/hypr/touchpad.lua" ]]; then
        mark_ok "Repository-owned laptop monitor, keyboard and touchpad settings"
    else
        mark_missing "Repository laptop hardware settings"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        service_enabled NetworkManager.service && mark_ok "NetworkManager enabled" || mark_missing "NetworkManager enabled"
        service_enabled bluetooth.service && mark_ok "Bluetooth enabled" || mark_warn "Bluetooth not enabled"
    fi

    current_shell="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7 || true)"
    [[ "$current_shell" == "$(command -v zsh 2>/dev/null || true)" ]] && mark_ok "Zsh login shell" || mark_warn "Login shell is ${current_shell:-unknown}"

    count="$(wallpaper_count)"
    (( count > 0 )) && mark_ok "$count wallpaper(s) in ~/wallpaper" || mark_missing "At least one wallpaper in ~/wallpaper"

    current_wallpaper="$HOME/.local/state/quickshell/current_wallpaper"
    if [[ -s "$current_wallpaper" ]] && [[ -f "$(<"$current_wallpaper")" ]]; then
        mark_ok "Initial wallpaper selected"
    else
        mark_warn "Initial wallpaper not selected"
    fi

    theme_ready && mark_ok "Initial Kitty and lock-screen themes" || mark_missing "Initial generated or seed themes"

    if git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet &&
        [[ -z "$(git -C "$ROOT" ls-files --others --exclude-standard)" ]]; then
        mark_ok "Git worktree clean"
    else
        mark_warn "Git worktree has local changes"
    fi
    printf '\n'
}

confirm() {
    local prompt="$1" default="${2:-yes}" answer suffix
    [[ "$default" == yes ]] && suffix='[Y/n]' || suffix='[y/N]'
    read -r -p "$prompt $suffix " answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

install_frameworks() {
    mkdir -p "$HOME/.config/zsh"
    if [[ ! -f "$OMZ_DIR/oh-my-zsh.sh" ]]; then
        if [[ -e "$OMZ_DIR" ]]; then
            printf 'setup: %s exists but is not a complete Oh My Zsh checkout\n' "$OMZ_DIR" >&2
            return 1
        fi
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
    fi
    if [[ ! -f "$P10K_DIR/powerlevel10k.zsh-theme" ]]; then
        if [[ -e "$P10K_DIR" ]]; then
            printf 'setup: %s exists but is not a complete Powerlevel10k checkout\n' "$P10K_DIR" >&2
            return 1
        fi
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    fi
}

choose_wallpaper() {
    local first answer
    first="$(find "$HOME/wallpaper" -maxdepth 1 -type f 2>/dev/null | sort | head -1)"
    [[ -n "$first" ]] || {
        printf 'Add images or videos to ~/wallpaper, then run: switchwall /path/to/wallpaper\n'
        return
    }
    if ! hyprctl monitors -j >/dev/null 2>&1; then
        printf 'Wallpaper selection is deferred until Hyprland is running. Then run:\n  switchwall %q\n' "$first"
        return
    fi
    read -r -p "Initial wallpaper [$first]: " answer
    "$HOME/.local/bin/switchwall" "${answer:-$first}"
}

run_wizard() {
    local current_wallpaper=""
    [[ -t 0 ]] || { printf 'setup: the wizard needs an interactive terminal\n' >&2; exit 1; }
    command -v pacman >/dev/null 2>&1 || {
        printf 'setup: this wizard currently supports Arch Linux only\n' >&2
        exit 1
    }
    printf '\nHyprland setup wizard\n'
    show_status

    if [[ -n "$(missing_packages)" ]]; then
        if confirm 'Install all declared packages?'; then
            command -v yay >/dev/null 2>&1 || { printf 'Install yay first, then rerun the wizard.\n' >&2; exit 1; }
            "$ROOT/install.sh" --packages
        fi
    fi

    if ! links_ready && confirm 'Create repository links and seed first-login themes?'; then
        "$ROOT/install.sh" --link
    fi
    if ! python_ready && confirm 'Create the Python colour environment?'; then
        "$ROOT/install.sh" --python
    fi
    if ! frameworks_ready && confirm 'Clone Oh My Zsh and Powerlevel10k?'; then
        install_frameworks
    fi
    printf 'Laptop hardware settings are tracked in hypr/general.lua and hypr/touchpad.lua.\n'
    printf 'Edit those files to change monitor, keyboard or touchpad settings.\n'

    if command -v systemctl >/dev/null 2>&1; then
        if ! service_enabled NetworkManager.service && confirm 'Enable NetworkManager now?'; then
            sudo systemctl enable --now NetworkManager.service
        fi
        if ! service_enabled bluetooth.service && confirm 'Enable Bluetooth now?'; then
            sudo systemctl enable --now bluetooth.service
        fi
    fi

    if [[ "$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)" != "$(command -v zsh 2>/dev/null || true)" ]]; then
        if confirm 'Make Zsh the login shell?'; then
            chsh -s "$(command -v zsh)"
        fi
    fi

    if [[ -s "$HOME/.local/state/quickshell/current_wallpaper" ]]; then
        current_wallpaper="$(<"$HOME/.local/state/quickshell/current_wallpaper")"
    fi
    if [[ ! -f "$current_wallpaper" ]]; then
        if confirm 'Select an initial wallpaper now?'; then
            choose_wallpaper
        fi
    fi

    "$ROOT/scripts/check-config"
    show_status
    printf 'Setup pass complete. Items still marked [ ] or [!] need attention.\n'
}

case "${1:-}" in
    --status) show_status ;;
    -h|--help)
        printf 'Usage: ./setup.sh [--status]\n\nRun without arguments for the interactive setup wizard.\n'
        ;;
    '') run_wizard ;;
    *) printf 'setup: unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
