#!/usr/bin/env python3
"""Pass Wi-Fi credentials to nmcli over stdin rather than process arguments."""
import json
import os
import subprocess
import sys


def main():
    try:
        request = json.load(sys.stdin)
        password = request.get('password', '')
        if '\n' in password or '\r' in password:
            raise ValueError('Password must be a single line')
        command = ['nmcli', '--ask', '--wait', '30', 'device', 'wifi', 'connect',
                   request['bssid'], 'ifname', request['interface']]
        result = subprocess.run(command, input=password + '\n' if password else '',
                                text=True, capture_output=True, timeout=40,
                                env={**os.environ, 'LC_ALL': 'C'})
        if result.returncode:
            print('Could not connect. Check the password or use the connection editor.', file=sys.stderr)
        return result.returncode
    except (ValueError, KeyError, OSError, subprocess.TimeoutExpired):
        print('Could not connect. Check NetworkManager and try again.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
