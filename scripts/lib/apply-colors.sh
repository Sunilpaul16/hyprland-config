#!/usr/bin/env bash

# Shared colour-apply steps

# Paths both entrypoints use
COLORGEN_DIR="$HOME/.config/matugen/colorgen"
CACHE_DIR="$HOME/.cache/matugen"
WALLPAPER_CACHE_DIR="$CACHE_DIR/wallpapers"
KITTY_THEME_OUT="$HOME/.config/kitty/theme.conf"
CONFIG_FILE="$HOME/.config/quickshell/config.json"
MODE_FILE="$HOME/.local/state/quickshell/color_mode"
SOURCE_FILE="$HOME/.local/state/quickshell/color_source"
LUM_FILE="$HOME/.local/state/quickshell/wallpaper_luminance"

# Serialize generated-theme writers. Each caller publishes a token before
# waiting; once it owns the lock it exits if a newer request superseded it.
begin_latest_theme() {
    local token_file="$CACHE_DIR/theme-request"
    THEME_REQUEST_TOKEN="$$-${RANDOM}-$(date +%s%N)"
    mkdir -p "$CACHE_DIR"
    printf '%s' "$THEME_REQUEST_TOKEN" > "$token_file.part.$$"
    mv "$token_file.part.$$" "$token_file"
    exec 9>"$CACHE_DIR/theme.lock"
    flock 9
    [[ "$(cat "$token_file" 2>/dev/null)" == "$THEME_REQUEST_TOKEN" ]]
}

theme_is_latest() {
    [[ "$(cat "$CACHE_DIR/theme-request" 2>/dev/null)" == "$THEME_REQUEST_TOKEN" ]]
}

# cfg <jq-path> <default>
cfg() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# cfgbool <jq-path> <default>
cfgbool() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 | if . == null then empty else . end" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# wall_cache <wallpaper> — per-file dir, keyed by contents
wall_cache() {
    local hash
    hash="$(sha256sum "$1" | cut -d' ' -f1)" || return 1
    printf '%s/%s' "$WALLPAPER_CACHE_DIR" "$hash"
}

# apply_kitty_from_scss <scss-path>
apply_kitty_from_scss() {
    local scss="$1"
    awk '
        NR == FNR {
            if (match($0, /^\$([^:]+):[[:space:]]*#([[:xdigit:]]+);/, parts))
                color[parts[1]] = parts[2]
            next
        }
        {
            for (name in color)
                gsub("#\\$" name " #", "#" color[name])
            print
        }
    ' "$scss" "$COLORGEN_DIR/terminal/kitty-theme.conf" > "$KITTY_THEME_OUT"

    # Window transparency
    local opacity
    opacity="$(cfg '.theming.terminalOpacity' '1.0')"
    {
        echo ""
        echo "# Written by switchwall from theming.terminalOpacity"
        echo "dynamic_background_opacity yes"
        echo "background_opacity $opacity"
    } >> "$KITTY_THEME_OUT"
}

# apply_gsettings <light|dark>
apply_gsettings() {
    if [[ "$1" == light ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
    if pgrep -x nautilus >/dev/null; then
        nautilus -q || true
    fi
}

# apply_qt <light|dark>
apply_qt() {
    local mode="$1" enabled icon
    enabled="$(cfgbool '.theming.qt' 'true')"

    # Match whatever GTK already uses
    icon="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'\"")"
    [[ -n "$icon" ]] || icon="$([[ "$mode" == light ]] && echo Papirus-Light || echo Papirus-Dark)"

    local ct dir conf palette
    for ct in qt6ct qt5ct; do
        dir="$HOME/.config/$ct"
        conf="$dir/$ct.conf"
        palette="$dir/colors/matugen.conf"
        [[ -f "$palette" ]] || continue
        mkdir -p "$dir"

        if [[ ! -f "$conf" ]]; then
            printf '[Appearance]\n' > "$conf"
        fi
        # Section may be absent
        grep -q '^\[Appearance\]' "$conf" || printf '\n[Appearance]\n' >> "$conf"

        qt_set "$conf" custom_palette "$([[ "$enabled" == true ]] && echo true || echo false)"
        qt_set "$conf" color_scheme_path "$palette"
        qt_set "$conf" style Fusion
        qt_set "$conf" icon_theme "$icon"
    done
}

# qt_set <file> <key> <value>
qt_set() {
    local file="$1" key="$2" value="$3"
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        sed -i "0,/^\[Appearance\]/s||[Appearance]\n${key}=${value}|" "$file"
    fi
}

reload_all() {
    hyprctl reload >/dev/null
    pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true
}
