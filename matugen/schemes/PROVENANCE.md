# Vendored colour schemes

Copied from the `caelestia` Python package, version 1.1.2
(`caelestia/data/schemes/`), upstream <https://github.com/caelestia-dots/cli>.

Licensed **GPL-3.0**; see `LICENSE`. The upstream package ships no per-file
header and names no copyright holder, so none is reproduced here.

## Modifications

Two normalisations applied at copy time, no colour values changed:

- every hex value lowercased (upstream case is inconsistent across and within
  files)
- a trailing newline added where missing (18 of 29 files lacked one, which
  makes a `split("\n")[:-1]` parse silently drop the final key)

Verified after copying: key counts per file identical to upstream.

## Note on the palettes themselves

Several of these (Catppuccin, Gruvbox, Nord, Dracula, Rosé Pine, Tokyo Night,
Everforest, Solarized) originate from separate theme projects with their own
licences. Upstream ships no notices for them and they have not been audited
here.

## Re-syncing

These files are a fork and do not track upstream. New schemes added to
caelestia will not appear here without repeating the copy in
`docs/superpowers/plans/2026-08-01-static-preset-schemes.md`, Task 0.
