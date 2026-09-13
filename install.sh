#!/usr/bin/env bash

set -euo pipefail

ROOT="$(dirname "$(readlink -f "$0")")"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-config"
VENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"

do_packages=false
do_links=false
do_python=false
do_check=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  --packages  Install Arch and AUR packages (requires sudo and yay)
  --link      Link the repository into the home directory
  --python    Create/update the wallpaper colour-generator virtualenv
  --check     Run repository validation and report missing packages
  --all       Run packages, link, Python setup, and checks
  -h, --help  Show this help

Existing destinations are moved under ~/.local/state/hyprland-config/backups/
before links are created. Nothing is silently overwritten.
EOF
}

while (($#)); do
    case "$1" in
        --packages) do_packages=true ;;
        --link) do_links=true ;;
        --python) do_python=true ;;
        --check) do_check=true ;;
        --all) do_packages=true; do_links=true; do_python=true; do_check=true ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'install: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if ! $do_packages && ! $do_links && ! $do_python && ! $do_check; then
    usage
    exit 0
fi

read_package_file() {
    local file="$1"
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

install_packages() {
    command -v pacman >/dev/null || {
        printf 'install: --packages currently supports Arch Linux only\n' >&2
        exit 1
    }

    mapfile -t repo_packages < <(read_package_file "$ROOT/packages/arch.txt")
    sudo pacman -S --needed -- "${repo_packages[@]}"

    command -v yay >/dev/null || {
        printf 'install: yay is required for packages/aur.txt; install an AUR helper and retry\n' >&2
        exit 1
    }
    mapfile -t aur_packages < <(read_package_file "$ROOT/packages/aur.txt")
    yay -S --needed -- "${aur_packages[@]}"
}

backup_root=""

link_one() {
    local source="$1" destination="$2" resolved_source resolved_destination relative backup
    resolved_source="$(readlink -f "$source")"

    if [[ -L "$destination" ]]; then
        resolved_destination="$(readlink -f "$destination" 2>/dev/null || true)"
        if [[ "$resolved_destination" == "$resolved_source" ]]; then
            printf 'current %s\n' "$destination"
            return
        fi
    fi

    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ -z "$backup_root" ]]; then
            mkdir -p "$STATE_ROOT/backups"
            backup_root="$(mktemp -d "$STATE_ROOT/backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
        fi
        relative="${destination#"$HOME"/}"
        backup="$backup_root/$relative"
        mkdir -p "$(dirname "$backup")"
        mv -- "$destination" "$backup"
        printf 'backup  %s -> %s\n' "$destination" "$backup"
    fi

    mkdir -p "$(dirname "$destination")"
    ln -s "$resolved_source" "$destination"
    printf 'linked  %s -> %s\n' "$destination" "$resolved_source"
}

install_links() {
    local entry source destination
    local -a links=(
        '.zshenv|.zshenv'
        'btop/btop.conf|.config/btop/btop.conf'
        'chrome-flags.conf|.config/chrome-flags.conf'
        'code-flags.conf|.config/code-flags.conf'
        'fastfetch|.config/fastfetch'
        'gtk-3.0|.config/gtk-3.0'
        'gtk-4.0|.config/gtk-4.0'
        'hypr|.config/hypr'
        'kitty|.config/kitty'
        'matugen|.config/matugen'
        'quickshell|.config/quickshell'
        'systemd/quickshell.service|.config/systemd/user/quickshell.service'
        'zsh/.p10k.zsh|.config/zsh/.p10k.zsh'
        'zsh/.zshrc|.config/zsh/.zshrc'
        'zsh/fuzzy-history.zsh|.config/zsh/fuzzy-history.zsh'
        'scripts/check-config|.local/bin/check-hypr-config'
        'scripts/ocr|.local/bin/ocr'
        'scripts/record|.local/bin/record'
        'scripts/screenshot|.local/bin/screenshot'
        'scripts/setscheme|.local/bin/setscheme'
        'scripts/switchwall|.local/bin/switchwall'
    )

    for entry in "${links[@]}"; do
        source="$ROOT/${entry%%|*}"
        destination="$HOME/${entry#*|}"
        link_one "$source" "$destination"
    done

    mkdir -p "$HOME/wallpaper" "$HOME/Pictures/Screenshots" "$HOME/Videos"
    if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
        systemctl --user daemon-reload
    else
        printf 'deferred systemctl --user daemon-reload (no user manager available)\n'
    fi
}

install_python() {
    command -v python3 >/dev/null || {
        printf 'install: python3 is required for --python\n' >&2
        exit 1
    }
    if [[ ! -x "$VENV/bin/python3" ]]; then
        python3 -m venv "$VENV"
    fi
    "$VENV/bin/python3" -m pip install --upgrade pip
    "$VENV/bin/python3" -m pip install -r "$ROOT/requirements.txt"
}

check_packages() {
    if command -v pacman >/dev/null 2>&1; then
        mapfile -t all_packages < <(
            read_package_file "$ROOT/packages/arch.txt"
            read_package_file "$ROOT/packages/aur.txt"
        )
        missing="$(pacman -T "${all_packages[@]}" || true)"
        if [[ -n "$missing" ]]; then
            printf 'Missing packages:\n%s\n' "$missing" >&2
            return 1
        fi
        printf 'All declared packages are installed.\n'
    else
        printf 'Package check skipped: pacman is unavailable.\n'
    fi

    if [[ -x "$VENV/bin/python3" ]] && "$VENV/bin/python3" -c 'import PIL, materialyoucolor' 2>/dev/null; then
        printf 'Python colour-generator environment is ready.\n'
    else
        printf 'Python colour-generator environment is missing; run ./install.sh --python.\n' >&2
        return 1
    fi
}

$do_packages && install_packages
$do_links && install_links
$do_python && install_python
if $do_check; then
    check_packages
    "$ROOT/scripts/check-config"
fi

if [[ -n "$backup_root" ]]; then
    printf '\nPrevious files were preserved in %s\n' "$backup_root"
fi
