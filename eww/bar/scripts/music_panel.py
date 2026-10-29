"""On-demand music popup on the bar's existing Eww daemon and collector."""
import asyncio

from common import ROOT


class MusicPanel:
    def __init__(self, collector):
        self.collector = collector
        self.window = False
        self.closing = None

    async def eww(self, *args):
        return await self.collector.commands.run(
            "eww", "--config", str(ROOT), "--force-wayland", "--no-daemonize", *args)

    async def finish_close(self):
        duration = int(self.collector.state["ui"]["music_duration"].removesuffix("ms")) / 1000
        await asyncio.sleep(duration + .05)
        async with self.collector.action_lock:
            await self.eww("close", "music-popup")
            self.window = False

    async def action(self, name):
        collector = self.collector
        if not collector.cfg["modules"]["music"]:
            raise ValueError("music is disabled")
        state = collector.state["music_panel"]
        if name == "music-panel-close" and not state["open"]:
            return
        if self.closing and not self.closing.done():
            self.closing.cancel()
            await asyncio.gather(self.closing, return_exceptions=True)
        if state["open"]:
            state["open"] = False
            collector.emit()
            self.closing = collector.task(self.finish_close())
            return
        if not self.window:
            ui = collector.state["ui"]
            result = await self.eww("open", "music-popup", "--screen", str(collector.cfg["monitor"]),
                                    "--arg", "panel-x=" + ui["music_offset_x"],
                                    "--arg", "panel-y=" + ui["music_offset_y"])
            if result is None:
                windows = await self.eww("active-windows")
                if "music-popup: music-popup" not in (windows or ""):
                    raise RuntimeError("music panel failed to open; inspect daemon.log")
            self.window = True
            await asyncio.sleep(.04)
        state["open"] = True
        collector.emit()
