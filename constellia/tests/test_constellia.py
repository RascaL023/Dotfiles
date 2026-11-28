"""Exercise constellia's routing, per-WM state and shell switch contract.

Every backend is a fake in a temporary directory, so nothing here needs a
compositor, Noctalia, atlanta, or a live D-Bus.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


CONSTELLIA_ROOT = Path(__file__).resolve().parents[1]

MOCK = r'''#!/usr/bin/env python3
import json, os, sys, time

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
echo = os.environ.get("MOCK_ECHO_ENV")
if echo:
    print(os.environ.get(echo, ""))
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

PGREP = r'''#!/usr/bin/env python3
import json, os, pathlib, sys

name = os.path.basename(sys.argv[0])
record = os.environ.get("MOCK_RECORD")
if record:
    with open(record, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"name": name, "argv": sys.argv[1:]}) + "\n")
pattern = sys.argv[-1]
for known in ("noctalia", "awww-daemon", "waybar", "eww"):
    if known in pattern:
        slug = known.upper().replace("-", "_")
        break
else:
    slug = "".join(c if c.isalnum() else "_" for c in pattern).strip("_").upper()
pidfile = pathlib.Path(os.environ["MOCK_PROC_DIR"]) / slug
if pidfile.exists():
    print(pidfile.read_text().strip() or "4242")
    sys.exit(0)
sys.exit(1)
'''

PKILL = r'''#!/usr/bin/env python3
import json, os, pathlib, sys

args = sys.argv[1:]
name = os.path.basename(sys.argv[0])
record = os.environ.get("MOCK_RECORD")
if record:
    with open(record, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"name": name, "argv": args}) + "\n")
signal = next((arg[1:] for arg in args if arg in ("-TERM", "-KILL")), "TERM")
if signal == "TERM" and os.environ.get("MOCK_PKILL_IGNORE_TERM") == "1":
    sys.exit(0)
if signal == "KILL" and os.environ.get("MOCK_PKILL_IGNORE_KILL") == "1":
    sys.exit(0)
pattern = args[-1]
for known in ("noctalia", "awww-daemon", "waybar", "eww"):
    if known in pattern:
        slug = known.upper().replace("-", "_")
        break
else:
    slug = "".join(c if c.isalnum() else "_" for c in pattern).strip("_").upper()
pidfile = pathlib.Path(os.environ["MOCK_PROC_DIR"]) / slug
if pidfile.exists():
    pidfile.unlink()
sys.exit(0)
'''

BUSCTL = r'''#!/usr/bin/env python3
import json, os, sys

args = sys.argv[1:]
name = os.path.basename(sys.argv[0])
record = os.environ.get("MOCK_RECORD")
if record:
    with open(record, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"name": name, "argv": args}) + "\n")
if os.environ.get("MOCK_BUSCTL_FAIL") == "1":
    sys.exit(2)
if "NameHasOwner" in args:
    print("b true" if os.environ.get("MOCK_BUS_OWNED") == "1" else "b false")
    sys.exit(0)
if "status" in args:
    if os.environ.get("MOCK_BUS_OWNED") == "1":
        print("PID=" + os.environ.get("MOCK_BUS_PID", "4242"))
        sys.exit(0)
    print("No such name", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
'''

PROVIDERS = ("atlanta", "rofi-ctl", "swaync-client", "noctalia",
             "matugen-ctl", "noctalia-ctl")

A_ROUTES = (
    (("screenshot", "region"), ["screenshot", "region"]),
    (("screenshot", "screen"), ["screenshot", "screen"]),
    (("screenshot", "window"), ["screenshot", "window"]),
    (("wallpaper", "set", "/tmp/a.png"), ["wallpaper", "set", "/tmp/a.png"]),
    (("wallpaper", "next"), ["wallpaper", "next"]),
    (("wallpaper", "prev"), ["wallpaper", "prev"]),
    (("wallpaper", "random"), ["wallpaper", "random"]),
    (("wallpaper", "pick"), ["wallpaper", "pick"]),
    (("wallpaper", "status"), ["wallpaper", "status"]),
    (("session", "lock"), ["session", "lock"]),
    (("session", "menu"), ["session", "menu"]),
    (("session", "dpms", "off"), ["session", "dpms", "off"]),
    (("session", "logout"), ["session", "logout"]),
    (("session", "reboot"), ["session", "reboot"]),
    (("session", "poweroff"), ["session", "poweroff"]),
    (("idle", "toggle"), ["idle", "toggle"]),
    (("idle", "status"), ["idle", "status"]),
    (("nightlight", "toggle"), ["nightlight", "toggle"]),
    (("nightlight", "status"), ["nightlight", "status"]),
    (("volume", "up"), ["volume", "up"]),
    (("volume", "mute"), ["volume", "mute"]),
    (("mic", "toggle"), ["mic", "toggle"]),
    (("brightness", "down"), ["brightness", "down"]),
    (("bar", "show"), ["bar", "show"]),
    (("bar", "status", "--provider", "eww"),
     ["bar", "status", "--provider", "eww"]),
    (("bar", "use", "eww"), ["bar", "use", "eww"]),
    (("bar.panel", "toggle", "profile"), ["bar.panel", "toggle", "profile"]),
    (("osd", "volume"), ["osd", "volume"]),
)

UNSUPPORTED_ON_ATLANTA = (
    ("screenshot", "annotate"),
    ("caffeine", "toggle"),
    ("caffeine", "status"),
)

N_ROUTES = (
    (("launcher", "apps"), ["msg", "panel-toggle", "launcher"]),
    (("launcher", "run"), ["msg", "panel-toggle", "launcher", "/"]),
    (("launcher", "toggle"), ["msg", "panel-toggle", "launcher"]),
    (("launcher", "window"), ["msg", "window-switcher"]),
    (("notifications", "toggle"),
     ["msg", "panel-toggle", "control-center", "notifications"]),
    (("notifications", "dnd"), ["msg", "notification-dnd-toggle"]),
    (("notifications", "dnd", "on"), ["msg", "notification-dnd-set", "true"]),
    (("notifications", "dnd", "off"), ["msg", "notification-dnd-set", "false"]),
    (("notifications", "clear"), ["msg", "notification-clear-active"]),
    (("screenshot", "region"), ["msg", "screenshot-region"]),
    (("screenshot", "screen"), ["msg", "screenshot-fullscreen"]),
    (("screenshot", "window"), ["msg", "screenshot-window"]),
    (("screenshot", "annotate"), ["msg", "screenshot-annotate"]),
    (("wallpaper", "set", "/tmp/a.png"), ["msg", "wallpaper-set", "/tmp/a.png"]),
    (("wallpaper", "next"), ["msg", "wallpaper-next"]),
    (("wallpaper", "prev"), ["msg", "wallpaper-previous"]),
    (("wallpaper", "random"), ["msg", "wallpaper-random"]),
    (("wallpaper", "pick"), ["msg", "panel-toggle", "wallpaper"]),
    (("wallpaper", "status"), ["msg", "wallpaper-get"]),
    (("session", "menu"), ["msg", "panel-toggle", "session"]),
    (("session", "lock"), ["msg", "session", "lock"]),
    (("session", "logout"), ["msg", "session", "logout"]),
    (("session", "reboot"), ["msg", "session", "reboot"]),
    (("session", "poweroff"), ["msg", "session", "shutdown"]),
    (("session", "dpms", "off"), ["msg", "dpms-off"]),
    (("session", "dpms", "on"), ["msg", "dpms-on"]),
    (("caffeine", "toggle"), ["msg", "caffeine-toggle"]),
    (("nightlight", "toggle"), ["msg", "nightlight-force-toggle"]),
    (("volume", "up"), ["msg", "volume-up"]),
    (("volume", "down"), ["msg", "volume-down"]),
    (("volume", "mute"), ["msg", "volume-mute"]),
    (("mic", "toggle"), ["msg", "mic-mute"]),
    (("brightness", "up"), ["msg", "brightness-up"]),
    (("brightness", "down"), ["msg", "brightness-down"]),
    (("bar", "show"), ["msg", "bar-show"]),
    (("bar", "hide"), ["msg", "bar-hide"]),
    (("bar", "toggle"), ["msg", "bar-toggle"]),
    (("bar", "status"), ["msg", "status"]),
    (("osd", "volume"), ["msg", "volume-osd"]),
    (("osd", "mic"), ["msg", "mic-volume-osd"]),
)

UNSUPPORTED_ON_NOCTALIA = (
    ("idle", "toggle"),
    ("idle", "status"),
    ("caffeine", "status"),
    ("nightlight", "status"),
    ("bar", "use", "eww"),
    ("bar", "switch", "waybar"),
    ("bar.panel", "toggle", "profile"),
    ("osd", "brightness"),
)


class ConstelliaTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="constellia contract ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

        self.app = self.root / "constellia"
        shutil.copytree(CONSTELLIA_ROOT, self.app,
                        ignore=shutil.ignore_patterns("__pycache__"))
        self.script = self.app / "constellia"

        self.binaries = self.root / "backends"
        self.binaries.mkdir()
        for name in PROVIDERS:
            fake = self.binaries / name
            fake.write_text(MOCK)
            fake.chmod(0o755)
        for name, body in (("pgrep", PGREP), ("pkill", PKILL),
                           ("busctl", BUSCTL)):
            fake = self.binaries / name
            fake.write_text(body)
            fake.chmod(0o755)

        self.record = self.root / "calls.jsonl"
        self.procs = self.root / "procs"
        self.procs.mkdir()
        self.state = self.root / "state"
        self.theme_root = self.root / "theme-store"
        self.feel_root = self.root / "feel-store"
        self.theme_root.mkdir()
        self.feel_root.mkdir()

        base = {
            key: value for key, value in os.environ.items()
            if key not in ("NIRI_SOCKET", "HYPRLAND_INSTANCE_SIGNATURE",
                           "XDG_CURRENT_DESKTOP", "CONSTELLIA_WM",
                           "CONSTELLIA_SESSION", "CONSTELLIA_DRY_RUN",
                           "CONSTELLIA_JSON", "CONSTELLIA_BACKEND_DIR",
                           "XDG_STATE_HOME")
        }
        self.env = {
            **base,
            "PATH": f"{self.binaries}:{os.environ['PATH']}",
            "CONSTELLIA_BACKEND_DIR": str(self.binaries),
            "CONSTELLIA_WM": "hypr",
            "CONSTELLIA_BUS_TIMEOUT_MS": "200",
            "CONSTELLIA_NOCTALIA_TIMEOUT_MS": "200",
            "CONSTELLIA_STOP_TIMEOUT_MS": "200",
            "XDG_STATE_HOME": str(self.state),
            "THEME_ROOT": str(self.theme_root),
            "FEEL_ROOT": str(self.feel_root),
            "MOCK_RECORD": str(self.record),
            "MOCK_PROC_DIR": str(self.procs),
        }

    def call(self, *args, **overrides):
        return subprocess.run(
            [str(self.script), *args], capture_output=True, text=True,
            env={**self.env, **overrides}, timeout=20, cwd="/",
        )

    def calls(self, name=None):
        if not self.record.exists():
            return []
        rows = [json.loads(line) for line in self.record.read_text().splitlines()]
        return [row for row in rows if name is None or row["name"] == name]

    def reset(self):
        self.record.unlink(missing_ok=True)

    def set_shell(self, shell, wm="hypr"):
        directory = self.state / "constellia" / "shell"
        directory.mkdir(parents=True, exist_ok=True)
        (directory / wm).write_text(shell + "\n")

    def shell_state(self, wm="hypr"):
        return self.state / "constellia" / "shell" / wm

    def live(self, name, pid="4242"):
        (self.procs / name.upper().replace("-", "_")).write_text(pid + "\n")

    def dead(self, name):
        (self.procs / name.upper().replace("-", "_")).unlink(missing_ok=True)

    def link_store(self, engine="matugen", name="kanagawa-dragon-lotus",
                   profile="default"):
        palette = self.theme_root / "generated" / engine / name
        palette.mkdir(parents=True)
        (self.theme_root / "current").symlink_to(palette)
        feel = self.feel_root / "generated" / profile
        feel.mkdir(parents=True)
        (self.feel_root / "current").symlink_to(feel)

    def theme_state(self):
        return self.state / "constellia" / "theme"

    def write_theme_state(self, variant):
        self.theme_state().parent.mkdir(parents=True, exist_ok=True)
        self.theme_state().write_text(f"variant={variant}\nupdated=1\n")

    def assert_route(self, shell, backend, argv, *args, **env):
        self.set_shell(shell)
        self.reset()
        result = self.call(*args, **env)
        self.assertEqual(result.returncode, 0, f"{args}: {result.stderr}")
        self.assertEqual([row["argv"] for row in self.calls(backend)], [argv])
        self.assertEqual(len(self.calls()), 1, self.calls())

    def assert_unsupported(self, shell, *args):
        self.set_shell(shell)
        self.reset()
        result = self.call(*args)
        self.assertEqual(result.returncode, 3,
                         f"{args}: {result.stdout}{result.stderr}")
        self.assertIn("not supported", result.stderr)
        self.assertEqual(self.calls(), [])

    # --- CLI surface --------------------------------------------------------

    def test_help_lists_capabilities_and_exit_codes(self):
        result = self.call("help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: constellia", result.stdout)
        self.assertIn("bar.panel", result.stdout)
        self.assertIn("shell switch", result.stdout)
        self.assertIn("theme palette", result.stdout)
        self.assertIn("feel <profile>", result.stdout)
        self.assertIn("Exit: 0 ok", result.stdout)

    def test_unknown_capability_is_usage(self):
        result = self.call("resize")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown capability", result.stderr)

    def test_unknown_option_is_usage(self):
        result = self.call("--force", "status")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown option", result.stderr)

    def test_unknown_wm_override_is_usage(self):
        result = self.call("--wm", "sway", "status")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown wm", result.stderr)

    def test_shell_without_a_verb_is_usage(self):
        result = self.call("shell")
        self.assertEqual(result.returncode, 2)
        self.assertIn("shell needs a verb", result.stderr)

    def test_unknown_verb_is_usage_and_calls_nothing(self):
        self.reset()
        result = self.call("launcher", "dial")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown launcher verb", result.stderr)
        self.assertEqual(self.calls(), [])

    # --- Capability matrix --------------------------------------------------

    def test_atlanta_capability_matrix(self):
        for args, argv in A_ROUTES:
            with self.subTest(args=args):
                self.assert_route("atlanta", "atlanta", argv, *args)

    def test_atlanta_launcher_routes_to_rofi_ctl(self):
        for args, argv in ((("launcher", "apps"), ["apps"]),
                           (("launcher", "run"), ["run"]),
                           (("launcher", "window", "drun"), ["window", "drun"]),
                           (("launcher", "toggle"), ["toggle"])):
            with self.subTest(args=args):
                self.assert_route("atlanta", "rofi-ctl", argv, *args)

    def test_atlanta_notifications_routes_to_swaync(self):
        for args, argv in ((("notifications", "toggle"), ["-t"]),
                           (("notifications", "dnd"), ["-d"]),
                           (("notifications", "dnd", "on"), ["-d", "-sw"]),
                           (("notifications", "dnd", "off"), ["-df"]),
                           (("notifications", "clear"), ["-C"])):
            with self.subTest(args=args):
                self.assert_route("atlanta", "swaync-client", argv, *args)

    def test_noctalia_capability_matrix(self):
        for args, argv in N_ROUTES:
            with self.subTest(args=args):
                self.assert_route("noctalia", "noctalia", argv, *args)

    def test_unsupported_capabilities_on_noctalia(self):
        for args in UNSUPPORTED_ON_NOCTALIA:
            with self.subTest(args=args):
                self.assert_unsupported("noctalia", *args)

    def test_unsupported_capabilities_on_atlanta(self):
        for args in UNSUPPORTED_ON_ATLANTA:
            with self.subTest(args=args):
                self.assert_unsupported("atlanta", *args)

    def test_screenshot_directory_is_forwarded_to_atlanta(self):
        self.set_shell("atlanta")
        self.reset()
        shots = self.root / "shots"
        result = self.call("screenshot", "region",
                           CONSTELLIA_SCREENSHOT_DIR=str(shots),
                           MOCK_ECHO_ENV="ATLANTA_SCREENSHOT_DIR")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(shots), result.stdout)

    # --- State --------------------------------------------------------------

    def test_missing_state_file_means_atlanta(self):
        result = self.call("shell", "status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr=atlanta", result.stdout)
        self.assertIn("niri=atlanta", result.stdout)

    def test_shell_use_writes_only_the_current_wm(self):
        result = self.call("shell", "use", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")
        self.assertFalse(self.shell_state("niri").exists())
        self.assertIn("shell hypr: noctalia", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_shell_use_on_niri_leaves_hypr_alone(self):
        self.set_shell("atlanta", "hypr")
        result = self.call("shell", "use", "noctalia",
                           CONSTELLIA_WM="niri")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state("niri").read_text().strip(), "noctalia")
        self.assertEqual(self.shell_state("hypr").read_text().strip(), "atlanta")

    def test_shell_use_rejects_an_unknown_shell(self):
        result = self.call("shell", "use", "sway")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown shell", result.stderr)
        self.assertFalse(self.shell_state().exists())

    def test_invalid_state_value_falls_back_to_atlanta_with_a_warning(self):
        self.shell_state().parent.mkdir(parents=True)
        self.shell_state().write_text("sway\n")
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr=atlanta state-invalid: sway", result.stdout)
        self.assertIn("unknown shell 'sway'", result.stderr)

        routed = self.call("notifications", "toggle")
        self.assertEqual(routed.returncode, 0, routed.stderr)
        self.assertEqual(self.calls("swaync-client")[-1]["argv"], ["-t"])

    def test_status_reports_drift_when_the_recorded_shell_is_not_alive(self):
        self.set_shell("noctalia")
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr=noctalia", result.stdout)
        self.assertIn("drift: hypr says noctalia, live is none", result.stdout)

    def test_status_has_no_drift_when_the_shell_is_alive(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("drift:", result.stdout)

    def test_status_detects_a_stale_atlanta_state(self):
        self.set_shell("atlanta")
        self.live("noctalia")
        result = self.call("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("drift: hypr says atlanta, live is noctalia", result.stdout)

    def test_status_json_is_valid(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        result = self.call("status", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["wm"], "hypr")
        self.assertEqual(payload["shell"], "noctalia")
        self.assertEqual(payload["live"], "noctalia")
        self.assertFalse(payload["drift"])
        self.assertEqual(payload["shells"], {"hypr": "noctalia", "niri": "atlanta"})
        self.assertEqual(payload["invalid"], {"hypr": None, "niri": None})

    def test_status_json_reports_an_invalid_state_file(self):
        self.shell_state().parent.mkdir(parents=True)
        self.shell_state().write_text("sway\n")
        result = self.call("status", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["shell"], "atlanta")
        self.assertEqual(payload["invalid"]["hypr"], "sway")

    def test_status_is_read_only(self):
        self.set_shell("noctalia")
        before = self.shell_state().read_text()
        self.call("status")
        self.assertEqual(self.shell_state().read_text(), before)

    def test_unknown_wm_still_reports_both_states(self):
        result = self.call("status", CONSTELLIA_WM="",
                           XDG_CURRENT_DESKTOP="")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr=atlanta", result.stdout)
        self.assertIn("niri=atlanta", result.stdout)
        self.assertNotIn("drift:", result.stdout)

    def test_shell_use_needs_a_compositor(self):
        result = self.call("shell", "use", "noctalia", CONSTELLIA_WM="",
                           XDG_CURRENT_DESKTOP="")
        self.assertEqual(result.returncode, 3)
        self.assertIn("needs a compositor", result.stderr)

    # --- Switch -------------------------------------------------------------

    def test_switch_to_noctalia_stops_atlanta_then_waits_then_starts(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "switch", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")
        sequence = [row["name"] for row in self.calls() if row["name"] != "pgrep"]
        self.assertEqual(sequence, ["atlanta", "busctl", "noctalia", "noctalia"])
        self.assertEqual(self.calls("atlanta")[0]["argv"], ["stop"])
        self.assertEqual(self.calls("noctalia")[0]["argv"], ["-d"])
        self.assertEqual(self.calls("noctalia")[1]["argv"], ["msg", "status"])

    def test_switch_to_noctalia_refuses_when_the_bus_is_still_owned(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "switch", "noctalia",
                           MOCK_BUS_OWNED="1", MOCK_BUS_PID="4242")
        self.assertEqual(result.returncode, 4)
        self.assertIn("4242", result.stderr)
        self.assertEqual(self.calls("noctalia"), [])
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"], ["start"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_switch_to_noctalia_rolls_back_when_the_bus_cannot_be_queried(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "switch", "noctalia",
                           MOCK_BUSCTL_FAIL="1")
        self.assertEqual(result.returncode, 4)
        self.assertIn("cannot query", result.stderr)
        self.assertEqual(self.calls("noctalia"), [])
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"], ["start"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_switch_to_noctalia_keeps_state_when_the_daemon_fails(self):
        self.set_shell("atlanta")
        result = self.call("shell", "switch", "noctalia",
                           MOCK_NOCTALIA_D_EXIT="1")
        self.assertEqual(result.returncode, 1)
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"], ["start"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_switch_to_noctalia_keeps_state_when_it_never_answers(self):
        self.set_shell("atlanta")
        result = self.call("shell", "switch", "noctalia",
                           MOCK_NOCTALIA_MSG_EXIT="1")
        self.assertEqual(result.returncode, 1)
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"], ["start"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_switch_to_noctalia_adopts_a_running_daemon(self):
        self.set_shell("atlanta")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "switch", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")
        self.assertEqual(self.calls("noctalia"), [{"name": "noctalia",
                                                   "argv": ["msg", "status"]}])
        self.assertEqual(self.calls("busctl"), [])

    def test_switch_to_the_same_shell_is_a_pure_noop(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "switch", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already noctalia", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_switch_to_atlanta_stops_noctalia_then_starts_atlanta(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "switch", "atlanta")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")
        sequence = [row["name"] for row in self.calls() if row["name"] != "pgrep"]
        self.assertEqual(sequence, ["pkill", "atlanta"])
        self.assertEqual(self.calls("pkill")[0]["argv"],
                         ["-TERM", "-f", "(^|/)noctalia$"])
        self.assertEqual(self.calls("atlanta")[0]["argv"], ["start"])

    def test_switch_to_atlanta_escalates_to_kill(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "switch", "atlanta",
                           MOCK_PKILL_IGNORE_TERM="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("pkill")],
                         [["-TERM", "-f", "(^|/)noctalia$"],
                          ["-KILL", "-f", "(^|/)noctalia$"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_switch_to_atlanta_gives_up_and_keeps_state(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "switch", "atlanta",
                           MOCK_PKILL_IGNORE_TERM="1",
                           MOCK_PKILL_IGNORE_KILL="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("still running after KILL", result.stderr)
        self.assertEqual(self.calls("atlanta"), [])
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")

    def test_switch_to_atlanta_rolls_back_when_start_fails(self):
        self.set_shell("noctalia")
        self.dead("noctalia")
        self.reset()
        result = self.call("shell", "switch", "atlanta",
                           MOCK_ATLANTA_START_EXIT="1")
        self.assertEqual(result.returncode, 1)
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["start"], ["stop"]])
        self.assertEqual([row["argv"] for row in self.calls("noctalia")],
                         [["-d"], ["msg", "status"]])
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")

    def test_switch_does_not_touch_the_other_wm(self):
        self.set_shell("atlanta", "hypr")
        self.set_shell("atlanta", "niri")
        result = self.call("shell", "switch", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state("hypr").read_text().strip(), "noctalia")
        self.assertEqual(self.shell_state("niri").read_text().strip(), "atlanta")

    # --- Select -------------------------------------------------------------

    def test_shell_select_switches_to_the_chosen_noctalia(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "select",
                           MOCK_ROFI_CTL_SHELL_OUT="Noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")
        # The card for the recorded shell is the one highlighted.
        self.assertEqual([row["argv"] for row in self.calls("rofi-ctl")],
                         [["shell", "-selected-row", "1"]])
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"]])
        self.assertIn("shell hypr: noctalia", result.stdout)

    def test_shell_select_switches_to_the_chosen_native_atlanta(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "select",
                           MOCK_ROFI_CTL_SHELL_OUT="Native")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")
        self.assertEqual([row["argv"] for row in self.calls("rofi-ctl")],
                         [["shell", "-selected-row", "0"]])
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["start"]])

    def test_shell_select_accepts_a_renamed_atlanta_card(self):
        self.set_shell("noctalia")
        self.dead("noctalia")
        self.reset()
        result = self.call("shell", "select",
                           MOCK_ROFI_CTL_SHELL_OUT="Atlanta")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_shell_select_cancel_changes_nothing(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "select", MOCK_ROFI_CTL_SHELL_EXIT="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")
        self.assertEqual([row["name"] for row in self.calls()], ["rofi-ctl"])

    def test_shell_select_rejects_an_unknown_label(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "select", MOCK_ROFI_CTL_SHELL_OUT="Sway")
        self.assertEqual(result.returncode, 2)
        self.assertIn("unknown shell choice", result.stderr)
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")
        self.assertEqual([row["name"] for row in self.calls()], ["rofi-ctl"])

    def test_shell_select_on_the_active_shell_is_a_noop(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "select",
                           MOCK_ROFI_CTL_SHELL_OUT="Noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already noctalia", result.stdout)
        self.assertEqual([row["name"] for row in self.calls()], ["rofi-ctl"])

    def test_shell_select_dry_run_prints_the_picker_and_stops(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("--dry-run", "shell", "select")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[dry] rofi-ctl shell -selected-row 1", result.stdout)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_shell_select_takes_no_arguments(self):
        result = self.call("shell", "select", "noctalia")
        self.assertEqual(result.returncode, 2)
        self.assertIn("takes no arguments", result.stderr)

    def test_shell_select_needs_a_compositor(self):
        result = self.call("shell", "select", CONSTELLIA_WM="",
                           XDG_CURRENT_DESKTOP="")
        self.assertEqual(result.returncode, 3)
        self.assertIn("needs a compositor", result.stderr)

    # --- Start and stop -----------------------------------------------------

    def test_shell_start_starts_the_recorded_atlanta_stack(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["start"]])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_shell_start_boots_noctalia_without_writing_state(self):
        self.set_shell("noctalia")
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("noctalia")],
                         [["-d"], ["msg", "status"]])
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")

    def test_shell_start_is_idempotent_for_noctalia(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already running noctalia", result.stdout)
        self.assertEqual(self.calls("noctalia"), [])

    def test_shell_start_refuses_atlanta_when_noctalia_is_alive(self):
        self.set_shell("atlanta")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 4)
        self.assertIn("refusing to start a second stack", result.stderr)
        self.assertEqual(self.calls("atlanta"), [])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    def test_shell_start_refuses_noctalia_when_the_atlanta_stack_is_alive(self):
        self.set_shell("noctalia")
        self.live("eww")
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 4)
        self.assertIn("refusing to start a second stack", result.stderr)
        self.assertEqual(self.calls("noctalia"), [])
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")

    def test_shell_start_does_not_write_a_missing_state_file(self):
        self.reset()
        result = self.call("shell", "start")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.shell_state().exists())

    def test_shell_stop_stops_noctalia_without_writing_state(self):
        self.set_shell("noctalia")
        self.live("noctalia")
        self.reset()
        result = self.call("shell", "stop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("pkill")],
                         [["-TERM", "-f", "(^|/)noctalia$"]])
        self.assertEqual(self.shell_state().read_text().strip(), "noctalia")

    def test_shell_stop_stops_the_atlanta_stack(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("shell", "stop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("atlanta")],
                         [["stop"]])

    def test_shell_stop_is_idempotent(self):
        self.set_shell("noctalia")
        self.reset()
        result = self.call("shell", "stop")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not running noctalia", result.stdout)

    # --- Dry run ------------------------------------------------------------

    def test_dry_run_prints_the_backend_argv_and_runs_nothing(self):
        self.set_shell("noctalia")
        self.reset()
        result = self.call("--dry-run", "notifications", "toggle")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "[dry] noctalia msg panel-toggle control-center notifications",
            result.stdout)
        self.assertEqual(self.calls(), [])

    def test_dry_run_environment_variable(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("wallpaper", "next", CONSTELLIA_DRY_RUN="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[dry] atlanta wallpaper next", result.stdout)
        self.assertEqual(self.calls(), [])

    def test_dry_run_switch_prints_the_plan_and_keeps_state(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("--dry-run", "shell", "switch", "noctalia")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[dry] atlanta stop", result.stdout)
        self.assertIn("[dry] noctalia -d", result.stdout)
        self.assertIn("=noctalia", result.stdout)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.shell_state().read_text().strip(), "atlanta")

    # --- Doctor and resolution ---------------------------------------------

    def test_doctor_lists_the_resolved_backends_and_session(self):
        self.set_shell("noctalia")
        result = self.call("doctor")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hypr", result.stdout)
        self.assertIn("noctalia", result.stdout)
        self.assertIn(str(self.binaries / "atlanta"), result.stdout)
        self.assertIn(str(self.binaries / "noctalia"), result.stdout)
        self.assertIn(str(self.binaries / "busctl"), result.stdout)

    def test_doctor_json_is_valid(self):
        result = self.call("doctor", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["wm"], "hypr")
        self.assertEqual(payload["backends"]["atlanta"],
                         str(self.binaries / "atlanta"))

    # --- Theme and feel -----------------------------------------------------

    def test_theme_status_without_a_store_is_null(self):
        result = self.call("theme", "status", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            "engine": None, "palette": None, "variant": None, "feel": None,
            "wm": "hypr", "shell": "atlanta",
        })

    def test_theme_status_derives_the_store_and_reads_the_variant(self):
        self.set_shell("noctalia")
        self.link_store(engine="noctalia", name="wallpaper-based")
        self.write_theme_state("dark")
        result = self.call("theme", "status", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["engine"], "noctalia")
        self.assertEqual(payload["palette"], "wallpaper-based")
        self.assertEqual(payload["variant"], "dark")
        self.assertEqual(payload["feel"], "default")
        self.assertEqual(payload["wm"], "hypr")
        self.assertEqual(payload["shell"], "noctalia")

    def test_theme_status_text_marks_an_unknown_variant(self):
        self.link_store()
        result = self.call("theme", "status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"engine\s+matugen")
        self.assertRegex(result.stdout, r"palette\s+kanagawa-dragon-lotus")
        self.assertRegex(result.stdout, r"variant\s+unknown")
        self.assertRegex(result.stdout, r"feel\s+default")

    def test_theme_status_is_read_only(self):
        self.link_store()
        result = self.call("theme", "status", "--json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.theme_state().exists())

    def test_theme_palette_routes_to_matugen_on_atlanta(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("theme", "palette", "/tmp/wall.png")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([row["argv"] for row in self.calls("matugen-ctl")],
                         [["palette", "/tmp/wall.png"]])
        self.assertFalse(self.calls("noctalia-ctl"))
        self.assertIn("variant=dark", self.theme_state().read_text())

    def test_theme_palette_routes_to_noctalia_and_passes_options(self):
        self.set_shell("noctalia")
        self.reset()
        result = self.call("theme", "palette", "--from-shell", "-N")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            [row["argv"] for row in self.calls("noctalia-ctl")],
            [["palette", "--from-shell", "-N"]])
        self.assertFalse(self.calls("matugen-ctl"))
        self.assertFalse(self.theme_state().exists())

    def test_theme_palette_writes_the_light_variant_from_a_blueprint(self):
        self.set_shell("atlanta")
        result = self.call("theme", "palette", "/tmp/kanagawa-light.json")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("variant=light", self.theme_state().read_text())

    def test_theme_palette_reload_writes_nothing(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("theme", "palette")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.theme_state().exists())
        self.assertEqual(self.calls("matugen-ctl")[0]["argv"], ["palette"])

    def test_theme_palette_list_writes_nothing(self):
        self.set_shell("noctalia")
        result = self.call("theme", "palette", "--list")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.theme_state().exists())

    def test_theme_palette_local_dry_run_writes_nothing(self):
        self.set_shell("atlanta")
        result = self.call("theme", "palette", "-n", "/tmp/wall.png")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.theme_state().exists())

    def test_theme_palette_failure_keeps_the_recorded_variant(self):
        self.set_shell("atlanta")
        self.write_theme_state("light")
        result = self.call("theme", "palette", "/tmp/wall.png",
                           MOCK_MATUGEN_CTL_PALETTE_EXIT="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("variant=light", self.theme_state().read_text())

    def test_theme_palette_global_dry_run_runs_nothing(self):
        self.set_shell("atlanta")
        self.reset()
        result = self.call("--dry-run", "theme", "palette", "/tmp/wall.png")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[dry] matugen-ctl palette /tmp/wall.png", result.stdout)
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.theme_state().exists())

    def test_feel_always_routes_to_matugen(self):
        for shell in ("atlanta", "noctalia"):
            with self.subTest(shell=shell):
                self.set_shell(shell)
                self.reset()
                result = self.call("feel", "default")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    [row["argv"] for row in self.calls("matugen-ctl")],
                    [["feel", "default", "--wm", "hypr"]])

    def test_feel_without_a_profile_is_usage(self):
        result = self.call("feel")
        self.assertEqual(result.returncode, 2)
        self.assertIn("feel needs a profile", result.stderr)
        self.assertEqual(self.calls(), [])

    def test_missing_backend_exits_127(self):
        empty = self.root / "empty"
        empty.mkdir()
        minimal = self.root / "minimal"
        minimal.mkdir()
        for name in ("bash", "readlink", "dirname", "env"):
            (minimal / name).symlink_to(shutil.which(name))
        result = self.call(
            "launcher", "apps",
            CONSTELLIA_BACKEND_DIR=str(empty), PATH=str(minimal))
        self.assertEqual(result.returncode, 127)
        self.assertIn("missing", result.stderr)

    # --- Install ------------------------------------------------------------

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
        self.assertTrue((bin_dir / "constellia").is_symlink())
        self.assertTrue((fish_dir / "constellia.fish").is_symlink())

        foreign = self.root / "foreign"
        foreign.write_text("keep me")
        (bin_dir / "foreign").symlink_to(foreign)

        removed = subprocess.run(
            ["bash", str(self.app / "install.sh"), "--remove"],
            capture_output=True, text=True, timeout=15, cwd="/", env=env,
        )
        self.assertEqual(removed.returncode, 0, removed.stderr)
        self.assertFalse((bin_dir / "constellia").exists())
        self.assertFalse((fish_dir / "constellia.fish").exists())
        self.assertTrue((bin_dir / "foreign").is_symlink())


if __name__ == "__main__":
    unittest.main()
