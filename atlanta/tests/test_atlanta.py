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
suffixes = []
if len(sys.argv) > 1:
    argument = sys.argv[1].upper().replace("-", "_").lstrip("_")
    suffixes.append("_" + argument)
suffixes.append("")
output = None
for suffix in suffixes:
    output = os.environ.get("MOCK_" + key + suffix + "_OUT")
    if output is not None:
        break
if output:
    print(output)
if os.environ.get("MOCK_" + key + "_HOLD") == "1":
    while True:
        time.sleep(0.2)
exit_code = None
for suffix in suffixes:
    exit_code = os.environ.get("MOCK_" + key + suffix + "_EXIT")
    if exit_code is not None:
        break
if exit_code is None:
    exit_code = os.environ.get("MOCK_" + key + "_EXIT", "0")
sys.exit(int(exit_code))
'''

PROVIDERS = (
    "rofi-ctl", "waybar-ctl", "swaync-client", "awww", "grim", "slurp",
    "notify-send", "wpctl", "brightnessctl", "wlogout", "swayidle",
    "wlsunset", "hyprlock", "hyprctl", "niri", "depth-ctl", "loginctl",
    "systemctl", "awww-daemon", "swaync", "eww", "busctl",
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

    def call(self, *args, cwd="/", **overrides):
        return subprocess.run(
            [str(self.script), *args], capture_output=True, text=True,
            env={**self.env, **overrides}, timeout=15, cwd=cwd,
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
        self.assertIn("start", result.stdout)
        self.assertIn("stop", result.stdout)

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

    def test_notifications_dnd_uses_the_toggle_flag(self):
        result = self.call("notifications", "dnd")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.only_call("swaync-client"), ["-d"])

    def test_notifications_clear_uses_close_all(self):
        result = self.call("notifications", "clear")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.only_call("swaync-client"), ["-C"])

    def test_idle_toggles_a_tracked_process(self):
        started = self.call("idle", "toggle", **{"MOCK_SWAYIDLE_HOLD": "1"})
        self.assertEqual(started.returncode, 0, started.stderr)
        self.wait_for(self.tracked("idle"))
        argv = self.wait_calls("swayidle")[0]["argv"]
        self.assertIn("timeout", argv)
        self.assertIn("session dpms off", " ".join(argv))
        status = self.call("idle", "status")
        self.assertEqual(status.returncode, 0)
        self.assertIn("running", status.stdout)

        stopped = self.call("idle", "toggle")
        self.assertEqual(stopped.returncode, 0, stopped.stderr)
        self.assertFalse(self.tracked("idle").exists())
        self.assertEqual(self.call("idle", "status").returncode, 1)

    def test_idle_runs_on_niri(self):
        started = self.call("idle", "toggle", ATLANTA_SESSION="niri",
                           **{"MOCK_SWAYIDLE_HOLD": "1"})
        self.assertEqual(started.returncode, 0, started.stderr)
        self.wait_for(self.tracked("idle"))
        self.assertEqual(self.call("idle", "toggle", ATLANTA_SESSION="niri").returncode, 0)
        self.assertFalse(self.tracked("idle").exists())

    def test_idle_rejects_an_unknown_session(self):
        result = self.call("idle", "toggle", ATLANTA_SESSION="unknown")
        self.assertEqual(result.returncode, 3)
        self.assertIn("needs hyprland, niri", result.stderr)
        self.assertFalse(self.calls("swayidle"))

    def test_nightlight_toggles_a_tracked_process(self):
        started = self.call("nightlight", "toggle",
                            **{"MOCK_WLSUNSET_HOLD": "1"})
        self.assertEqual(started.returncode, 0, started.stderr)
        self.wait_for(self.tracked("nightlight"))
        self.assertEqual(self.wait_calls("wlsunset")[0]["argv"], ["-t", "4000"])
        self.assertIn("running", self.call("nightlight", "status").stdout)

        stopped = self.call("nightlight", "toggle")
        self.assertEqual(stopped.returncode, 0, stopped.stderr)
        self.assertFalse(self.tracked("nightlight").exists())
        self.assertEqual(self.call("nightlight", "status").returncode, 1)

    def test_nightlight_runs_on_niri_with_a_temp_override(self):
        started = self.call("nightlight", "toggle", ATLANTA_SESSION="niri",
                            ATLANTA_NIGHTLIGHT_TEMP="3500",
                            **{"MOCK_WLSUNSET_HOLD": "1"})
        self.assertEqual(started.returncode, 0, started.stderr)
        self.wait_for(self.tracked("nightlight"))
        self.assertEqual(self.wait_calls("wlsunset")[0]["argv"], ["-t", "3500"])
        self.call("nightlight", "toggle", ATLANTA_SESSION="niri")

    def test_session_menu_opens_and_closes_wlogout(self):
        opened = self.call("session", "menu", **{"MOCK_WLOGOUT_HOLD": "1"})
        self.assertEqual(opened.returncode, 0, opened.stderr)
        self.wait_for(self.tracked("wlogout"))
        rows = self.wait_calls("wlogout")
        self.assertEqual(rows[0]["argv"], ["-b", "4", "-n", "-m", "100"])

        closed = self.call("session", "menu")
        self.assertEqual(closed.returncode, 0, closed.stderr)
        self.assertFalse(self.tracked("wlogout").exists())

    def test_session_lock_works_on_hyprland_and_niri(self):
        for session in ("hyprland", "niri"):
            with self.subTest(session=session):
                result = self.call("session", "lock", ATLANTA_SESSION=session)
                self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            [row["argv"] for row in self.calls("hyprlock")], [[], []])

        blocked = self.call("session", "lock", ATLANTA_SESSION="unknown")
        self.assertEqual(blocked.returncode, 3)
        self.assertIn("needs hyprland, niri", blocked.stderr)

    def test_session_dpms_uses_the_compositor_command(self):
        self.assertEqual(self.call("session", "dpms", "off").returncode, 0)
        self.assertEqual(self.call("session", "dpms", "on",
                                 ATLANTA_SESSION="niri").returncode, 0)
        self.assertEqual(self.only_call("hyprctl"),
                         ["dispatch", 'hl.dsp.dpms({ action = "off" })'])
        self.assertEqual(self.only_call("niri"),
                         ["msg", "action", "power-on-monitors"])

        blocked = self.call("session", "dpms", "off", ATLANTA_SESSION="unknown")
        self.assertEqual(blocked.returncode, 3)
        self.assertIn("needs hyprland, niri", blocked.stderr)

    def test_session_dpms_rejects_an_unknown_direction(self):
        result = self.call("session", "dpms", "sideways")
        self.assertEqual(result.returncode, 2)
        self.assertIn("session dpms needs off or on", result.stderr)

    def test_session_logout_uses_loginctl(self):
        result = self.call("session", "logout")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.only_call("loginctl"), ["terminate-user", os.environ["USER"]])

    def test_session_reboot_and_poweroff_use_systemctl(self):
        self.assertEqual(self.call("session", "reboot").returncode, 0)
        self.assertEqual(self.call("session", "poweroff").returncode, 0)
        self.assertEqual(
            [row["argv"] for row in self.calls("systemctl")],
            [["reboot"], ["poweroff"]])

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

    def test_wallpaper_set_with_relative_path_updates_the_index(self):
        result = self.call("wallpaper", "set", "b.png", cwd=str(self.wallpapers))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.wallpapers / "b.png"))
        self.assertEqual(self.img_call()[1], str(self.wallpapers / "b.png"))
        self.assertEqual(
            (self.state / "atlanta" / "wallpaper").read_text().strip(), "1")

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

    def test_status_reports_notification_dnd(self):
        result = self.call("status", **{
            "MOCK_SWAYNC_CLIENT_C_OUT": "3",
            "MOCK_SWAYNC_CLIENT_D_OUT": "false",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("running dnd=off count=3", result.stdout)

    def test_status_check_ignores_missing_optional_notify_send(self):
        (self.binaries / "notify-send").unlink()
        minimal = self.root / "minimal"
        minimal.mkdir()
        for name in ("bash", "readlink", "dirname", "timeout", "wc", "python3"):
            target = shutil.which(name)
            self.assertIsNotNone(target, name)
            (minimal / name).symlink_to(target)
        result = self.call(
            "status", "--check",
            PATH=f"{minimal}:{self.binaries}",
            ATLANTA_PROVIDER_DIR=str(self.binaries),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("osd", result.stdout)
        self.assertIn("brightness", result.stdout)
        self.assertIn("optional (OSD disabled)", result.stdout)

    def test_doctor_reports_the_resolved_provider_and_session(self):
        result = self.call("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.binaries / "waybar-ctl"), result.stdout)
        self.assertIn("hyprland", result.stdout)
        self.assertIn("loginctl", result.stdout)
        self.assertIn("systemctl", result.stdout)
        self.assertIn(str(self.binaries / "swayidle"), result.stdout)
        self.assertIn(str(self.binaries / "wlsunset"), result.stdout)

    def test_osd_reports_volume_without_changing_it(self):
        result = self.call("osd", "volume", **{"MOCK_WPCTL_OUT": "Volume: 0.45"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Volume 45%")
        self.assertEqual(self.only_call("wpctl"), ["get-volume", "@DEFAULT_AUDIO_SINK@"])
        self.assertIn("x-canonical-private-synchronous:atlanta-osd",
                      " ".join(self.only_call("notify-send")))

    def test_volume_up_sets_then_reports(self):
        result = self.call("volume", "up",
                           **{"MOCK_WPCTL_GET_VOLUME_OUT": "Volume: 0.65"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Volume 65%")
        self.assertEqual(
            [row["argv"] for row in self.calls("wpctl")],
            [["set-volume", "@DEFAULT_AUDIO_SINK@", "0.05+", "-l", "1.0"],
             ["get-volume", "@DEFAULT_AUDIO_SINK@"]])
        self.assertIn("x-canonical-private-synchronous:atlanta-osd",
                      " ".join(self.only_call("notify-send")))

    def test_volume_down_respects_the_step_override(self):
        result = self.call("volume", "down", ATLANTA_VOLUME_STEP="0.1",
                           **{"MOCK_WPCTL_GET_VOLUME_OUT": "Volume: 0.40"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Volume 40%")
        self.assertEqual(self.calls("wpctl")[0]["argv"],
                         ["set-volume", "@DEFAULT_AUDIO_SINK@", "0.1-", "-l", "1.0"])

    def test_volume_mute_toggles_and_shows_the_muted_state(self):
        result = self.call("volume", "mute",
                           **{"MOCK_WPCTL_GET_VOLUME_OUT": "Volume: 0.65 [MUTED]"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Volume 65% (muted)")
        self.assertEqual(self.calls("wpctl")[0]["argv"],
                         ["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])

    def test_mic_toggle_uses_the_default_source(self):
        result = self.call("mic", "toggle",
                           **{"MOCK_WPCTL_GET_VOLUME_OUT": "Volume: 0.30 [MUTED]"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Microphone 30% (muted)")
        self.assertEqual(self.calls("wpctl")[0]["argv"],
                         ["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])

    def test_brightness_up_sets_then_reports(self):
        result = self.call("brightness", "up", **{
            "MOCK_BRIGHTNESSCTL_GET_OUT": "40",
            "MOCK_BRIGHTNESSCTL_MAX_OUT": "100",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "Brightness 40%")
        self.assertEqual([row["argv"] for row in self.calls("brightnessctl")],
                         [["-q", "set", "+5%"], ["get"], ["max"]])
        self.assertIn("Brightness", self.only_call("notify-send"))

    def test_brightness_down_uses_the_reverse_step(self):
        result = self.call("brightness", "down", ATLANTA_BRIGHTNESS_STEP="10%", **{
            "MOCK_BRIGHTNESSCTL_GET_OUT": "50",
            "MOCK_BRIGHTNESSCTL_MAX_OUT": "100",
        })
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls("brightnessctl")[0]["argv"],
                         ["-q", "set", "10%-"])

    def test_volume_rejects_an_unknown_verb(self):
        result = self.call("volume", "louder")
        self.assertEqual(result.returncode, 2)
        self.assertIn("volume needs a verb", result.stderr)

    def test_screenshot_without_verb_does_not_create_the_directory(self):
        result = self.call("screenshot")
        self.assertEqual(result.returncode, 2)
        self.assertIn("screenshot needs a verb", result.stderr)
        self.assertFalse(self.shots.exists())

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

    def test_start_starts_the_shell_stack(self):
        eww_calls = self.root / "eww.calls"
        eww = self.binaries / "eww"
        eww.write_text(
            "#!/usr/bin/env bash\n"
            f"printf '%s\\n' \"$*\" >> \"{eww_calls}\"\n"
            "case \" $* \" in\n"
            "    *\" ping \"*) exit 1 ;;\n"
            "esac\n"
            "exit 0\n"
        )
        eww.chmod(0o755)

        result = self.call(
            "start",
            **{
                "MOCK_AWWW_QUERY_EXIT": "1",
                "MOCK_SWAYNC_CLIENT_C_EXIT": "1",
                "MOCK_WAYBAR_CTL_STATUS_EXIT": "1",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("started awww", result.stdout)
        self.assertIn("started eww", result.stdout)
        self.assertIn("started swaync", result.stdout)
        self.assertIn("started waybar", result.stdout)

        self.wait_calls("awww-daemon")
        self.wait_calls("swaync")
        self.wait_for(eww_calls)
        self.assertIn("ping", eww_calls.read_text())
        self.assertIn("daemon", eww_calls.read_text())
        self.assertEqual(
            [row["argv"] for row in self.calls("waybar-ctl")],
            [["status"], ["start"]],
        )

    def test_start_skips_running_components(self):
        result = self.call("start")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already running awww", result.stdout)
        self.assertIn("already running eww", result.stdout)
        self.assertIn("already running swaync", result.stdout)
        self.assertIn("already running waybar", result.stdout)
        self.assertFalse(self.calls("awww-daemon"))
        self.assertFalse(self.calls("swaync"))
        self.assertEqual(
            [row["argv"] for row in self.calls("waybar-ctl")],
            [["status"]],
        )
        self.assertEqual(
            [row["argv"][-1] for row in self.calls("eww")],
            ["ping"],
        )

    def test_stop_stops_the_shell_stack(self):
        dummy = self.root / "swaync"
        dummy.write_text(
            "#!/usr/bin/env python3\n"
            "import time\n"
            "time.sleep(30)\n"
        )
        dummy.chmod(0o755)
        proc = subprocess.Popen([str(dummy)])

        def cleanup():
            if proc.poll() is None:
                proc.kill()
            proc.wait()

        self.addCleanup(cleanup)

        result = self.call(
            "stop", **{"MOCK_BUSCTL_USER_OUT": f"PID={proc.pid}"}
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("stopped swaync", result.stdout)
        proc.wait(timeout=2)
        self.assertIsNotNone(proc.poll())

        self.assertEqual(
            [row["argv"] for row in self.calls("waybar-ctl")],
            [["status"], ["stop"]],
        )
        self.assertEqual(
            [row["argv"] for row in self.calls("awww")],
            [["query"], ["kill"]],
        )
        self.assertEqual(
            [row["argv"][-1] for row in self.calls("eww")],
            ["ping", "kill"],
        )
        self.assertEqual(
            [row["argv"] for row in self.calls("busctl")],
            [["--user", "status", "org.erikreider.swaync"]],
        )

    def test_stop_is_idempotent(self):
        result = self.call(
            "stop",
            **{
                "MOCK_BUSCTL_USER_EXIT": "1",
                "MOCK_EWW_CONFIG_EXIT": "1",
                "MOCK_AWWW_QUERY_EXIT": "1",
                "MOCK_WAYBAR_CTL_STATUS_EXIT": "1",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not running waybar", result.stdout)
        self.assertIn("not running swaync", result.stdout)
        self.assertIn("not running eww", result.stdout)
        self.assertIn("not running awww", result.stdout)
        self.assertEqual(
            [row["argv"] for row in self.calls("waybar-ctl")],
            [["status"]],
        )
        self.assertEqual(
            [row["argv"] for row in self.calls("awww")],
            [["query"]],
        )
        self.assertEqual(
            [row["argv"][-1] for row in self.calls("eww")],
            ["ping"],
        )

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

    def test_install_remove_only_removes_own_links(self):
        bin_dir = self.root / "bin"
        fish_dir = self.root / "fish"
        env = {**self.env, "BIN_DIR": str(bin_dir),
               "FISH_COMPLETION_DIR": str(fish_dir)}
        installed = subprocess.run(
            ["bash", str(self.app / "install.sh")],
            capture_output=True, text=True, timeout=15, cwd="/", env=env,
        )
        self.assertEqual(installed.returncode, 0, installed.stderr)
        self.assertTrue((bin_dir / "atlanta").is_symlink())
        self.assertTrue((fish_dir / "atlanta.fish").is_symlink())

        foreign = self.root / "foreign"
        foreign.write_text("keep me")
        (bin_dir / "foreign").symlink_to(foreign)

        removed = subprocess.run(
            ["bash", str(self.app / "install.sh"), "--remove"],
            capture_output=True, text=True, timeout=15, cwd="/", env=env,
        )
        self.assertEqual(removed.returncode, 0, removed.stderr)
        self.assertFalse((bin_dir / "atlanta").exists())
        self.assertFalse((fish_dir / "atlanta.fish").exists())
        self.assertTrue((bin_dir / "foreign").is_symlink())
        self.assertEqual(os.readlink(bin_dir / "foreign"), str(foreign))


if __name__ == "__main__":
    unittest.main()
