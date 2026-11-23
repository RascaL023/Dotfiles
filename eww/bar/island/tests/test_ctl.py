"""Contract tests for eww-ctl: one launcher, island stop, paths and environment."""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

EWW = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(EWW / "bar" / "island" / "scripts"))
from common import MODULE, runtime_dir  # noqa: E402

loader = importlib.machinery.SourceFileLoader("eww_ctl", str(EWW / "eww-ctl"))
spec = importlib.util.spec_from_loader("eww_ctl", loader)
ctl = importlib.util.module_from_spec(spec)
loader.exec_module(ctl)


class Layout(unittest.TestCase):
    def test_root_includes_and_scss_imports_resolve(self):
        includes = re.findall(r'\(include "([^"]+)"\)', (EWW / "eww.yuck").read_text())
        self.assertIn("bar/island/island.yuck", includes)
        for include in includes:
            self.assertTrue((EWW / include).is_file(), include)
        scss = (EWW / "eww.scss").read_text()
        self.assertEqual(scss.count("all: unset;"), 1)
        for target in re.findall(r'@import "([^"]+)"', scss):
            if target.startswith("/"):
                continue
            base = EWW / target
            candidates = (base.with_suffix(".scss"), base.parent / ("_" + base.name + ".scss"))
            self.assertTrue(any(path.is_file() for path in candidates), target)

    def test_module_has_no_nested_includes_and_no_bar_names(self):
        module = (MODULE / "island.yuck").read_text()
        self.assertNotIn("(include ", module)
        self.assertIn("python3 ./bar/island/scripts/adapter.py listen", module)
        self.assertNotIn("{bar.", module)
        self.assertNotRegex(module, r"\bbar\.")
        for path in sorted((MODULE / "widgets").glob("*.yuck")):
            text = path.read_text()
            self.assertNotIn("(include ", text, path.name)
            self.assertNotIn("{bar.", text, path.name)
            self.assertNotRegex(text, r"\bbar\.", path.name)
            self.assertNotIn("EWW_BAR_EVENTS", text, path.name)
            self.assertNotIn("./barctl", text, path.name)

    def test_window_classes_exist_in_the_island_stylesheet(self):
        window = (MODULE / "window.yuck").read_text()
        styles = (MODULE / "styles/_island.scss").read_text()
        for name in ("island-frame", "islands-window"):
            self.assertIn(name, window)
            self.assertIn("." + name, styles)
        self.assertNotIn("bar-frame", styles)

    def test_widget_callbacks_point_at_the_launcher(self):
        text = "\n".join(p.read_text() for p in sorted((MODULE / "widgets").glob("*.yuck")))
        self.assertIn("./eww-ctl bar island action launcher", text)
        self.assertTrue(os.access(EWW / "eww-ctl", os.X_OK))


class RuntimeIsolation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.env = patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.temp.name})
        self.env.start()

    def tearDown(self):
        self.env.stop()
        self.temp.cleanup()


class IslandStop(RuntimeIsolation):
    def setUp(self):
        super().setUp()
        self.calls = []

    def fake_eww(self, *args, check=True):
        self.calls.append(args)
        return subprocess.CompletedProcess(args, 0, "", "")

    def test_stop_closes_only_island_windows_and_keeps_the_daemon(self):
        with patch.object(ctl, "eww", self.fake_eww), \
                patch.object(ctl, "windows", return_value=["islands", "profile", "music-popup"]), \
                patch("actions.request", side_effect=OSError("not running")):
            ctl.island_stop()
        self.assertEqual([args[1] for args in self.calls if args[0] == "close"],
                         ["islands", "music-popup"])
        self.assertNotIn("kill", [args[0] for args in self.calls])


class DaemonStart(RuntimeIsolation):
    class Proc:
        pid = 4321

        def poll(self):
            return None

    def test_launcher_always_injects_the_island_events_fifo(self):
        captured = {}

        def popen(argv, **kwargs):
            captured["argv"] = argv
            captured.update(kwargs)
            return self.Proc()

        with patch.object(ctl, "alive", side_effect=[False, True]), \
                patch.object(ctl, "identity", return_value=99), \
                patch("subprocess.Popen", popen):
            ctl.spawn_daemon()
        self.assertEqual(captured["env"]["EWW_ISLAND_EVENTS"], str(runtime_dir() / "events.fifo"))
        self.assertIn("daemon", captured["argv"])
        self.assertEqual(json.loads((runtime_dir() / "daemon.pid").read_text()),
                         {"pid": 4321, "start": 99})

    def test_daemon_env_is_the_single_source_of_the_fifo(self):
        self.assertEqual(ctl.daemon_env()["EWW_ISLAND_EVENTS"],
                         str(runtime_dir() / "events.fifo"))


class Parser(unittest.TestCase):
    def setUp(self):
        self.stdout = io.StringIO()
        self.stderr = io.StringIO()
        self.redirects = contextlib.ExitStack()
        self.redirects.enter_context(contextlib.redirect_stdout(self.stdout))
        self.redirects.enter_context(contextlib.redirect_stderr(self.stderr))

    def tearDown(self):
        self.redirects.close()

    def test_help_and_usage_errors(self):
        self.assertEqual(ctl.main(["--help"]), 0)
        self.assertIn("bar island", self.stdout.getvalue())
        self.assertEqual(ctl.main([]), 2)
        self.assertEqual(ctl.main(["island", "status"]), 2)
        self.assertEqual(ctl.main(["open"]), 2)
        self.assertEqual(ctl.main(["bar"]), 2)
        self.assertEqual(ctl.main(["bar", "island"]), 2)
        self.assertEqual(ctl.main(["bar", "island", "bogus"]), 2)
        self.assertEqual(ctl.main(["bar", "island", "start", "--monitor"]), 2)
        self.assertEqual(ctl.main(["daemon"]), 2)

    def test_monitor_forms_reach_the_handler(self):
        # Patch windows so toggle never depends on the live daemon.
        with patch.object(ctl, "island_start") as start, patch.object(ctl, "windows", return_value=[]):
            self.assertEqual(ctl.main(["bar", "island", "start", "--monitor", "LVDS-1"]), 0)
            self.assertEqual(start.call_args.args[1], "LVDS-1")
            self.assertEqual(ctl.main(["bar", "island", "toggle", "--monitor=DP-1"]), 0)
            self.assertEqual(start.call_args.args[1], "DP-1")

    def test_action_keeps_name_and_argument(self):
        with patch("actions.local_action") as local:
            local.return_value = True
            self.assertEqual(ctl.main(["bar", "island", "action", "workspace", "3"]), 0)
            local.assert_called_once()
            self.assertEqual(local.call_args.args[0], "workspace")


if __name__ == "__main__":
    unittest.main()
