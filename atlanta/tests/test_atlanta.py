"""Exercise atlanta's routing, provider resolution and state contract.

Every provider is a fake in a temporary directory, so nothing here needs a
compositor, a bar, or a live notification daemon.
"""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest


ATLANTA_ROOT = Path(__file__).resolve().parents[1]

MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, sys, time

name = os.path.basename(sys.argv[0])
key = name.upper().replace("-", "_")
record = os.environ.get("MOCK_RECORD")
if record:
    with open(record, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"name": name, "argv": sys.argv[1:]}) + "\n")
output = os.environ.get("MOCK_" + key + "_OUT")
if output:
    print(output)
if os.environ.get("MOCK_" + key + "_HOLD") == "1":
    while True:
        time.sleep(0.2)
sys.exit(int(os.environ.get("MOCK_" + key + "_EXIT", "0")))
'''

PROVIDERS = (
    "rofi-ctl", "waybar-ctl", "swaync-client", "awww", "grim", "slurp",
    "notify-send", "wpctl", "brightnessctl", "wlogout", "hypridle",
    "hyprsunset", "hyprlock", "depth-ctl", "loginctl",
)


class AtlantaTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="atlanta contract ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

        self.app = self.root / "atlanta"
        shutil.copytree(ATLANTA_ROOT, self.app,
                        ignore=shutil.ignore_patterns("__pycache__"))
        self.script = self.app / "atlanta"

        self.binaries = self.root / "providers"
        self.binaries.mkdir()
        for name in PROVIDERS:
            fake = self.binaries / name
            fake.write_text(MOCK)
            fake.chmod(0o755)

        self.record = self.root / "calls.jsonl"
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.state = self.root / "state"
        self.wallpapers = self.root / "wallpapers"
        self.wallpapers.mkdir()
        (self.wallpapers / "a.png").write_bytes(b"a")
        (self.wallpapers / "b.png").write_bytes(b"b")
        self.shots = self.root / "shots"

        base = {
            key: value for key, value in os.environ.items()
            if key not in ("NIRI_SOCKET", "HYPRLAND_INSTANCE_SIGNATURE")
        }
        self.env = {
            **base,
            "PATH": f"{self.binaries}:{os.environ['PATH']}",
            "ATLANTA_PROVIDER_DIR": str(self.binaries),
            "ATLANTA_SESSION": "hyprland",
            "ATLANTA_WALLPAPER_DIR": str(self.wallpapers),
            "ATLANTA_SCREENSHOT_DIR": str(self.shots),
            "XDG_RUNTIME_DIR": str(self.runtime),
            "XDG_STATE_HOME": str(self.state),
            "MOCK_RECORD": str(self.record),
        }

    def tearDown(self):
        for pidfile in self.runtime.glob("atlanta-*.pid"):
            try:
                os.kill(int(pidfile.read_text().strip()), signal.SIGKILL)
            except (OSError, ValueError):
                pass

    def call(self, *args, **overrides):
        return subprocess.run(
            [str(self.script), *args], capture_output=True, text=True,
            env={**self.env, **overrides}, timeout=15, cwd="/",
        )

    def calls(self, name=None):
        if not self.record.exists():
            return []
        rows = [json.loads(line) for line in self.record.read_text().splitlines()]
        return [row for row in rows if name is None or row["name"] == name]

    def only_call(self, name):
        rows = self.calls(name)
        self.assertEqual(len(rows), 1, rows)
        return rows[0]["argv"]

    def img_call(self):
        rows = [row["argv"] for row in self.calls("awww")
                if row["argv"][:1] == ["img"]]
        self.assertEqual(len(rows), 1, rows)
        return rows[0]

    def wait_calls(self, name, timeout=3.0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            rows = self.calls(name)
            if rows:
                return rows
            time.sleep(0.02)
        raise AssertionError(f"no {name} call")

    def tracked(self, name):
        return self.runtime / f"atlanta-{name}-{os.getuid()}.pid"

    def wait_for(self, path, timeout=3.0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            if path.exists():
                return
            time.sleep(0.02)
        raise AssertionError(f"{path} never appeared")

    def test_help_lists_capabilities(self):
        result = self.call("help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: atlanta", result.stdout)
        self.assertIn("bar.panel", result.stdout)

    def test_unknown_capability_is_usage(self):
        result = self.call("resize")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown capability", result.stderr)

    def test_launcher_passes_the_mode_through(self):
        result = self.call("launcher", "apps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.only_call("rofi-ctl"), ["apps"])

    def test_bar_maps_verbs_to_waybar_ctl(self):
        self.assertEqual(self.call("bar", "toggle").returncode, 0)
        self.assertEqual(self.call("bar", "show").returncode, 0)
        self.assertEqual(self.call("bar", "hide").returncode, 0)
        self.assertEqual(
            [row["argv"] for row in self.calls("waybar-ctl")],
            [["toggle"], ["start"], ["stop"]])

    def test_bar_rejects_the_inactive_provider(self):
        result = self.call("bar", "toggle", "--provider", "eww")
        self.assertEqual(result.returncode, 3)
        self.assertIn("not active", result.stderr)
        self.assertFalse(self.record.exists())

    def test_bar_panel_is_reserved(self):
        result = self.call("bar.panel", "toggle", "profile")
        self.assertEqual(result.returncode, 3)
        self.assertIn("reserved", result.stderr)

    def test_notifications_toggle_uses_the_panel_flag(self):
        result = self.call("notifications", "toggle")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.only_call("swaync-client"), ["-t"])

    def test_idle_toggles_a_tracked_process(self):
        started = self.call("idle", "toggle", **{"MOCK_HYPRIDLE_HOLD": "1"})
        self.assertEqual(started.returncode, 0, started.stderr)
        self.wait_for(self.tracked("hypridle"))
        status = self.call("idle", "status")
        self.assertEqual(status.returncode, 0)
        self.assertIn("running", status.stdout)

        stopped = self.call("idle", "toggle")
        self.assertEqual(stopped.returncode, 0, stopped.stderr)
        self.assertFalse(self.tracked("hypridle").exists())
        self.assertEqual(self.call("idle", "status").returncode, 1)

    def test_idle_is_unsupported_on_niri(self):
        result = self.call("idle", "toggle", ATLANTA_SESSION="niri")
        self.assertEqual(result.returncode, 3)
        self.assertIn("Hyprland-only", result.stderr)

    def test_nightlight_is_unsupported_on_niri(self):
        result = self.call("nightlight", "toggle", ATLANTA_SESSION="niri")
        self.assertEqual(result.returncode, 3)

    def test_session_menu_opens_and_closes_wlogout(self):
        opened = self.call("session", "menu", **{"MOCK_WLOGOUT_HOLD": "1"})
        self.assertEqual(opened.returncode, 0, opened.stderr)
        self.wait_for(self.tracked("wlogout"))
        rows = self.wait_calls("wlogout")
        self.assertEqual(rows[0]["argv"], ["-b", "4", "-n", "-m", "100"])

        closed = self.call("session", "menu")
        self.assertEqual(closed.returncode, 0, closed.stderr)
        self.assertFalse(self.tracked("wlogout").exists())

    def test_session_lock_is_hyprland_only(self):
        blocked = self.call("session", "lock", ATLANTA_SESSION="niri")
        self.assertEqual(blocked.returncode, 3)
        self.assertEqual(self.call("session", "lock").returncode, 0)
        self.only_call("hyprlock")

    def test_session_logout_uses_loginctl(self):
        result = self.call("session", "logout")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.only_call("loginctl"), ["terminate-user", os.environ["USER"]])

    def test_wallpaper_next_advances_the_index(self):
        result = self.call("wallpaper", "next")
        self.assertEqual(result.returncode, 0, result.stderr)
        argv = self.img_call()
        self.assertEqual(argv[0], "img")
        self.assertEqual(argv[1], str(self.wallpapers / "b.png"))
        self.assertEqual((self.state / "atlanta" / "wallpaper").read_text().strip(), "1")

    def test_wallpaper_prev_wraps(self):
        (self.state / "atlanta").mkdir(parents=True)
        (self.state / "atlanta" / "wallpaper").write_text("0\n")
        result = self.call("wallpaper", "prev")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.img_call()[1], str(self.wallpapers / "b.png"))

    def test_wallpaper_set_announces_the_path(self):
        target = self.wallpapers / "a.png"
        result = self.call("wallpaper", "set", str(target))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(target))
        self.assertEqual(self.img_call()[1], str(target))
        self.only_call("depth-ctl")

    def test_wallpaper_status_prints_the_index(self):
        (self.state / "atlanta").mkdir(parents=True)
        (self.state / "atlanta" / "wallpaper").write_text("1\n")
        result = self.call("wallpaper", "status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.strip().endswith("(1/2)"))

    def test_status_does_not_write_state(self):
        (self.state / "atlanta").mkdir(parents=True)
        state_file = self.state / "atlanta" / "wallpaper"
        state_file.write_text("1\n")
        result = self.call("status", **{"MOCK_WAYBAR_CTL_OUT": "running 4242 hyprland"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("running 4242 hyprland", result.stdout)
        self.assertIn("1/2 b.png", result.stdout)
        self.assertEqual(state_file.read_text(), "1\n")

    def test_doctor_reports_the_resolved_provider_and_session(self):
        result = self.call("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.binaries / "waybar-ctl"), result.stdout)
        self.assertIn("hyprland", result.stdout)

    def test_osd_reports_volume_without_changing_it(self):
        result = self.call("osd", "volume", **{"MOCK_WPCTL_OUT": "Volume: 0.45"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Volume 45%")
        self.assertEqual(self.only_call("wpctl"), ["get-volume", "@DEFAULT_AUDIO_SINK@"])
        self.assertIn("x-canonical-private-synchronous:atlanta-osd",
                      " ".join(self.only_call("notify-send")))

    def test_region_screenshot_passes_the_slurp_geometry(self):
        result = self.call("screenshot", "region", **{"MOCK_SLURP_OUT": "10x10+0+0"})
        self.assertEqual(result.returncode, 0, result.stderr)
        path = result.stdout.strip()
        self.assertTrue(path.startswith(str(self.shots)))
        self.assertTrue(path.endswith(".png"))
        self.assertEqual(self.only_call("grim"), ["-g", "10x10+0+0", path])

    def test_missing_provider_exits_127(self):
        empty = self.root / "empty"
        empty.mkdir()
        minimal = self.root / "minimal"
        minimal.mkdir()
        for name in ("bash", "readlink", "dirname"):
            (minimal / name).symlink_to(shutil.which(name))
        result = self.call(
            "launcher", "apps",
            ATLANTA_PROVIDER_DIR=str(empty), PATH=str(minimal))
        self.assertEqual(result.returncode, 127)
        self.assertIn("missing", result.stderr)

    def test_install_dry_run_touches_nothing(self):
        bin_dir = self.root / "bin"
        fish_dir = self.root / "fish"
        result = subprocess.run(
            ["bash", str(self.app / "install.sh"), "--dry-run"],
            capture_output=True, text=True, timeout=15, cwd="/",
            env={**self.env, "BIN_DIR": str(bin_dir),
                 "FISH_COMPLETION_DIR": str(fish_dir)},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("would link"), 2)
        self.assertFalse(bin_dir.exists())
        self.assertFalse(fish_dir.exists())


if __name__ == "__main__":
    unittest.main()
