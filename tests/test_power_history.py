import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('power_history', Path(__file__).parent.parent/'scripts/power-history.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class HistoryChecks(unittest.TestCase):
    def test_pid_reuse_and_cpu_grouping(self):
        before={'1:100':['Chrome',10], '2:200':['Chrome',4], '3:300':['Files',20]}
        after={'1:100':['Chrome',12], '2:200':['Chrome',5], '3:301':['Files',25]}
        self.assertEqual(m.cpu_delta(before,after), {'Chrome':3})

    def test_charge_current_fallback_units(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'BAT0'; p.mkdir()
            (p/'uevent').write_text('POWER_SUPPLY_TYPE=Battery\nPOWER_SUPPLY_STATUS=Discharging\nPOWER_SUPPLY_CAPACITY=50\nPOWER_SUPPLY_CHARGE_NOW=2000000\nPOWER_SUPPLY_CURRENT_NOW=-1000000\nPOWER_SUPPLY_VOLTAGE_NOW=12000000\n')
            battery=m.battery_read(Path(folder))
            self.assertEqual(battery['energy'],24)
            self.assertEqual(battery['watts'],12)

    def test_suspend_does_not_attribute_cpu_or_energy(self):
        with tempfile.TemporaryDirectory() as folder, m.connect(Path(folder)/'db') as conn:
            boot=Path('/proc/sys/kernel/random/boot_id').read_text().strip()
            m.set_meta(conn,'previous',dict(ts=100, monotonic=10,boot=boot,status='Discharging',energy=50,processes={'1:10':['Chrome',2]}))
            with patch.object(m.time,'time',return_value=3700), patch.object(m.time,'monotonic',return_value=40), patch.object(m,'process_snapshot',return_value={'1:10':['Chrome',8]}), patch.object(m,'battery_read',return_value=dict(status='Discharging',percent=60,energy=45,watts=12)), patch.object(m,'command',return_value='balanced'), patch.object(m,'import_upower'):
                m.sample(conn)
            row=conn.execute('SELECT span,drained_wh,apps FROM samples').fetchone()
            self.assertEqual(row,(0,None,'{}'))

    def test_measured_drain_and_history_survive_reopen(self):
        with tempfile.TemporaryDirectory() as folder:
            db=Path(folder)/'db'
            boot=Path('/proc/sys/kernel/random/boot_id').read_text().strip()
            with m.connect(db) as conn:
                m.set_meta(conn,'previous',dict(ts=100,monotonic=10,boot=boot,status='Discharging',energy=50,processes={'1:10':['Chrome',2]}))
                with patch.object(m.time,'time',return_value=130), patch.object(m.time,'monotonic',return_value=40), patch.object(m,'process_snapshot',return_value={'1:10':['Chrome',8]}), patch.object(m,'battery_read',return_value=dict(status='Discharging',percent=60,energy=49.9,watts=12)), patch.object(m,'command',return_value='balanced'), patch.object(m,'import_upower'):
                    m.sample(conn)
            with m.connect(db) as conn, patch.object(m.time,'time',return_value=131):
                report=m.report(conn,1)
                self.assertAlmostEqual(report['drained_wh'],.1)
                self.assertEqual(report['apps'][0],dict(name='Chrome',seconds=6,cpu=20))
                self.assertEqual(report['rate'][0]['value'],12)

unittest.main()
