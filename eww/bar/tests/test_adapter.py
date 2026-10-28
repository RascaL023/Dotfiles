import asyncio
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from common import ROOT, compositor_name, initial_state, settings
from sources import (Commands, Hyprland, Niri, PipeWireEvents, battery_state, brightness_state, choose_player, music_players,
                     music_state, network_state, nm_fields, notification_state,
                     volume_state, workspace_state, niri_workspace_state)
from adapter import Collector
from actions import dispatch, power_menu


def player(name="mpd", status="Playing", kind="mpd"):
    return {"key": name if kind == "mpd" else "mpris:" + name, "name": name,
            "kind": kind, "status": status, "title": '曲 "quote" \\ $(`cmd`)\nline',
            "artist": "Björk\n日本語"}


class Parsers(unittest.TestCase):
    def setUp(self):
        self.cfg = settings()

    def test_complete_initial_schema(self):
        line = (ROOT / "eww.yuck").read_text().splitlines()[1]
        initial = json.loads(json.loads(line.split(":initial ", 1)[1]))
        def schema(value):
            if isinstance(value, dict):
                return {k: schema(v) for k, v in value.items()}
            if isinstance(value, list):
                return [schema(value[0])] if value else []
            return type(value)
        self.assertEqual(schema(initial), schema(initial_state(self.cfg)))

    def test_workspaces_include_active_empty_and_occupied_extras(self):
        state = workspace_state([{"id": 8, "windows": 1, "name": 'eight"\\'},
                                 {"id": 9, "windows": 0}, {"id": -99, "windows": 1}],
                                {"id": 10}, [1, 2, 3, 4, 5])
        self.assertEqual([w["id"] for w in state["items"]], [1, 2, 3, 4, 5, 8, 10])
        self.assertTrue(state["items"][-1]["active"])

    def test_compositor_detection_and_niri_stable_ids(self):
        self.assertEqual(compositor_name({"compositor": "auto"}, {
            "XDG_CURRENT_DESKTOP": "niri", "HYPRLAND_INSTANCE_SIGNATURE": "stale"}), "niri")
        self.assertEqual(compositor_name({"compositor": "auto"}, {
            "XDG_CURRENT_DESKTOP": "Hyprland", "NIRI_SOCKET": "stale"}), "hyprland")
        rows = [{"id": 99, "idx": 2, "output": "DP-1", "active_window_id": None},
                {"id": 42, "idx": 1, "output": "DP-1", "active_window_id": 6, "is_active": True,
                 "is_focused": True, "name": '日本語 " \\'},
                {"id": 2, "idx": 1, "output": "HDMI-A-1"}]
        state = niri_workspace_state(rows, "DP-1")
        self.assertEqual([w["id"] for w in state["items"]], [42, 99])
        self.assertEqual([w["label"] for w in state["items"]], ["1", "2"])
        self.assertTrue(state["items"][0]["occupied"])
        self.assertEqual(niri_workspace_state(rows, "0"), state)
        self.assertFalse(Niri().relevant(b'{"WindowLayoutsChanged": {}}'))
        self.assertTrue(Niri().relevant(b'{"WorkspaceActivated": {"id":42}}'))

    def test_network_escaping_and_no_wifi_scan(self):
        raw = r'wlan9:wifi:connected:Café\: "hi" \\ ☕'
        self.assertEqual(nm_fields(raw)[3], 'Café: "hi" \\ ☕')
        self.assertIn('Café: "hi" \\ ☕', network_state(raw)["tooltip"])
        self.assertEqual(network_state("lo:loopback:connected (externally):lo")["icon"], "󰤭")
        self.assertIsNone(network_state(None))

    def test_volume_and_notifications(self):
        self.assertTrue(volume_state("Volume: 0.45 [MUTED]")["muted"])
        self.assertEqual(volume_state("Volume: 1.20")["percent"], 120)
        for percent, icon in ((0, "󰖁"), (1, "󰕿"), (33, "󰕿"), (34, "󰖀"),
                              (50, "󰖀"), (66, "󰖀"), (67, "󰕾"), (100, "󰕾"), (120, "󰕾")):
            with self.subTest(percent=percent):
                self.assertEqual(volume_state(f"Volume: {percent / 100:.2f}")["icon"], icon)
                self.assertEqual(volume_state(f"Volume: {percent / 100:.2f} [MUTED]")["icon"], "󰝟")
        self.assertIsNone(volume_state(""))
        self.assertEqual(notification_state('{"count":3,"dnd":true}')["count"], 3)
        self.assertTrue(notification_state('{"dnd":"true"}')["dnd"])

    def test_pipewire_chunks_ignore_wpctl_clients_and_unchanged_props(self):
        events = PipeWireEvents()
        node = [{"id": 58, "info": {"props": {"media.class": "Audio/Sink", "node.name": "音声"},
                                       "params": {"Props": [{"mute": False, "channelVolumes": [.5, .5]}]}}}]
        raw = json.dumps(node, ensure_ascii=False).encode()
        changes = [events.feed(raw[i:i + 1]) for i in range(len(raw))]
        self.assertEqual(sum(changes), 1)
        self.assertFalse(events.feed(json.dumps(node).encode()))
        clients = [{"id": 900, "type": "PipeWire:Interface:Client", "info": {"props": {"application.name": "wpctl"}}},
                   {"id": 900, "info": None}]
        self.assertFalse(events.feed(json.dumps(clients).encode()))
        self.assertFalse(events.feed(b'[{"id":58,"info":{"state":"running"}}]'))
        self.assertTrue(events.feed(b'[{"id":58,"info":{"params":{"Props":[{"mute":true}]}}}]'))
        default = b'[{"id":43,"metadata":[{"key":"default.audio.sink","value":{"name":"new"}}]}]'
        self.assertTrue(events.feed(default + default))
        self.assertFalse(events.feed(default))
        self.assertTrue(events.feed(b'[{"id":58,"info":null}]'))

    def test_battery_detection_charging_removal_and_multiple(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.assertIsNone(battery_state(root))
            for name, capacity, status in (("BAT7", 20, "Discharging"), ("CMB1", 60, "Charging")):
                path = root / name
                path.mkdir()
                for key, value in {"type": "Battery", "capacity": str(capacity), "status": status}.items():
                    (path / key).write_text(value)
            state = battery_state(root)
            self.assertEqual(state["text"], "40%")
            self.assertEqual(state["icon"], "󰂈")
            self.assertFalse(state["warning"])
            (root / "CMB1/present").write_text("0")
            self.assertTrue(battery_state(root)["warning"])
            (root / "BAT7/capacity").write_text("invalid")
            self.assertIsNone(battery_state(root))

    def test_battery_icons_follow_capacity_and_charging(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            battery = root / "BAT7"
            battery.mkdir()
            (battery / "type").write_text("Battery")
            cases = ((0, "󰂎", "󰢟"), (9, "󰂎", "󰢟"), (10, "󰁺", "󰢜"),
                     (19, "󰁺", "󰢜"), (20, "󰁻", "󰂆"), (37, "󰁼", "󰂇"),
                     (50, "󰁾", "󰢝"), (99, "󰂂", "󰂋"), (100, "󰁹", "󰂅"))
            for percent, normal, charging in cases:
                (battery / "capacity").write_text(str(percent))
                for status, icon in (("Discharging", normal), ("Charging", charging)):
                    with self.subTest(percent=percent, status=status):
                        (battery / "status").write_text(status)
                        state = battery_state(root)
                        self.assertEqual(state["icon"], icon)
                        self.assertEqual(state["warning"], percent <= 20 and status != "Charging")
            (battery / "status").write_text("Full")
            self.assertEqual(battery_state(root)["icon"], "󰁹")

    def test_backlight_detection_selection_and_bounds(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.assertIsNone(brightness_state(root=root))
            for name, kind, level, maximum in (("acpi0", "firmware", 25, 100),
                                               ("panel9", "raw", 500, 1000)):
                path = root / name
                path.mkdir()
                for key, value in {"type": kind, "brightness": level, "max_brightness": maximum}.items():
                    (path / key).write_text(str(value))
            self.assertEqual(brightness_state(root=root)["device"], "panel9")
            self.assertEqual(brightness_state(root=root)["percent"], 50)
            self.assertEqual(brightness_state("acpi0", root)["percent"], 25)
            self.assertIsNone(brightness_state("missing", root))
            for level, expected in ((-5, 0), (0, 0), (2000, 100)):
                (root / "panel9/brightness").write_text(str(level))
                self.assertEqual(brightness_state(root=root)["percent"], expected)
            (root / "panel9/max_brightness").write_text("0")
            self.assertEqual(brightness_state(root=root)["device"], "acpi0")
            (root / "acpi0/brightness").write_text("invalid")
            self.assertIsNone(brightness_state(root=root))

    def test_player_priority_sticky_and_bridge_deduplication(self):
        cfg = self.cfg["music"]
        native = player()
        bridge = player("mpd.instance42", kind="mpris")
        other = player("spotify", kind="mpris")
        self.assertEqual(choose_player([native, bridge], bridge["key"], cfg), native)
        self.assertEqual(choose_player([native, other], other["key"], cfg), other)
        self.assertEqual(choose_player([player(status="Paused"), other], "mpd", cfg), other)
        self.assertEqual(choose_player([bridge], "mpd", cfg), bridge)
        self.assertIsNone(choose_player([], "mpd", cfg))

    def test_metadata_remains_text_and_json_has_one_line(self):
        value = music_state(player(), self.cfg["music"])
        self.assertLessEqual(len(value["title"]), 24)
        self.assertNotIn("\n", value["title"])
        self.assertIn('"quote" \\', value["tooltip"])
        encoded = json.dumps(value, ensure_ascii=False)
        self.assertEqual(len(encoded.splitlines()), 1)
        self.assertEqual(json.loads(encoded), value)

    def test_power_confirmation_and_cancel_for_all_destructive_actions(self):
        for label, action in (("Logout", "logout"), ("Restart", "reboot"), ("Shutdown", "shutdown")):
            for confirm in (False, True):
                calls = []
                responses = [label, "Ya, " + label if confirm else "Batal", ""]
                def run(argv, **kwargs):
                    calls.append(argv)
                    return subprocess.CompletedProcess(argv, 0, responses[len(calls) - 1])
                power_menu(self.cfg, run)
                self.assertEqual(len(calls), 3 if confirm else 2)
                if confirm:
                    self.assertEqual(calls[-1], self.cfg["commands"][action])
        for response in ("", "Batal", "$(shutdown)"):
            calls = []
            def cancel(argv, **kwargs):
                calls.append(argv)
                return subprocess.CompletedProcess(argv, 0, response)
            power_menu(self.cfg, cancel)
            self.assertEqual(len(calls), 1)


class AsyncTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.cfg = settings()
        self.cfg["compositor"] = "hyprland"
        self.lines = []
        self.collector = Collector(self.cfg, self.lines.append)

    async def test_actions_route_to_displayed_player_and_limit_volume(self):
        run = self.collector.commands.run = AsyncMock(return_value="")
        self.collector.selected = player("mpd.instance42", kind="mpris")
        await dispatch(self.collector, "music-toggle")
        run.assert_awaited_with("playerctl", "--player=mpd.instance42", "play-pause")
        self.collector.selected = player()
        await dispatch(self.collector, "music-scroll", "up")
        run.assert_awaited_with("mpc", "prev")
        await dispatch(self.collector, "volume-scroll", "up")
        run.assert_awaited_with("wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+")
        for action, argument in (("workspace", "1; touch /tmp/oops"), ("workspace", "99"),
                                 ("volume-scroll", "$(x)"), ("shutdown", None)):
            with self.assertRaises(ValueError):
                await dispatch(self.collector, action, argument)

    async def test_slider_bursts_keep_latest_and_reject_bad_values(self):
        self.collector.state["volume"]["available"] = True
        self.collector.apply_control = AsyncMock()
        task = asyncio.create_task(self.collector.control_updates())
        try:
            for value in range(101):
                await dispatch(self.collector, "volume-set", str(value))
            await asyncio.sleep(.1)
            self.collector.apply_control.assert_awaited_once_with("volume", 100)
            for value in ("nan", "inf", "-1", "101", "50; command", None):
                with self.subTest(value=value), self.assertRaises(ValueError):
                    await dispatch(self.collector, "volume-set", value)
            with self.assertRaises(ValueError):
                await dispatch(self.collector, "brightness-set", "50")
        finally:
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)

    async def test_slider_setters_use_displayed_backlight_and_bounded_volume(self):
        self.collector.state["volume"]["available"] = True
        self.collector.state["brightness"].update(available=True, device="panel9")
        self.collector.snapshot = AsyncMock()
        run = self.collector.commands.run = AsyncMock(return_value="")
        await self.collector.apply_control("volume", 50)
        run.assert_awaited_with("wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "0.5")
        await self.collector.apply_control("brightness", 50)
        run.assert_awaited_with("brightnessctl", "--quiet", "--class=backlight", "--device=panel9",
                               "--min-value=0", "set", "50%")
        await dispatch(self.collector, "brightness-scroll", "down")
        run.assert_awaited_with("brightnessctl", "--quiet", "--class=backlight", "--device=panel9",
                               "--min-value=0", "set", "5%-")

    async def test_fifo_gui_callback_and_slider_burst(self):
        with tempfile.TemporaryDirectory() as folder:
            self.collector.state["volume"]["available"] = True
            self.collector.apply_control = AsyncMock()
            self.collector.open_event_pipe(Path(folder))
            worker = asyncio.create_task(self.collector.control_updates())
            try:
                yuck = (ROOT / "widgets/right.yuck").read_text()
                callback, _ = json.JSONDecoder().raw_decode(yuck.split(":onchange ", 1)[1])
                callback = callback.replace("{}", "50")
                child = await asyncio.create_subprocess_exec(
                    "/bin/sh", "-c", callback,
                    env={**os.environ, "EWW_BAR_EVENTS": str(self.collector.event_pipe)})
                await asyncio.wait_for(child.wait(), 2)
                self.assertEqual(child.returncode, 0)
                await asyncio.sleep(.1)
                self.collector.apply_control.assert_awaited_once_with("volume", 50)
                self.collector.apply_control.reset_mock()
                os.write(self.collector.event_fd, b"volume-set 25\nvolume-set 75\n")
                await asyncio.sleep(.1)
                self.collector.apply_control.assert_awaited_once_with("volume", 75)
            finally:
                self.collector.close_event_pipe()
                worker.cancel()
                for task in list(self.collector.tasks):
                    task.cancel()
                await asyncio.gather(worker, *list(self.collector.tasks), return_exceptions=True)
            self.assertFalse((Path(folder) / "events.fifo").exists())

    async def test_player_handoff_only_when_published(self):
        self.collector.selected = player()
        replacement = player("spotify", kind="mpris")
        with patch("adapter.music_players", AsyncMock(return_value=[replacement])):
            await self.collector.snapshot("music")
        self.assertEqual(self.collector.selected["key"], "mpd")
        self.collector.emit()
        self.assertEqual(self.collector.selected["key"], "mpris:spotify")

    async def test_separate_metadata_fields_preserve_newlines(self):
        async def run(*argv):
            if argv == ("playerctl", "-l"):
                return "spotify\nmalicious;command"
            return {"status": "Playing", "xesam:title": 'one\ntwo " \\',
                    "xesam:artist": "artist\n藝"}.get(argv[-1])
        cfg = {**self.cfg["music"], "mpd": False}
        players = await music_players(run, cfg)
        self.assertEqual(len(players), 1)
        self.assertEqual(players[0]["title"], 'one\ntwo " \\')
        self.assertEqual(players[0]["artist"], "artist\n藝")

    async def test_hyprland_lua_and_legacy_focus(self):
        run = AsyncMock(return_value="ok")
        await Hyprland().focus(run, 3)
        run.assert_awaited_once_with("hyprctl", "dispatch", "hl.dsp.focus({ workspace = 3 })")
        run = AsyncMock(side_effect=[None, "ok"])
        self.assertEqual(await Hyprland().focus(run, 3), "ok")
        run.assert_awaited_with("hyprctl", "dispatch", "workspace", "3")

    async def test_changed_only_and_burst_coalescing(self):
        self.collector.snapshot = AsyncMock()
        task = asyncio.create_task(self.collector.refresh())
        for _ in range(100):
            self.collector.mark("volume")
        await asyncio.sleep(.25)
        self.collector.snapshot.assert_awaited_once_with("volume")
        self.collector.emit()
        self.collector.emit()
        self.assertEqual(len(self.lines), 1)
        task.cancel()
        await asyncio.gather(task, return_exceptions=True)

    async def test_missing_services_only_reset_their_module(self):
        self.collector.commands.run = AsyncMock(return_value=None)
        self.collector.state["clock"]["time"] = "12:34"
        await asyncio.gather(*(self.collector.snapshot(n) for n in ("music", "volume", "network", "workspaces")))
        for name in ("music", "volume", "network", "workspaces"):
            self.assertFalse(self.collector.state[name]["available"])
        self.assertEqual(self.collector.state["clock"]["time"], "12:34")

    async def test_command_cancellation_reaps_child(self):
        commands = Commands()
        task = asyncio.create_task(commands.run(sys.executable, "-c", "import time; time.sleep(30)"))
        await asyncio.sleep(.1)
        children = list(commands.children)
        self.assertEqual(len(children), 1)
        task.cancel()
        await asyncio.gather(task, return_exceptions=True)
        self.assertIsNotNone(children[0].returncode)
        self.assertFalse(commands.children)

    async def test_stream_disconnect_reconnect_and_cleanup(self):
        with tempfile.TemporaryDirectory() as folder:
            counter = Path(folder) / "count"
            script = ("import pathlib,time; p=pathlib.Path(" + repr(str(counter)) + "); "
                      "n=int(p.read_text())+1 if p.exists() else 1; p.write_text(str(n)); "
                      "print('{\"count\":'+str(n)+',\"dnd\":false}',flush=True); "
                      "time.sleep(.08 if n==1 else 30)")
            task = asyncio.create_task(self.collector.stream("notifications", [sys.executable, "-c", script]))
            await asyncio.sleep(1.5)
            self.assertEqual(self.collector.state["notifications"]["count"], 2)
            states = [json.loads(line)["notifications"] for line in self.lines]
            self.assertTrue(any(not s["available"] for s in states))
            children = list(self.collector.commands.children)
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)
            self.assertTrue(all(p.returncode is not None for p in children))

    async def test_hyprland_socket_reconnect_and_filter(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "hypr.sock"
            connections = []
            async def client(reader, writer):
                connections.append(True)
                writer.write(b"activewindow>>ignore,title\nworkspacev2>>3,3\n")
                await writer.drain()
                writer.close()
                await writer.wait_closed()
            server = await asyncio.start_unix_server(client, path)
            with patch.object(Hyprland, "socket_path", return_value=path):
                task = asyncio.create_task(self.collector.workspace_events())
                await asyncio.sleep(1.2)
                task.cancel()
                await asyncio.gather(task, return_exceptions=True)
            server.close()
            await server.wait_closed()
            self.assertGreaterEqual(len(connections), 2)
            self.assertEqual(self.collector.dirty, {"workspaces"})

    async def test_niri_focus_uses_id_and_event_subscription(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "niri.sock"
            requests = []
            async def client(reader, writer):
                requests.append(json.loads(await reader.readline()))
                writer.write(b'{"Ok":"Handled"}\n')
                await writer.drain()
                writer.close()
                await writer.wait_closed()
            server = await asyncio.start_unix_server(client, path)
            with patch.object(Niri, "socket_path", return_value=path):
                self.assertEqual(await Niri().focus(None, 42), "ok")
                reader, writer = await asyncio.open_unix_connection(path)
                await Niri().subscribe(writer)
                await reader.readline()
                writer.close()
                await writer.wait_closed()
            server.close()
            await server.wait_closed()
            self.assertEqual(requests, [{"Action": {"FocusWorkspace": {"reference": {"Id": 42}}}}, "EventStream"])


if __name__ == "__main__":
    unittest.main()
