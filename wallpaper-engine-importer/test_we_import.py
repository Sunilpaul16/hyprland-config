import json
import struct
import tempfile
import unittest
from pathlib import Path

import we_import


class ImporterTests(unittest.TestCase):
    def test_read_project_normalizes_type(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "123"
            root.mkdir()
            (root / "movie.mp4").write_bytes(b"video")
            (root / "project.json").write_text(json.dumps({
                "type": "Video", "title": "A/B: C", "file": "movie.mp4"
            }))
            project = we_import.read_project(root / "project.json")
            self.assertEqual(project.kind, "video")
            self.assertEqual(project.workshop_id, "123")

    def test_safe_child_rejects_escape(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "123"
            root.mkdir()
            outside = Path(temp) / "outside.mp4"
            outside.write_bytes(b"video")
            with self.assertRaises(we_import.ImportFailure):
                we_import.safe_child(root, "../outside.mp4")

    def test_scene_uses_packed_workshop_entry(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "456"
            root.mkdir()
            (root / "scene.pkg").write_bytes(b"packed")
            (root / "project.json").write_text(json.dumps({
                "type": "scene", "title": "Packed", "file": "scene.json"
            }))
            project = we_import.read_project(root / "project.json")
            self.assertEqual(project.entry, (root / "scene.pkg").resolve())

    def test_scene_accepts_legacy_package_name(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "789"
            root.mkdir()
            (root / "gifscene.pkg").write_bytes(b"packed")
            (root / "project.json").write_text(json.dumps({
                "type": "scene", "title": "Legacy", "file": "gifscene.json"
            }))
            project = we_import.read_project(root / "project.json")
            self.assertEqual(project.entry, (root / "gifscene.pkg").resolve())

    def test_scene_compatibility_catches_child_particles(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "999"
            root.mkdir()
            payload = json.dumps({"children": [{"type": "eventfollow"}]}).encode()
            name = b"particles/parent.json"
            package = (
                struct.pack("<I", 4) + b"PKGV" + struct.pack("<I", 1)
                + struct.pack("<I", len(name)) + name
                + struct.pack("<II", 0, len(payload)) + payload
            )
            scene = root / "scene.pkg"
            scene.write_bytes(package)
            project = we_import.Project("999", "scene", "Children", scene, root, None)
            issues = we_import.scene_compatibility(project)
            self.assertEqual(len(issues), 1)
            self.assertIn("eventfollow", issues[0])

    def test_output_name_is_flat_and_identifiable(self):
        project = we_import.Project("42", "video", "A/B: C", Path("x"), Path("."), None)
        self.assertEqual(
            we_import.output_path(project, Path("out")).name,
            "WE - A B C [42].mp4",
        )


if __name__ == "__main__":
    unittest.main()
