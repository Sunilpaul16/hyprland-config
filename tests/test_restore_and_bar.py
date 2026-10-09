import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO=Path(__file__).resolve().parents[1]
BAR=Path(os.environ.get('BAR_SCRIPT',REPO/'caelestia/toggle-bar.py'))

class BarTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.home=Path(self.temp.name);self.cfg=self.home/'.config/caelestia/shell.json';self.cfg.parent.mkdir(parents=True)
    def toggle(self, transient='0'):
        with patch.object(Path,'home',return_value=self.home),patch('subprocess.run') as run:
            run.return_value.stdout=transient
            runpy.run_path(str(BAR))
            return run
    def test_toggle_preserves_unrelated_settings(self):
        self.cfg.write_text('{"background":{"wallpaperEnabled":true},"bar":{"persistent":true}}')
        self.toggle();data=json.loads(self.cfg.read_text())
        self.assertFalse(data['bar']['persistent']);self.assertTrue(data['background']['wallpaperEnabled'])
        self.toggle();self.assertTrue(json.loads(self.cfg.read_text())['bar']['persistent'])
    def test_hiding_clears_temporary_reveal(self):
        self.cfg.write_text('{"bar":{"persistent":true}}');run=self.toggle('1')
        self.assertIn('toggle',run.call_args.args[0]);self.assertFalse(json.loads(self.cfg.read_text())['bar']['showOnHover'])
    def test_fresh_config_uses_default_visible(self):
        self.toggle();self.assertFalse(json.loads(self.cfg.read_text())['bar']['persistent'])

class RestoreTests(unittest.TestCase):
    def test_restore_backs_up_old_setup_and_preserves_zsh(self):
        with tempfile.TemporaryDirectory() as td:
            home=Path(td);bin_dir=home/'bin';bin_dir.mkdir()
            fake=bin_dir/'systemctl';fake.write_text('#!/bin/sh\nexit 0\n');fake.chmod(0o755)
            old=home/'.config/hypr';old.mkdir(parents=True);(old/'old.conf').write_text('old setup')
            third=home/'.config/zsh/oh-my-zsh';third.mkdir(parents=True);(third/'keep').write_text('third-party')
            env={**os.environ,'HOME':str(home),'PATH':str(bin_dir)+':'+os.environ['PATH']}
            subprocess.run(['python3',str(REPO/'install.py')],env=env,capture_output=True,text=True,check=True)
            self.assertFalse((old/'old.conf').exists())
            self.assertTrue(list((home/'.local/state/caelestia-config-backups').glob('*/.config/hypr/old.conf')))
            self.assertEqual((third/'keep').read_text(),'third-party')
            data=json.loads((home/'.config/quickshell/caelestia-cheatsheet/data.json').read_text())
            titles={g['title'] for g in data}
            self.assertTrue({'Workspace','Window','System','Kitty'}<=titles)
            self.assertFalse({'Record','Media','Help','Shell','Inactive · unassigned'} & titles)
            system=next(g for g in data if g['title']=='System')
            self.assertTrue(any(row['key']=='Super + B' for row in system['rows']))
            self.assertIn('%h/',(home/'.config/systemd/user/caelestia-wallpaper.service').read_text())

if __name__=='__main__':unittest.main(verbosity=2)
