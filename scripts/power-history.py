#!/usr/bin/env python3
"""Local battery and app CPU history. No browser tabs or command lines are stored."""
import argparse
from collections import defaultdict
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import time

STATE = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'quickshell'
DB = STATE / 'power-history.sqlite3'
KEEP = 30 * 86400
NAMES = {'chrome': 'Chrome', 'qs': 'Desktop shell', 'mpvpaper': 'Animated wallpaper',
         'Hyprland': 'Hyprland', 'codex': 'Codex', 'kitty': 'Terminal', 'nautilus': 'Files'}


def connect(path=DB):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    conn = sqlite3.connect(path, timeout=10)
    conn.execute('PRAGMA journal_mode=WAL')
    conn.executescript('''
        CREATE TABLE IF NOT EXISTS battery (ts INTEGER, kind TEXT, value REAL, state INTEGER,
            PRIMARY KEY (ts, kind));
        CREATE TABLE IF NOT EXISTS samples (ts INTEGER PRIMARY KEY, span REAL, status TEXT,
            profile TEXT, energy_wh REAL, drained_wh REAL, apps TEXT);
        CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT);
    ''')
    os.chmod(path, 0o600)
    return conn


def meta(conn, key, default=None):
    row = conn.execute('SELECT value FROM metadata WHERE key=?', (key,)).fetchone()
    return json.loads(row[0]) if row else default


def set_meta(conn, key, value):
    conn.execute('INSERT OR REPLACE INTO metadata VALUES (?,?)', (key, json.dumps(value)))


def command(args):
    return subprocess.check_output(args, text=True, timeout=10).strip()


def import_upower(conn, now):
    if now - meta(conn, 'upower_imported', 0) < 86400:
        return
    try:
        devices = command(['upower', '-e']).splitlines()
        device = next(d for d in devices if '/battery_' in d)
        for kind in ('charge', 'rate'):
            result = json.loads(command(['busctl', '--json=short', 'call',
                'org.freedesktop.UPower', device, 'org.freedesktop.UPower.Device',
                'GetHistory', 'suu', kind, str(KEEP), '10000']))
            rows = [(int(ts), kind, float(value), int(state))
                    for ts, value, state in result['data'][0] if now - KEEP <= ts <= now]
            conn.executemany('INSERT OR IGNORE INTO battery VALUES (?,?,?,?)', sorted(rows, key=lambda row: row[3] == 0))
        set_meta(conn, 'upower_imported', now)
    except (subprocess.SubprocessError, OSError, ValueError, StopIteration, KeyError, TypeError) as exc:
        print('power-history: could not import UPower history: ' + str(exc), file=__import__('sys').stderr)


def process_snapshot(proc=Path('/proc')):
    result = {}
    hz = os.sysconf('SC_CLK_TCK')
    for path in proc.iterdir():
        if not path.name.isdigit():
            continue
        try:
            if path.stat().st_uid != os.getuid():
                continue
            stat = (path / 'stat').read_text()
            close = stat.rfind(')')
            name = stat[stat.find('(') + 1:close]
            fields = stat[close + 2:].split()
            result[path.name + ':' + fields[19]] = [NAMES.get(name, name),
                (int(fields[11]) + int(fields[12])) / hz]
        except (OSError, ValueError, IndexError):
            continue
    return result


def battery_read(base=Path('/sys/class/power_supply')):
    for path in base.iterdir():
        try:
            values = dict(line.split('=', 1) for line in (path / 'uevent').read_text().splitlines() if '=' in line)
            if values.get('POWER_SUPPLY_TYPE') != 'Battery':
                continue
            def number(key):
                value = values.get('POWER_SUPPLY_' + key)
                return float(value) if value is not None else None
            energy = number('ENERGY_NOW')
            if energy is None and number('CHARGE_NOW') is not None and number('VOLTAGE_NOW') is not None:
                energy = number('CHARGE_NOW') * number('VOLTAGE_NOW') / 1e6
            power = number('POWER_NOW')
            if power is None and number('CURRENT_NOW') is not None and number('VOLTAGE_NOW') is not None:
                power = abs(number('CURRENT_NOW')) * number('VOLTAGE_NOW') / 1e6
            return {'status': values.get('POWER_SUPPLY_STATUS', 'Unknown'),
                'percent': number('CAPACITY'), 'energy': energy / 1e6 if energy is not None else None,
                'watts': abs(power) / 1e6 if power is not None else None}
        except (OSError, ValueError):
            continue
    return {'status': 'Unavailable', 'percent': None, 'energy': None, 'watts': None}


def cpu_delta(before, after):
    apps = defaultdict(float)
    for key, (name, seconds) in after.items():
        if key in before:
            apps[name] += max(0, seconds - before[key][1])
    return {name: round(value, 4) for name, value in apps.items() if value > 0}


def sample(conn):
    now = int(time.time())
    monotonic = time.monotonic()
    boot = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    previous = meta(conn, 'previous', {})
    processes = process_snapshot()
    battery = battery_read()
    span = monotonic - previous.get('monotonic', monotonic)
    valid = (previous.get('boot') == boot and 0 < span <= 90
             and abs(now - previous.get('ts', now) - span) < 5)
    apps = cpu_delta(previous.get('processes', {}), processes) if valid else {}
    drained = None
    if (valid and battery['status'] == previous.get('status') == 'Discharging'
            and battery['energy'] is not None and previous.get('energy') is not None):
        drained = max(0, previous['energy'] - battery['energy'])
    try:
        profile = command(['powerprofilesctl', 'get'])
    except (OSError, subprocess.SubprocessError):
        profile = 'unknown'
    conn.execute('INSERT OR REPLACE INTO samples VALUES (?,?,?,?,?,?,?)',
        (now, span if valid else 0, battery['status'], profile, battery['energy'], drained, json.dumps(apps)))
    state = {'Charging': 1, 'Discharging': 2, 'Full': 4, 'Not charging': 3}.get(battery['status'], 0)
    for kind, value in [('charge', battery['percent']), ('rate', battery['watts'])]:
        if value is not None:
            conn.execute('INSERT OR REPLACE INTO battery VALUES (?,?,?,?)', (now, kind, value, state))
    set_meta(conn, 'previous', dict(ts=now, monotonic=monotonic, boot=boot,
        processes=processes, status=battery['status'], energy=battery['energy']))
    import_upower(conn, now)
    conn.execute('DELETE FROM battery WHERE ts < ?', (now - KEEP,))
    conn.execute('DELETE FROM samples WHERE ts < ?', (now - KEEP,))
    conn.commit()


def report(conn, hours):
    now = int(time.time())
    cutoff = now - int(hours * 3600)
    apps = defaultdict(float)
    coverage = 0
    drain = 0
    for span, drained, values in conn.execute('SELECT span,drained_wh,apps FROM samples WHERE ts >= ?', (cutoff,)):
        coverage += span
        drain += drained or 0
        for name, seconds in json.loads(values).items():
            apps[name] += seconds
    def points(kind):
        rows = list(conn.execute('SELECT ts,value,state FROM battery WHERE kind=? AND ts>=? ORDER BY ts', (kind, cutoff)))
        # Bucket long histories without smoothing away peaks or state changes.
        if len(rows) > 600:
            bucket = max(1, int(hours * 3600 / 300))
            selected = []
            group = []
            last_key = None
            for row in rows:
                key = (row[0] // bucket, row[2])
                if group and key != last_key:
                    selected.extend(sorted(set([group[0], min(group,key=lambda x:x[1]), max(group,key=lambda x:x[1]), group[-1]])))
                    group = []
                group.append(row)
                last_key = key
            selected.extend(sorted(set([group[0], min(group,key=lambda x:x[1]), max(group,key=lambda x:x[1]), group[-1]])))
            rows = selected
        return [dict(ts=ts, value=value, state=state) for ts,value,state in rows]
    previous = meta(conn, 'previous', {})
    return dict(now=now, start=cutoff, charge=points('charge'), rate=points('rate'),
        apps=[dict(name=name, seconds=round(seconds,1), cpu=round(seconds/coverage*100,1) if coverage else 0)
              for name,seconds in sorted(apps.items(),key=lambda x:x[1],reverse=True)[:10]],
        coverage=coverage, drained_wh=round(drain,2), last_sample=previous.get('ts',0),
        current=battery_read())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['sample', 'report'])
    parser.add_argument('--hours', type=float, default=24)
    parser.add_argument('--database', type=Path, default=DB)
    args = parser.parse_args()
    with connect(args.database) as conn:
        if args.action == 'sample':
            sample(conn)
        else:
            print(json.dumps(report(conn, max(1,min(720,args.hours)))))

if __name__ == '__main__':
    main()
