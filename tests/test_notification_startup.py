import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / 'caelestia/load-files-gestures.py'
spec = importlib.util.spec_from_file_location('gesture_loader', SOURCE)
loader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loader)


class NotificationStartupTests(unittest.TestCase):
    def test_waits_until_caelestia_owns_notifications(self):
        results = [
            subprocess.CompletedProcess([], 0, '[{"pid":1234}]'),
            subprocess.CompletedProcess([], 0, 'u 5678\n'),
            subprocess.CompletedProcess([], 0, '[{"pid":1234}]'),
            subprocess.CompletedProcess([], 0, 'u 1234\n'),
            subprocess.CompletedProcess([], 0),
        ]
        with patch.object(loader.subprocess, 'run', side_effect=results) as run, patch.object(loader.time, 'sleep') as sleep:
            loader.notify_when_shell_ready('Rebuild needed')
        sleep.assert_called_once_with(0.2)
        calls = [call.args[0] for call in run.call_args_list]
        self.assertEqual([call for call in calls if call[0] == 'notify-send'],
                         [['notify-send', 'Files gestures', 'Rebuild needed']])
        self.assertEqual(calls[-2][-2:], ['s', 'org.freedesktop.Notifications'])

    def test_missing_shell_does_not_activate_another_notification_daemon(self):
        with patch.object(loader.time, 'monotonic', side_effect=[0, 11]), patch.object(loader.subprocess, 'run') as run, patch.object(loader.sys, 'stderr') as stderr:
            loader.notify_when_shell_ready('Rebuild needed')
        run.assert_not_called()
        self.assertTrue(stderr.write.called)


if __name__ == '__main__':
    unittest.main()
