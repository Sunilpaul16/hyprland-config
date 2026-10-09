#!/usr/bin/env python3
"""Bridge Caelestia's image picker and theme generator to mpvpaper."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import random
import subprocess
import sys

HOME = Path.home()
ROOT = HOME / 'Pictures/Wallpapers'
CACHE = HOME / '.cache/caelestia/video-picker'
STATE = HOME / '.local/state/caelestia/animated-wallpaper.json'
VIDEOS = {'.mp4', '.mkv', '.webm', '.mov', '.m4v'}
IMAGES = {'.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff'}
SERVICE = 'caelestia-wallpaper.service'
GAME_MODE = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'caelestia-wallpaper-game-mode'

def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(value, indent=2) + '\n')
    temp.replace(path)

def sync():
    CACHE.mkdir(parents=True, exist_ok=True)
    mapping = {}
    for source in sorted(ROOT.rglob('*')):
        if not source.is_file() or source.suffix.lower() not in VIDEOS | IMAGES:
            continue
        stat = source.stat()
        digest = hashlib.sha256(f'{source}:{stat.st_size}:{stat.st_mtime_ns}'.encode()).hexdigest()[:12]
        thumb = CACHE / source.relative_to(ROOT).parent / f'{source.stem} [{digest}].jpg'
        thumb.parent.mkdir(parents=True, exist_ok=True)
        if not thumb.exists():
            try:
                seek = []
                if source.suffix.lower() in VIDEOS:
                    probe = run('ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=nw=1:nk=1', str(source), capture_output=True, text=True, timeout=20)
                    seek = ['-ss', str(min(3.0, max(0.0, float(probe.stdout.strip()) / 2)))]
                run('ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *seek, '-i', str(source), '-frames:v', '1', '-vf', 'scale=1920:-2', str(thumb), timeout=60)
            except (subprocess.SubprocessError, ValueError) as error:
                thumb.unlink(missing_ok=True)
                print(f'Cannot create preview for {source.name}: {error}', file=sys.stderr)
                continue
        mapping[str(thumb)] = str(source)
    for thumb in CACHE.rglob('*.jpg'):
        if str(thumb) not in mapping:
            thumb.unlink()
    write_json(CACHE / 'index.json', mapping)
    return mapping

def select(path):
    mapping = json.loads((CACHE / 'index.json').read_text())
    preview = str(Path(path).resolve())
    source = Path(mapping.get(preview, preview))
    if not source.is_file():
        raise ValueError(f'Wallpaper does not exist: {source}')
    if source.suffix.lower() in VIDEOS and preview not in mapping:
        mapping = sync()
        preview = next(key for key, value in mapping.items() if value == str(source))
    run('caelestia', 'wallpaper', '-f', preview)
    write_json(STATE, {'source': str(source), 'preview': preview})
    if not GAME_MODE.exists():
        run('systemctl', '--user', 'restart', SERVICE)

def main():
    action = sys.argv[1]
    if action == 'play':
        if GAME_MODE.exists():
            return
        state = json.loads(STATE.read_text())
        source = Path(state['source'])
        if not source.is_file():
            return
        os.execvp('mpvpaper', ['mpvpaper', '-p', '-a', 'full', '-o', 'no-audio loop-file=inf image-display-duration=inf hwdec=auto panscan=1 terminal=no', 'eDP-1', str(source)])
    CACHE.mkdir(parents=True, exist_ok=True)
    with (CACHE / '.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if action == 'game-sync':
            enabled = subprocess.check_output(['qs', '-c', 'caelestia', 'ipc', 'call', 'gameMode', 'isEnabled'], text=True).strip().lower() in ('true', '1')
            action = 'game-on' if enabled else 'game-off'
        if action == 'game-on':
            GAME_MODE.touch()
            run('systemctl', '--user', 'stop', SERVICE)
        elif action == 'game-off':
            GAME_MODE.unlink(missing_ok=True)
            if STATE.exists():
                run('systemctl', '--user', 'start', SERVICE)
        elif action == 'sync':
            print(f'{len(sync())} wallpaper previews ready')
        elif action == 'picker':
            sync()
            run('qs', '-c', 'caelestia', 'ipc', 'call', 'launcher', 'wallpaper')
        elif action == 'set':
            select(sys.argv[2])
        elif action == 'random':
            mapping = sync()
            if not mapping:
                raise ValueError(f'No supported wallpapers in {ROOT}')
            current = json.loads(STATE.read_text()).get('source') if STATE.exists() else None
            choices = [key for key, value in mapping.items() if value != current] or list(mapping)
            select(random.choice(choices))
        elif action == 'restore':
            sync()
            if STATE.exists() and not GAME_MODE.exists():
                run('systemctl', '--user', 'restart', SERVICE)
        else:
            raise ValueError(f'Unknown action: {action}')

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        subprocess.run(['notify-send', 'Wallpaper', str(error)])
        raise
