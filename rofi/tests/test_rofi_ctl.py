"""Exercise the wrapper's process/data contract without a desktop session."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROFI_ROOT = Path(__file__).resolve().parents[1]
MOCK_ROFI = r'''#!/usr/bin/env python3
import json, os, pathlib, signal, sys
args = sys.argv[1:]
data = sys.stdin.buffer.read()
pathlib.Path(os.environ["MOCK_RECORD"]).write_text(json.dumps({
    "argv": args, "stdin": data.hex(), "pid": os.getpid(),
}))
if os.environ.get("MOCK_HOLD") == "1":
    pathlib.Path(args[args.index("-pid") + 1]).write_text(str(os.getpid()))
    print("ready", flush=True)
    signal.pause()
else:
    sys.stdout.write(os.environ.get("MOCK_STDOUT", ""))
    sys.exit(int(os.environ.get("MOCK_EXIT", "0")))
'''


class LaunchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="rofi contract ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = self.root / "config with spaces"
        self.config.mkdir()
        (self.config / "config.rasi").write_text("")
        (self.config / "themes").mkdir()
        shutil.copy2(ROFI_ROOT / "rofi-ctl", self.config / "rofi-ctl")
        self.launch = self.config / "rofi-ctl"
        self.record = self.root / "record.json"
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        binaries = self.root / "bin"
        binaries.mkdir()
        fake = binaries / "rofi"
        fake.write_text(MOCK_ROFI)
        fake.chmod(0o755)
        self.env = {
            **os.environ,
            "PATH": f"{binaries}:{os.environ['PATH']}",
            "XDG_RUNTIME_DIR": str(self.runtime),
            "MOCK_RECORD": str(self.record),
            "MOCK_EXIT": "0",
            "MOCK_HOLD": "0",
            "MOCK_STDOUT": "",
        }

    def call(self, *args, data=b"", **overrides):
        return subprocess.run(
            [str(self.launch), *args], input=data, capture_output=True,
            env={**self.env, **overrides}, timeout=5, cwd="/",
        )

    def recorded(self):
        return json.loads(self.record.read_text())

    def option(self, name):
        args = self.recorded()["argv"]
        return args[args.index(name) + 1]

    def hold(self, style="apps"):
        proc = subprocess.Popen(
            [str(self.launch), "apps", style], stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            env={**self.env, "MOCK_HOLD": "1"},
        )
        self.addCleanup(self.close_process, proc)
        self.assertEqual(proc.stdout.readline(), "ready\n")
        return proc

    @staticmethod
    def close_process(proc):
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=3)
        if proc.stdout:
            proc.stdout.close()
        if proc.stderr:
            proc.stderr.close()

    def test_default_apps_resolves_its_own_directory(self):
        result = self.call()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.option("-show"), "drun")
        self.assertEqual(self.option("-config"), str(self.config / "config.rasi"))
        self.assertEqual(self.option("-theme"), str(self.config / "themes/apps.rasi"))

    def test_symlinked_entry_point_finds_its_own_config(self):
        entry = self.root / "bin" / "rofi-ctl"
        entry.symlink_to(self.launch)
        result = subprocess.run([str(entry), "shell"], input=b"",
                                capture_output=True, env=self.env, timeout=5, cwd="/")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.option("-config"), str(self.config / "config.rasi"))

    def test_copy_without_config_fails_loudly(self):
        lonely = self.root / "copied"
        lonely.mkdir()
        shutil.copy2(self.launch, lonely / "rofi-ctl")
        result = subprocess.run([str(lonely / "rofi-ctl"), "shell"], input=b"",
                                capture_output=True, env=self.env, timeout=5, cwd="/")
        self.assertEqual(result.returncode, 2)
        self.assertIn(b"config.rasi", result.stderr)
        self.assertFalse(self.record.exists())

    def test_modes_and_launcher_styles(self):
        for command, style, mode in [
            ("apps", "orbit", "drun"), ("run", "apps", "run"),
            ("run", "orbit", "run"),
        ]:
            with self.subTest(command=command, style=style):
                self.assertEqual(self.call(command, style).returncode, 0)
                self.assertEqual(self.option("-show"), mode)
                self.assertEqual(Path(self.option("-theme")).stem, style)
        self.assertEqual(self.call("window").returncode, 0)
        self.assertEqual(self.option("-show"), "window")

    def test_extra_arguments_remain_separate_and_literal(self):
        prompt = 'SSID with spaces; $(touch should-not-run) "quoted"'
        self.assertEqual(self.call("menu", "-p", prompt).returncode, 0)
        self.assertEqual(self.option("-p"), prompt)

    def test_stdin_with_icon_metadata_is_not_modified(self):
        data = b"image with spaces.png\0icon\x1f/tmp/image with spaces.png\n"
        for command in ("menu", "wallpaper"):
            with self.subTest(command=command):
                self.assertEqual(self.call(command, data=data).returncode, 0)
                self.assertEqual(bytes.fromhex(self.recorded()["stdin"]), data)
        self.assertIn("-no-custom", self.recorded()["argv"])

    def test_menu_leaves_custom_input_policy_to_caller(self):
        self.call("menu")
        self.assertNotIn("-no-custom", self.recorded()["argv"])
        self.call("menu", "-no-custom")
        self.assertIn("-no-custom", self.recorded()["argv"])

    def test_shell_provides_exactly_two_choices_and_only_returns_text(self):
        result = self.call("shell", data=b"ignored\n", MOCK_STDOUT="Native\n")
        self.assertEqual(result.stdout, b"Native\n")
        self.assertEqual(bytes.fromhex(self.recorded()["stdin"]), b"Noctalia\nNative\n")
        self.assertIn("-no-custom", self.recorded()["argv"])
        self.assertEqual(Path(self.option("-theme")).stem, "shell-select")

    def test_password_has_empty_stdin_and_allows_typed_text(self):
        result = self.call("password", "-p", "Password", data=b"not-a-choice\n",
                           MOCK_STDOUT="typed password\n")
        self.assertEqual(result.stdout, b"typed password\n")
        self.assertEqual(self.recorded()["stdin"], "")
        self.assertIn("-password", self.recorded()["argv"])
        self.assertNotIn("-no-custom", self.recorded()["argv"])

    def test_cancellation_and_custom_return_codes_are_preserved(self):
        for code in (1, 10):
            with self.subTest(code=code):
                result = self.call("shell", MOCK_EXIT=str(code))
                self.assertEqual(result.returncode, code)
                self.assertEqual(result.stdout, b"")

    def test_invalid_command_or_style_does_not_launch_rofi(self):
        for args in [("unknown",), ("apps", "unknown"), ("run", "../orbit")]:
            with self.subTest(args=args):
                result = self.call(*args)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, b"")
                self.assertTrue(result.stderr)
                self.assertFalse(self.record.exists())

    def test_help_does_not_launch_rofi(self):
        result = self.call("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn(b"Usage: rofi-ctl", result.stdout)
        self.assertFalse(self.record.exists())

    def test_exec_replaces_the_wrapper_process(self):
        proc = self.hold()
        self.assertEqual(self.recorded()["pid"], proc.pid)

    def test_toggle_stops_only_its_own_launcher(self):
        proc = self.hold()
        before = self.record.read_bytes()
        result = self.call("toggle", "apps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(proc.wait(timeout=3), 0)
        self.assertEqual(self.record.read_bytes(), before)

    def test_reused_pid_does_not_kill_an_unrelated_process(self):
        other = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        self.addCleanup(self.close_process, other)
        pid_file = self.runtime / f"dotfile-rofi-{os.getuid()}-launcher-apps.pid"
        pid_file.write_text(str(other.pid))
        result = self.call("toggle", "apps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(other.poll())
        self.assertEqual(self.option("-show"), "drun")

    def test_toggle_does_not_close_the_other_style(self):
        proc = self.hold("orbit")
        result = self.call("toggle", "apps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(proc.poll())
        self.assertEqual(Path(self.option("-theme")).stem, "apps")


if __name__ == "__main__":
    unittest.main()
