#!/usr/bin/env bash

# Shared colour-apply steps

# Paths both entrypoints use
COLORGEN_DIR="$HOME/.config/matugen/colorgen"
CACHE_DIR="$HOME/.cache/matugen"
KITTY_THEME_OUT="$HOME/.config/kitty/theme.conf"
CONFIG_FILE="$HOME/.config/quickshell/config.json"
MODE_FILE="$HOME/.local/state/quickshell/color_mode"
SOURCE_FILE="$HOME/.local/state/quickshell/color_source"

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

# apply_kitty_from_scss <scss-path>
apply_kitty_from_scss() {
    local scss="$1"
    cp "$COLORGEN_DIR/terminal/kitty-theme.conf" "$KITTY_THEME_OUT"
    local name value hexval
    while IFS=: read -r name value; do
        [[ -z "$name" ]] && continue
        hexval="$(echo "$value" | tr -d ' ;')"
        hexval="${hexval#\#}"
        sed -i "s/${name} #/${hexval}/g" "$KITTY_THEME_OUT"
    done < "$scss"

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
    nautilus -q || true
}

reload_all() {
    hyprctl reload >/dev/null
    pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true
}
