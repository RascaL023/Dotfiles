import asyncio
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from actions import dispatch
from adapter import Collector
from common import initial_state, settings
from sources import music_state


def player(kind="mpd", status="Paused"):
    return {"key": "mpd" if kind == "mpd" else "mpris:mpd.instance42",
            "name": "mpd" if kind == "mpd" else "mpd.instance42", "kind": kind,
            "status": status, "title": '曲 "quotes" \\ $(`command`)\nLong title beyond the bar limit',
            "artist": "Björk\\日本語\n<artist>"}


class MusicMetadata(unittest.TestCase):
    def test_panel_keeps_full_metadata_and_escapes_only_label_values(self):
        cfg = settings()
        state = music_state(player(), cfg["music"])
        self.assertEqual(state["full_title"], '曲 "quotes" \\ $(`command`) Long title beyond the bar limit')
        self.assertLessEqual(len(state["title"]), cfg["music"]["title_limit"])
        self.assertEqual(state["label_full_title"], state["full_title"].replace("\\", "\\\\"))
        self.assertEqual(state["label_artist"], "Björk\\\\日本語 <artist>")
        self.assertIn("\n", state["tooltip"])
        self.assertEqual(json.loads(json.dumps(state, ensure_ascii=False)), state)
        self.assertFalse(state["playing"])
        playing = music_state(player(status="Playing"), cfg["music"])
        self.assertTrue(playing["playing"])
        self.assertNotEqual(playing["play_icon"], state["play_icon"])
        self.assertEqual(set(state), set(initial_state(cfg)["music"]))


class MusicInteractions(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.collector = Collector(settings(), lambda _: None)
        self.collector.music_panel.eww = AsyncMock(return_value="")
        self.collector.state["ui"]["music_duration"] = "0ms"

    async def asyncTearDown(self):
        tasks = list(self.collector.tasks)
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)

    async def test_open_empty_close_and_cancel_stale_close_on_reopen(self):
        collector = self.collector
        await dispatch(collector, "music-panel-toggle")
        self.assertTrue(collector.state["music_panel"]["open"])
        self.assertFalse(collector.state["music"]["available"])
        await dispatch(collector, "music-panel-close")
        await dispatch(collector, "music-panel-toggle")
        await asyncio.sleep(.07)
        self.assertTrue(collector.state["music_panel"]["open"])
        self.assertEqual(collector.music_panel.eww.await_count, 1)
        await dispatch(collector, "music-panel-close")
        await collector.music_panel.closing
        self.assertFalse(collector.music_panel.window)
        collector.music_panel.eww.assert_awaited_with("close", "music-popup")
        await dispatch(collector, "music-panel-close")
        self.assertFalse(collector.state["music_panel"]["open"])

    async def test_popup_ipc_timeout_checks_actual_window_and_can_retry_failure(self):
        collector = self.collector
        collector.music_panel.eww.return_value = None
        with self.assertRaises(RuntimeError):
            await dispatch(collector, "music-panel-toggle")
        self.assertFalse(collector.state["music_panel"]["open"])
        self.assertFalse(collector.music_panel.window)
        collector.music_panel.eww.side_effect = [None, "music-popup: music-popup"]
        await dispatch(collector, "music-panel-toggle")
        self.assertTrue(collector.state["music_panel"]["open"])

    async def test_transport_uses_displayed_mpd_or_mpris_source(self):
        collector = self.collector
        run = collector.commands.run = AsyncMock(return_value="")
        for kind, prefix, previous in (("mpd", ("mpc",), "prev"),
                                       ("mpris", ("playerctl", "--player=mpd.instance42"), "previous")):
            collector.selected = player(kind)
            await dispatch(collector, "music-previous")
            run.assert_awaited_with(*prefix, previous)
            await dispatch(collector, "music-next")
            run.assert_awaited_with(*prefix, "next")
            await dispatch(collector, "music-toggle")
            run.assert_awaited_with(*prefix, "toggle" if kind == "mpd" else "play-pause")
        collector.selected = None
        run.reset_mock()
        with self.assertRaises(ValueError):
            await dispatch(collector, "music-next")
        run.assert_not_awaited()

    async def test_player_disappears_and_returns_while_panel_remains_closable(self):
        collector = self.collector
        await dispatch(collector, "music-panel-toggle")
        with patch("adapter.music_players", AsyncMock(return_value=[player()])):
            await collector.snapshot("music")
        collector.emit()
        self.assertTrue(collector.state["music"]["available"])
        with patch("adapter.music_players", AsyncMock(return_value=[])):
            await collector.snapshot("music")
        collector.emit()
        self.assertFalse(collector.state["music"]["available"])
        self.assertTrue(collector.state["music_panel"]["open"])
        self.assertIsNone(collector.selected)
        with patch("adapter.music_players", AsyncMock(return_value=[player("mpris", "Playing")])):
            await collector.snapshot("music")
        collector.emit()
        self.assertEqual(collector.state["music"]["source"], "mpris:mpd.instance42")
        self.assertTrue(collector.state["music"]["playing"])
        await dispatch(collector, "music-panel-close")
        await collector.music_panel.closing
        self.assertFalse(collector.music_panel.window)


if __name__ == "__main__":
    unittest.main()
