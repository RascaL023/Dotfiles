"""Exercise waybar-ctl's session, process and passthrough contract."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest


WAYBAR_ROOT = Path(__file__).resolve().parents[1]

MOCK_WAYBAR = r'''#!/usr/bin/env python3
import json, os, pathlib, signal, sys
pathlib.Path(os.environ["MOCK_RECORD"]).write_text(json.dumps({
    "argv": sys.argv[1:], "pid": os.getpid(),
}))
if os.environ.get("MOCK_HOLD") == "1":
    def reload(*_):
        pathlib.Path(os.environ["MOCK_SIGNAL"]).write_text("SIGUSR2")
        sys.exit(0)
    signal.signal(signal.SIGUSR2, reload)
    while True:
        signal.pause()
sys.exit(int(os.environ.get("MOCK_EXIT", "0")))
'''


class WaybarCtlTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="waybar contract ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = self.root / "waybar config"
        self.config.mkdir()
        shutil.copy2(WAYBAR_ROOT / "waybar-ctl", self.config / "waybar-ctl")
        for session in ("hyprland", "niri"):
            (self.config / f"config.{session}.jsonc").write_text("{}\n")
        self.ctl = self.config / "waybar-ctl"
        self.record = self.root / "record.json"
        self.signal_record = self.root / "signal.txt"
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.binaries = self.root / "bin"
        self.binaries.mkdir()
        fake = self.binaries / "waybar"
        fake.write_text(MOCK_WAYBAR)
        fake.chmod(0o755)
        self.pid_file = self.runtime / f"dotfile-waybar-{os.getuid()}.pid"
        base = {k: v for k, v in os.environ.items()
                if k not in ("NIRI_SOCKET", "HYPRLAND_INSTANCE_SIGNATURE")}
        self.env = {
            **base,
            "PATH": f"{self.binaries}:{os.environ['PATH']}",
            "XDG_RUNTIME_DIR": str(self.runtime),
            "MOCK_RECORD": str(self.record),
            "MOCK_SIGNAL": str(self.signal_record),
            "MOCK_HOLD": "0",
            "MOCK_EXIT": "0",
        }

    def tearDown(self):
        pid = self.pid()
        if pid:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def call(self, *args, **overrides):
        return subprocess.run(
            [str(self.ctl), *args], capture_output=True, text=True,
            env={**self.env, **overrides}, timeout=10, cwd="/",
        )

    def wait_for(self, path, timeout=3.0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            if path.exists():
                return path
            time.sleep(0.02)
        raise AssertionError(f"{path} never appeared")

    def argv(self):
        return json.loads(self.wait_for(self.record).read_text())["argv"]

    def pid(self):
        try:
            pid = int(self.pid_file.read_text().strip())
        except (OSError, ValueError):
            return None
        return pid if Path(f"/proc/{pid}").exists() else None

    def wait_pid(self, timeout=3.0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            pid = self.pid()
            if pid:
                return pid
            time.sleep(0.02)
        raise AssertionError("no pid file")

    def running(self, session="niri"):
        result = self.call("start", "--session", session, MOCK_HOLD="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        pid = self.wait_pid()
        self.wait_for(self.record)
        return pid

    def test_start_uses_the_niri_config(self):
        result = self.call("start", NIRI_SOCKET="/run/niri.sock")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.argv(), ["-c", str(self.config / "config.niri.jsonc")])

    def test_start_uses_the_hyprland_config(self):
        result = self.call("start", HYPRLAND_INSTANCE_SIGNATURE="abc123")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.argv(), ["-c", str(self.config / "config.hyprland.jsonc")])

    def test_session_flag_wins_over_the_environment(self):
        self.call("start", "--session", "hyprland", NIRI_SOCKET="/run/niri.sock")
        self.assertEqual(self.argv(), ["-c", str(self.config / "config.hyprland.jsonc")])

    def test_extra_arguments_reach_waybar(self):
        self.call("start", "--session", "niri", "-l", "debug")
        self.assertEqual(
            self.argv(), ["-c", str(self.config / "config.niri.jsonc"), "-l", "debug"])

    def test_missing_session_fails_loudly(self):
        result = self.call("start")
        self.assertEqual(result.returncode, 2)
        self.assertIn("cannot tell the session", result.stderr)
        self.assertFalse(self.record.exists())

    def test_unknown_session_fails_loudly(self):
        result = self.call("start", "--session", "sway")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown session", result.stderr)

    def test_missing_config_fails_loudly(self):
        (self.config / "config.niri.jsonc").unlink()
        result = self.call("start", "--session", "niri")
        self.assertEqual(result.returncode, 2)
        self.assertIn("missing config", result.stderr)

    def test_start_is_idempotent_while_running(self):
        pid = self.running()
        self.record.unlink()
        second = self.call("start", "--session", "niri", MOCK_HOLD="1")
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(self.pid(), pid)
        self.assertFalse(self.record.exists())

    def test_status_reports_running_and_stopped(self):
        stopped = self.call("status", "--session", "niri")
        self.assertEqual(stopped.returncode, 1)
        self.assertEqual(stopped.stdout.strip(), "not running")

        pid = self.running()
        running = self.call("status", "--session", "niri")
        self.assertEqual(running.returncode, 0)
        self.assertEqual(running.stdout.strip(), f"running {pid} niri")

    def test_toggle_starts_then_stops(self):
        pid = self.running()
        result = self.call("toggle", "--session", "niri")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(self.pid())
        self.assertFalse(Path(f"/proc/{pid}").exists())

        self.call("toggle", "--session", "niri")
        self.assertIsNotNone(self.pid())

    def test_stop_ignores_a_foreign_pid_file(self):
        foreign = subprocess.Popen(["sleep", "30"])
        self.addCleanup(foreign.wait)
        self.addCleanup(foreign.kill)
        self.pid_file.write_text(f"{foreign.pid}\n")

        result = self.call("stop", "--session", "niri")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(foreign.poll())

    def test_reload_signals_the_running_bar(self):
        pid = self.running()
        result = self.call("reload", "--session", "niri")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.wait_for(self.signal_record).read_text(), "SIGUSR2")
        deadline = time.time() + 3
        while Path(f"/proc/{pid}").exists() and time.time() < deadline:
            time.sleep(0.02)
        self.assertIsNone(self.pid())

    def test_reload_fails_when_stopped(self):
        result = self.call("reload", "--session", "niri")
        self.assertEqual(result.returncode, 1)
        self.assertIn("not running", result.stderr)

    def test_run_stays_in_the_foreground(self):
        result = self.call("run", "--session", "niri", "-l", "debug", MOCK_EXIT="3")
        self.assertEqual(result.returncode, 3)
        self.assertEqual(
            self.argv(), ["-c", str(self.config / "config.niri.jsonc"), "-l", "debug"])
        self.assertFalse(self.pid_file.exists())

    def test_config_prints_the_session_path(self):
        result = self.call("config", "--session", "hyprland")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.config / "config.hyprland.jsonc"))

    def test_missing_waybar_fails_loudly(self):
        minimal = self.root / "minimal-bin"
        minimal.mkdir()
        for name in ("bash", "readlink", "dirname", "sleep"):
            (minimal / name).symlink_to(shutil.which(name))
        result = self.call("start", "--session", "niri", PATH=str(minimal))
        self.assertEqual(result.returncode, 127)
        self.assertIn("not available on PATH", result.stderr)

    def test_unknown_command_fails_loudly(self):
        result = self.call("resize")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown command", result.stderr)

    def test_help_prints_usage(self):
        result = self.call("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Usage: waybar-ctl", result.stdout)


if __name__ == "__main__":
    unittest.main()
