#!/usr/bin/env python3
"""Turns a vendored preset .txt into what this repo's pipeline consumes.

Reads matugen/schemes/; emits matugen JSON or the SCSS-shaped stream the kitty
filter eats. No side effects, no writes.
"""

import json
import os
import sys

# Roles the six matugen templates reference. A missing one renders a literal
# {{colors.x.default.hex}} into a live config, so this is validated up front.
TEMPLATE_ROLES = [
    "background", "error", "errorContainer", "inverseOnSurface", "inversePrimary",
    "inverseSurface", "onBackground", "onError", "onErrorContainer", "onPrimary",
    "onPrimaryContainer", "onPrimaryFixed", "onSecondaryContainer", "onSurface",
    "onSurfaceVariant", "outline", "outlineVariant", "primary", "primaryContainer",
    "primaryFixed", "primaryFixedDim", "secondary", "secondaryContainer",
    "secondaryFixedDim", "surface", "surfaceContainer", "surfaceContainerHigh",
    "surfaceContainerHighest", "surfaceContainerLow", "surfaceContainerLowest",
    "surfaceVariant", "tertiary", "tertiaryContainer", "tertiaryFixedDim",
]

# Names kitty-theme.conf substitutes. Unsupplied ones survive as literal
# `$primary` text that kitty refuses to parse, so all 33 are required.
KITTY_NAMES = [f"term{i}" for i in range(16)] + [
    "primary", "primaryContainer", "secondary", "secondaryContainer",
    "onSecondaryContainer", "tertiary", "tertiaryContainer", "error",
    "errorContainer", "onPrimary", "onPrimaryContainer", "onSecondary",
    "onTertiary", "onTertiaryContainer", "onError", "onErrorContainer",
    "outlineVariant",
]


def camel_to_snake(name):
    out = []
    for ch in name:
        if ch.isupper():
            out.append("_")
            out.append(ch.lower())
        else:
            out.append(ch)
    return "".join(out)


def corpus_dir():
    # Vendored in-repo. Resolved from this file's real path, since the
    # entrypoint is reached through a symlink in ~/.local/bin
    here = os.path.dirname(os.path.realpath(__file__))
    path = os.path.normpath(os.path.join(here, "..", "..", "matugen", "schemes"))
    if not os.path.isdir(path):
        sys.exit(f"preset-palette: scheme corpus missing at {path}")
    return path


def list_flavours():
    root = corpus_dir()
    rows = []
    for scheme in sorted(os.listdir(root)):
        sdir = os.path.join(root, scheme)
        if not os.path.isdir(sdir):
            continue
        for flavour in sorted(os.listdir(sdir)):
            fdir = os.path.join(sdir, flavour)
            if not os.path.isdir(fdir):
                continue
            modes = sorted(
                os.path.splitext(f)[0] for f in os.listdir(fdir) if f.endswith(".txt")
            )
            if modes:
                rows.append((f"{scheme}/{flavour}", modes))
    return rows


def resolve_mode(preset, want):
    for pid, modes in list_flavours():
        if pid == preset:
            # Silent fallback: 17 of 24 flavours are dark-only
            return want if want in modes else modes[0]
    sys.exit(2)


def read_preset(preset, mode):
    path = os.path.join(corpus_dir(), preset, f"{mode}.txt")
    if not os.path.isfile(path):
        sys.exit(2)
    colours = {}
    # Line-wise: a split("\n")[:-1] read drops the last key from any file
    # without a trailing newline, which upstream had in 18 of 29
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            key, _, value = line.partition(" ")
            # Normalised at vendor time; lowered again so a hand-edit is safe
            colours[key] = value.strip().lower()
    return colours


def require(colours, names, what):
    missing = [n for n in names if n not in colours]
    if missing:
        sys.exit(f"preset-palette: preset missing {what}: {', '.join(missing)}")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: preset-palette.py list|modes|matugen|scss ...")
    cmd = sys.argv[1]

    if cmd == "list":
        for pid, modes in list_flavours():
            print(f"{pid}\t{' '.join(modes)}")
        return

    if cmd == "modes":
        for pid, modes in list_flavours():
            if pid == sys.argv[2]:
                print(" ".join(modes))
                return
        sys.exit(2)

    preset, want = sys.argv[2], sys.argv[3]
    mode = resolve_mode(preset, want)
    colours = read_preset(preset, mode)

    if cmd == "matugen":
        require(colours, TEMPLATE_ROLES, "template roles")
        out = {}
        for role in TEMPLATE_ROLES:
            value = "#" + colours[role]
            # One palette drives all three variants; a preset has one mode
            out[camel_to_snake(role)] = {
                "default": {"color": value},
                "light": {"color": value},
                "dark": {"color": value},
            }
        json.dump({"colors": out}, sys.stdout)
        return

    if cmd == "scss":
        require(colours, KITTY_NAMES, "kitty names")
        for name in KITTY_NAMES:
            print(f"${name}: #{colours[name]};")
        return

    sys.exit(f"preset-palette: unknown command {cmd}")


if __name__ == "__main__":
    main()
