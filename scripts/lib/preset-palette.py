#!/usr/bin/env python3
"""Turns a vendored preset .txt into what this repo's pipeline consumes.

Reads matugen/schemes/; emits matugen JSON or the SCSS-shaped stream the kitty
filter eats. No side effects, no writes.
"""

import json
import os
import re
import sys

# Template roles
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

# Kitty colour names
KITTY_NAMES = [f"term{i}" for i in range(16)] + [
    "primary", "primaryContainer", "secondary", "secondaryContainer",
    "onSecondaryContainer", "tertiary", "tertiaryContainer", "error",
    "errorContainer", "onPrimary", "onPrimaryContainer", "onSecondary",
    "onTertiary", "onTertiaryContainer", "onError", "onErrorContainer",
    "outlineVariant",
]


def repo_dir():
    here = os.path.dirname(os.path.realpath(__file__))
    return os.path.normpath(os.path.join(here, "..", ".."))


# Shell role names
def shell_role_sets():
    root = repo_dir()
    paths = {
        "colors.json template": os.path.join(
            root, "matugen", "templates", "colors-json", "colors.json"
        ),
        "Colors.qml": os.path.join(
            root, "quickshell", "shell", "services", "Colors.qml"
        ),
        "ColorsLoader.previewPalette": os.path.join(
            root, "quickshell", "shell", "services", "ColorsLoader.qml"
        ),
    }
    for name, path in paths.items():
        if not os.path.isfile(path):
            sys.exit(f"preset-palette: cannot check, missing {path}")

    with open(paths["colors.json template"]) as f:
        raw = f.read()
    template = set(json.loads(raw))
    # Renamed roles to M3
    referenced = {
        snake_to_camel(m) for m in re.findall(r"\{\{colors\.(\w+)\.", raw)
    }

    # Mutable roles only
    with open(paths["Colors.qml"]) as f:
        qml = set(re.findall(r"^\s*property color (\w+):", f.read(), re.M))

    # applyColors() literal
    with open(paths["ColorsLoader.previewPalette"]) as f:
        body = f.read()
    start = body.find("function previewPalette")
    end = body.find("function ", start + 1)
    loader = set(re.findall(r"^\s*(\w+): palette\.", body[start:end], re.M))

    return {
        "colors.json template": template,
        "Colors.qml": qml,
        "ColorsLoader.previewPalette": loader,
    }, referenced


def check_roles():
    sets, referenced = shell_role_sets()
    every = set().union(*sets.values())
    problems = []
    for role in sorted(every):
        missing = [n for n, s in sets.items() if role not in s]
        if missing:
            problems.append(f"  {role}: missing from {', '.join(missing)}")

    # Unvalidated template roles
    for role in sorted(referenced - set(TEMPLATE_ROLES)):
        problems.append(f"  {role}: rendered by colors.json but not in TEMPLATE_ROLES")

    if problems:
        print("preset-palette: role lists disagree", file=sys.stderr)
        print("\n".join(problems), file=sys.stderr)
        return 1
    print(f"role lists agree ({len(every)} shell roles)")
    return 0


def snake_to_camel(name):
    head, *rest = name.split("_")
    return head + "".join(p.capitalize() for p in rest)


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
    # Vendored in-repo
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
            # Silent fallback
            return want if want in modes else modes[0]
    sys.exit(2)


def read_preset(preset, mode):
    path = os.path.join(corpus_dir(), preset, f"{mode}.txt")
    if not os.path.isfile(path):
        sys.exit(2)
    colours = {}
    # Line-wise read
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            key, _, value = line.partition(" ")
            # Lowered for safety
            colours[key] = value.strip().lower()
    return colours


def require(colours, names, what):
    missing = [n for n in names if n not in colours]
    if missing:
        sys.exit(f"preset-palette: preset missing {what}: {', '.join(missing)}")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: preset-palette.py list|modes|matugen|scss|check ...")
    cmd = sys.argv[1]

    if cmd == "check":
        sys.exit(check_roles())

    if cmd == "list":
        for pid, modes in list_flavours():
            print(f"{pid}\t{' '.join(modes)}")
        return

    # One pass per list
    if cmd == "listall":
        want = sys.argv[2] if len(sys.argv) > 2 else "dark"
        for pid, modes in list_flavours():
            c = read_preset(pid, want if want in modes else modes[0])
            print(f"{pid}\t{' '.join(modes)}\t{c['surface']}\t{c['primary']}\t{c['outline']}")
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
            # One palette, one mode
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
