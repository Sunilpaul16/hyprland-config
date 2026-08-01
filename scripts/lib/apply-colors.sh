#!/usr/bin/env bash

# Shared colour-apply steps. Sourced by switchwall and setscheme so both
# reach every themed app by one implementation. Expects the caller to have
# set CONFIG_FILE, COLORGEN_DIR and KITTY_THEME_OUT.

# cfg <jq-path> <default> — missing file, missing key or null all fall back
cfg() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# cfgbool <jq-path> <default> — booleans cannot go through cfg: jq's `//`
# treats a literal `false` as absent, so `false` would read back as the
# default. Only null/missing falls back here.
cfgbool() {
    local value=""
    if [[ -s "$CONFIG_FILE" ]]; then
        value="$(jq -r "$1 | if . == null then empty else . end" "$CONFIG_FILE" 2>/dev/null || true)"
    fi
    [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "$2"
}

# apply_kitty_from_scss <scss-path> — rewrites the kitty theme from a stream
# of `$name: #RRGGBB;` lines. Generator-agnostic: matugen's materialyoucolor
# pass and a static preset both feed it the same shape.
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

    # Terminal window transparency. dynamic_background_opacity is what lets
    # kitty pick this up on SIGUSR1 instead of needing a restart
    local opacity
    opacity="$(cfg '.theming.terminalOpacity' '1.0')"
    {
        echo ""
        echo "# Written by switchwall from theming.terminalOpacity"
        echo "dynamic_background_opacity yes"
        echo "background_opacity $opacity"
    } >> "$KITTY_THEME_OUT"
}

# apply_gsettings <light|dark> — GTK4 renders the wrong @media block without this
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
