# Wallpaper Engine importer

`we-import` converts locally downloaded Wallpaper Engine Workshop items into
ordinary MP4 files. The converted files work with this configuration's existing
`mpvpaper`, thumbnail, framing, game-mode, and Matugen pipeline.

It never modifies Steam Workshop content and deliberately skips application
wallpapers.

## Supported inputs

- **Video:** copied losslessly when already MP4, otherwise remuxed.
- **Web:** loaded locally in sandboxed headless Chrome and captured to H.264 MP4.
  Bubblewrap hides the user's files; browser network requests are blocked.
- **Scene:** rendered by a `linux-wallpaperengine` build configured with
  `-DDEMOMODE=1`, then transcoded from its WebM export to MP4. A preflight
  rejects known-incompatible child-particle scenes instead of producing an
  incomplete video.
- **Application:** unsupported and skipped.

Wallpaper Engine must be installed through Steam because scene projects rely on
its shared assets. A normal Steam location is detected automatically.

## Usage

```bash
./we-import scan
./we-import import 1907587142
./we-import import 1286183699 --duration 10 --fps 30 --width 1920 --height 1080
./build-scene-renderer
./we-import import 1425503532 --duration 10
```

The scene build is large because upstream links Chromium Embedded Framework.
`build-scene-renderer` keeps its source, dependencies, and roughly 1.5 GB runtime
under the ignored `.runtime/` directory. On Arch it downloads missing build-only
libraries locally, without `sudo`.

Outputs are written to `output/` and tracked in `manifest.json`. Override Steam
discovery with `WE_STEAM_ROOT` or `WE_WORKSHOP_DIR`; override the Wallpaper
Engine asset location with `WE_ASSETS_DIR`.

Web and scene exports are recordings. They preserve visible animation but not
mouse interaction, live audio response, or a clock that continues to show the
current time after conversion.
