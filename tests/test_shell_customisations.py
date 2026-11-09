import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CUSTOM = ROOT / "customisations/shell"


class ShellCustomisationsTests(unittest.TestCase):
    def test_feature_patches_reconstruct_all_custom_sources(self):
        manifest = json.loads((CUSTOM / "manifest.json").read_text())
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            shutil.copytree(CUSTOM / "base", output, dirs_exist_ok=True)
            for patch in sorted((CUSTOM / "patches").glob("*.patch")):
                subprocess.run(["git", "apply", str(patch)], cwd=output,
                               capture_output=True, text=True, check=True)
            for entry in manifest["files"]:
                with self.subTest(path=entry["path"]):
                    self.assertEqual((output / entry["path"]).read_bytes(),
                                     (CUSTOM / entry["source"]).read_bytes())


if __name__ == "__main__":
    unittest.main()
