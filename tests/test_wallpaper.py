"""Regression tests for the wallpaper bridge, using isolated state and fake services."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(os.environ.get('WALLPAPER_SCRIPT', Path(__file__).resolve().parents[1] / 'caelestia/animated-wallpaper.py'))
spec = importlib.util.spec_from_file_location('wallpaper', SOURCE)
wall = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wall)

class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        for name, value in {'HOME':self.home, 'ROOT':self.home/'Pictures/Wallpapers', 'CACHE':self.home/'cache', 'STATE':self.home/'state/selected.json', 'GAME_MODE':self.home/'game-mode'}.items():
            p = patch.object(wall, name, value); p.start(); self.addCleanup(p.stop)
        wall.ROOT.mkdir(parents=True)
        wall.CACHE.mkdir()
        self.commands = []
        def run(*args, **kwargs):
            self.commands.append(args)
            if args[0] == 'ffmpeg': Path(args[-1]).write_bytes(b'preview')
            return type('Result', (), {'stdout':'10\n'})()
        p = patch.object(wall, 'run', side_effect=run);p.start();self.addCleanup(p.stop)
        p = patch.object(wall.subprocess, 'check_output', return_value='false\n');self.ipc=p.start();self.addCleanup(p.stop)
    def setting(self, static):
        p=self.home/'.config/caelestia/shell.json';p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(json.dumps({'background':{'wallpaperEnabled':static}}))
    def image(self):
        p=self.home/'outside image.png';p.write_bytes(b'image');return p
    def selected(self):
        p=self.image();wall.write_json(wall.STATE,{'source':str(p),'preview':str(p)})
    def main(self, *args):
        with patch.object(sys,'argv',['wallpaper',*args]):wall.main()
    def test_static_is_default(self):self.assertFalse(wall.video_allowed())
    def test_video_requires_static_off_and_game_off(self):
        self.setting(False);self.assertTrue(wall.video_allowed())
        wall.GAME_MODE.touch();self.assertFalse(wall.video_allowed())
    def test_monitor_setting_overrides_global(self):
        self.setting(False);p=self.home/'.config/caelestia/monitors/eDP-1/shell.json';p.parent.mkdir(parents=True)
        p.write_text('{"background":{"wallpaperEnabled":true}}');self.assertFalse(wall.video_allowed())
    def test_select_image_before_first_sync(self):
        self.setting(True);p=self.image();wall.select(str(p))
        self.assertIn(('systemctl','--user','stop',wall.SERVICE),self.commands)
    def test_select_video_outside_wallpaper_directory(self):
        self.setting(True);p=self.home/'outside video.mp4';p.write_bytes(b'video')
        wall.write_json(wall.CACHE/'index.json',{})
        wall.select(str(p))
        self.assertEqual(json.loads(wall.STATE.read_text())['source'],str(p))
        self.assertTrue(Path(json.loads(wall.STATE.read_text())['preview']).exists())
    def test_cached_selection_preserves_source(self):
        self.setting(False);p=wall.ROOT/'clip.mp4';p.write_bytes(b'video')
        mapping=wall.sync();preview=next(iter(mapping));wall.select(preview)
        self.assertEqual(json.loads(wall.STATE.read_text())['source'],str(p))
        self.assertIn(('systemctl','--user','restart',wall.SERVICE),self.commands)
    def test_sync_reuses_frames(self):
        p=wall.ROOT/'clip.mp4';p.write_bytes(b'video');wall.sync();self.commands.clear();wall.sync()
        self.assertFalse(any(c[0]=='ffmpeg' for c in self.commands))
    def test_sync_removes_deleted_previews(self):
        p=wall.ROOT/'clip.mp4';p.write_bytes(b'video');mapping=wall.sync();p.unlink();self.assertEqual(wall.sync(),{})
        self.assertFalse(Path(next(iter(mapping))).exists())
    def test_restore_does_not_restart_hidden_video(self):
        self.setting(True);self.selected();self.main('restore')
        self.assertFalse(any('restart' in c for c in self.commands))
    def test_leaving_game_mode_in_static_mode_stays_stopped(self):
        self.setting(True);self.selected();wall.GAME_MODE.touch();self.main('game-off')
        self.assertFalse(wall.GAME_MODE.exists());self.assertFalse(any('start' in c for c in self.commands))
    def test_game_mode_stops_service(self):
        self.setting(False);self.main('game-on');self.assertTrue(wall.GAME_MODE.exists())
        self.assertIn(('systemctl','--user','stop',wall.SERVICE),self.commands)
    def test_playback_sync_stops_service_when_not_allowed(self):
        self.selected();self.main('playback-sync');self.assertIn(('systemctl','--user','stop',wall.SERVICE),self.commands)
    def test_start_in_static_mode_does_not_launch_mpv(self):
        self.setting(True)
        with patch.object(wall.os,'execvp') as exe:
            self.main('play');exe.assert_not_called()
    def test_missing_selected_video_does_not_restart_forever(self):
        self.setting(False);wall.write_json(wall.STATE,{'source':str(self.home/'missing.mp4')})
        with patch.object(wall.os,'execvp') as exe:
            self.main('play');exe.assert_not_called()
    def test_first_start_without_selection_exits_cleanly(self):
        self.setting(False)
        with patch.object(wall.os,'execvp') as exe:
            self.main('play');exe.assert_not_called()
    def test_external_video_preview_survives_library_refresh(self):
        self.setting(True);p=self.home/'outside.mp4';p.write_bytes(b'video')
        wall.select(str(p));preview=Path(json.loads(wall.STATE.read_text())['preview'])
        wall.sync();self.assertTrue(preview.exists())
    def test_random_avoids_current_video(self):
        self.setting(True)
        for name in ['one.mp4','two.mp4']:(wall.ROOT/name).write_bytes(b'video')
        mapping=wall.sync();wall.select(next(iter(mapping)));previous=json.loads(wall.STATE.read_text())['source']
        self.main('random');self.assertNotEqual(json.loads(wall.STATE.read_text())['source'],previous)

if __name__=='__main__':unittest.main(verbosity=2)
