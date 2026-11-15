import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('custom_shell', str(REPO / 'scripts/custom-shell'))
spec = importlib.util.spec_from_loader(loader.name, loader)
shell = importlib.util.module_from_spec(spec)
loader.exec_module(shell)


class CompositionTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        shutil.copytree(REPO / 'customs', self.root / 'customs')
        for name, value in {'ROOT': self.root, 'CUSTOMS': self.root / 'customs',
                            'GENERATED': self.root / 'generated'}.items():
            mock = patch.object(shell, name, value)
            mock.start()
            self.addCleanup(mock.stop)

    def test_default_uses_native_wallpapers_and_custom_scratchpads(self):
        shell.prepare('custom')
        output = self.root / 'generated'
        self.assertEqual((output / 'caelestia/services/Wallpapers.qml').read_bytes(),
                         (shell.UPSTREAM / 'services/Wallpapers.qml').read_bytes())
        self.assertIn('scratchpadNames', (output / 'caelestia/services/Hypr.qml').read_text())
        self.assertIn('caelestia wallpaper -r', (output / 'files/caelestia/my-shortcuts.lua').read_text())
        self.assertNotIn('animated-wallpaper.py restore', (output / 'files/caelestia/hypr-user.lua').read_text())
        self.assertTrue(json.loads((output / 'files/caelestia/shell.json').read_text())['background']['wallpaperEnabled'])

    def test_upstream_mode_matches_every_source_file(self):
        shell.prepare('upstream')
        output = self.root / 'generated/caelestia'
        original = {p.relative_to(shell.UPSTREAM): p.read_bytes() for p in shell.UPSTREAM.rglob('*') if p.is_file()}
        actual = {p.relative_to(output): p.read_bytes() for p in output.rglob('*') if p.is_file()}
        self.assertEqual(original, actual)
        hardware = (self.root / 'generated/files/caelestia/hypr-user.lua').read_text()
        self.assertIn('DP-3', hardware)
        self.assertNotIn('my-shortcuts', hardware)
        self.assertIn('hyprland.keybinds', hardware)

    def test_all_optional_features_still_apply(self):
        config = self.root / 'customs/features.json'
        config.write_text(json.dumps({name: True for name in json.loads(config.read_text())}))
        shell.prepare('custom')
        self.assertIn('pickerDir', (self.root / 'generated/caelestia/services/Wallpapers.qml').read_text())

    def test_disabled_scratchpads_use_standard_hyprland_command(self):
        config = self.root / 'customs/features.json'
        features = json.loads(config.read_text())
        features['scratchpads'] = False
        config.write_text(json.dumps(features))
        shell.prepare('custom')
        for name in ('my-shortcuts.lua', 'my-gestures.lua'):
            text = (self.root / 'generated/files/caelestia' / name).read_text()
            self.assertNotIn('hypr toggleLastSpecialWorkspace', text)
            self.assertNotIn('hypr openLastSpecialWorkspace', text)
            self.assertIn('hyprctl dispatch togglespecialworkspace magic', text)

    def test_conflict_preserves_previous_generated_profile(self):
        output = self.root / 'generated'
        output.mkdir()
        (output / 'keep').write_text('previous working profile')
        config = self.root / 'customs/patches/scratchpads.patch'
        config.write_text(config.read_text().replace('readonly property var toplevels: Hyprland.toplevels',
                                                    'THIS UPSTREAM CONTEXT NO LONGER EXISTS'))
        with self.assertRaises(subprocess.CalledProcessError):
            shell.prepare('custom')
        self.assertEqual((output / 'keep').read_text(), 'previous working profile')


if __name__ == '__main__':
    unittest.main()
