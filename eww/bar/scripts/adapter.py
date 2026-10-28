#!/usr/bin/env python3
"""One JSON-line collector; periodic timers only for clock and sysfs batteries."""
import argparse
import asyncio
import contextlib
import datetime
import fcntl
import json
import os
import signal
import sys
import time

from actions import dispatch, local_action, power_menu, request
from common import ROOT, initial_state, runtime_dir, settings, workspace_layout
from calendar_data import calendar_state, shift_month
from sources import (Commands, PipeWireEvents, battery_state, brightness_state, choose_player, clock_state, compositor,
                     music_players, music_state, network_state, notification_state, volume_state)

DBUS_MATCHES = [
    "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/mpris/MediaPlayer2',arg0='org.mpris.MediaPlayer2.Player'",
    "type='signal',interface='org.freedesktop.DBus',member='NameOwnerChanged',arg0namespace='org.mpris.MediaPlayer2'",
]


class Collector:
    def __init__(self, cfg, output=None):
        self.cfg = cfg
        self.defaults = initial_state(cfg)
        self.state = initial_state(cfg)
        self.commands = Commands(cfg["intervals"]["command_timeout"])
        self.compositor = compositor(cfg)
        self.selected = None
        self.next_selected = None
        self.dirty = set()
        self.changed = asyncio.Event()
        self.stop = asyncio.Event()
        self.tasks = set()
        self.last = None
        self.output = output or (lambda value: print(value, flush=True))
        self.action_lock = asyncio.Lock()
        self.control_values = {}
        self.control_changed = asyncio.Event()
        self.event_queue = asyncio.Queue(maxsize=128)
        self.event_buffer = b""
        self.event_pipe = None
        self.event_fd = None
        self.calendar_window = False
        self.calendar_close_task = None

    async def calendar_eww(self, *args):
        return await self.commands.run("eww", "--config", str(ROOT), "--force-wayland",
                                       "--no-daemonize", *args)

    async def close_calendar(self):
        # A single cancellable delay lets GTK finish the native revealer animation.
        duration = int(self.state["ui"]["calendar_duration"].removesuffix("ms")) / 1000
        await asyncio.sleep(duration + .05)
        async with self.action_lock:
            await self.calendar_eww("close", "calendar-popup")
            self.calendar_window = False

    async def calendar_action(self, name):
        if not self.cfg["modules"]["clock"]:
            raise ValueError("clock is disabled")
        state = self.state["calendar"]
        if name == "calendar-toggle":
            if self.calendar_close_task and not self.calendar_close_task.done():
                self.calendar_close_task.cancel()
                await asyncio.gather(self.calendar_close_task, return_exceptions=True)
            if state["open"]:
                state["open"] = False
                self.emit()
                self.calendar_close_task = self.task(self.close_calendar())
                return
            self.state["calendar"] = calendar_state()
            self.emit()
            if not self.calendar_window:
                result = await self.calendar_eww("open", "calendar-popup", "--screen", str(self.cfg["monitor"]),
                                                 "--arg", "panel-y=" + self.state["ui"]["calendar_offset"])
                if result is None:
                    # Like barctl, tolerate Eww's short IPC timeout only if the window exists.
                    windows = await self.calendar_eww("active-windows")
                    if "calendar-popup: calendar-popup" not in (windows or ""):
                        raise RuntimeError("calendar failed to open; inspect daemon.log")
                self.calendar_window = True
                await asyncio.sleep(.04)  # Map collapsed before starting the GTK animation.
            self.state["calendar"]["open"] = True
        elif name in ("calendar-previous", "calendar-next", "calendar-today"):
            if not state["open"]:
                return
            if name == "calendar-today":
                self.state["calendar"] = calendar_state(opened=True)
            else:
                year, month = shift_month(state["year"], state["month"],
                                          -1 if name == "calendar-previous" else 1)
                self.state["calendar"] = calendar_state(year, month, opened=True)
        else:
            raise ValueError("unknown calendar action")
        self.emit()

    def refresh_calendar_date(self):
        state = self.state["calendar"]
        today = datetime.date.today()
        if state["date"] != today.isoformat():
            year, month = state["year"], state["month"]
            # Follow the current month across midnight unless the user was browsing.
            old = datetime.date.fromisoformat(state["date"])
            if (year, month) == (old.year, old.month):
                year, month = today.year, today.month
            self.state["calendar"] = calendar_state(year, month, today=today, opened=state["open"])

    def mark(self, module):
        self.dirty.add(module)
        self.changed.set()

    def emit(self):
        encoded = json.dumps(self.state, ensure_ascii=False, separators=(",", ":"))
        if encoded != self.last:
            try:
                self.output(encoded)
            except (BrokenPipeError, OSError):
                self.stop.set()
            self.last = encoded
            self.selected = self.next_selected

    def task(self, coro):
        task = asyncio.create_task(coro)
        self.tasks.add(task)
        task.add_done_callback(self.tasks.discard)
        return task

    async def apply_control(self, module, percent):
        state = self.state[module]
        if not state["available"]:
            return
        if module == "volume":
            result = await self.commands.run("wpctl", "set-volume", "-l", "1.0",
                                             "@DEFAULT_AUDIO_SINK@", str(percent / 100))
        else:
            result = await self.commands.run("brightnessctl", "--quiet", "--class=backlight",
                                             "--device=" + state["device"], "--min-value=0",
                                             "set", f"{percent}%")
        if result is None:
            print(f"bar: {module}: setting value failed", file=sys.stderr)
        await self.snapshot(module)
        self.emit()

    async def control_updates(self):
        while True:
            await self.control_changed.wait()
            # Keep the latest drag value; never queue a subprocess for every pixel.
            await asyncio.sleep(.05)
            values, self.control_values = self.control_values, {}
            self.control_changed.clear()
            for module, percent in values.items():
                await self.apply_control(module, percent)

    def open_event_pipe(self, directory):
        self.event_pipe = directory / "events.fifo"
        self.event_pipe.unlink(missing_ok=True)
        os.mkfifo(self.event_pipe, 0o600)
        self.event_fd = os.open(self.event_pipe, os.O_RDWR | os.O_NONBLOCK)
        asyncio.get_running_loop().add_reader(self.event_fd, self.read_events)

    def close_event_pipe(self):
        if self.event_fd is not None:
            asyncio.get_running_loop().remove_reader(self.event_fd)
            os.close(self.event_fd)
            self.event_fd = None
        if self.event_pipe:
            self.event_pipe.unlink(missing_ok=True)

    def read_events(self):
        try:
            self.event_buffer += os.read(self.event_fd, 65536)
        except BlockingIOError:
            return
        while b"\n" in self.event_buffer:
            line, self.event_buffer = self.event_buffer.split(b"\n", 1)
            fields = line.decode(errors="replace").split(maxsplit=1)
            if not fields:
                continue
            item = (fields[0], fields[1] if len(fields) == 2 else None)
            if fields[0] in ("volume-set", "brightness-set"):
                # These actions only change memory and never await a device command.
                self.task(self.event_action(*item))
            else:
                if self.event_queue.full():
                    self.event_queue.get_nowait()
                self.event_queue.put_nowait(item)
        if len(self.event_buffer) > 8192:
            self.event_buffer = b""

    async def event_action(self, name, argument):
        try:
            await dispatch(self, name, argument)
        except (ValueError, RuntimeError, OSError, asyncio.TimeoutError) as exc:
            print(f"bar: event {name}: {exc}", file=sys.stderr)

    async def event_actions(self):
        while True:
            item = await self.event_queue.get()
            async with self.action_lock:
                await self.event_action(*item)

    async def snapshot(self, module):
        run = self.commands.run
        value = None
        try:
            if module == "workspaces":
                value = await self.compositor.snapshot(run, self.cfg)
            elif module == "volume":
                value = volume_state(await run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"))
            elif module == "brightness":
                value = brightness_state(self.cfg["brightness"]["device"])
            elif module == "network":
                value = network_state(await run("nmcli", "-t", "-e", "yes", "-f",
                                                "DEVICE,TYPE,STATE,CONNECTION", "device", "status"))
            elif module == "music":
                players = await music_players(run, self.cfg["music"])
                current = self.selected["key"] if self.selected else ""
                self.next_selected = choose_player(players, current, self.cfg["music"])
                value = music_state(self.next_selected, self.cfg["music"])
            elif module == "battery":
                value = battery_state()
            elif module == "clock":
                value = clock_state()
                self.refresh_calendar_date()
        except (ValueError, TypeError, KeyError, OSError) as exc:
            print(f"bar: {module}: {exc}", file=sys.stderr)
            if module == "music":
                self.next_selected = None
        if module == "workspaces" and value is not None:
            value = workspace_layout(value)
        self.state[module] = value if value is not None else self.defaults[module].copy()

    async def refresh(self):
        while True:
            await self.changed.wait()
            # Fixed coalescing window: a continuous stream cannot starve a refresh.
            await asyncio.sleep(self.cfg["intervals"]["debounce"])
            modules, self.dirty = self.dirty, set()
            self.changed.clear()
            await asyncio.gather(*(self.snapshot(name) for name in modules))
            self.emit()

    async def timer(self, module):
        while True:
            self.mark(module)
            interval = (60 - time.time() % 60) if module == "clock" else self.cfg["intervals"]["battery"]
            await asyncio.sleep(interval)

    async def stream(self, module, argv, mode="line"):
        delay = 1
        while True:
            proc = None
            pipewire = PipeWireEvents() if mode == "pipewire" else None
            started = time.monotonic()
            try:
                proc = await asyncio.create_subprocess_exec(
                    *argv, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
                    limit=1024 * 1024, env={**os.environ, "LC_ALL": "C"})
                self.commands.children.add(proc)
                if module != "notifications":
                    self.mark(module)
                while True:
                    data = await (proc.stdout.read(65536) if mode == "pipewire" else proc.stdout.readline())
                    if not data:
                        break
                    line = data.decode(errors="replace").strip()
                    if pipewire is not None:
                        if pipewire.feed(data):
                            self.mark(module)
                    elif module == "notifications":
                        try:
                            self.state[module] = notification_state(line)
                            self.emit()
                        except (ValueError, TypeError, AttributeError):
                            pass
                    elif mode == "backlight":
                        if line.startswith(("UDEV ", "KERNEL ")):
                            self.mark(module)
                    elif mode != "mpris" or "member=NameOwnerChanged" in line or line in (
                            'string "Metadata"', 'string "PlaybackStatus"'):
                        self.mark(module)
                await proc.wait()
            except (OSError, ValueError):
                pass
            finally:
                if proc:
                    if proc.returncode is None:
                        with contextlib.suppress(ProcessLookupError):
                            proc.terminate()
                        try:
                            await asyncio.wait_for(proc.wait(), 1)
                        except asyncio.TimeoutError:
                            with contextlib.suppress(ProcessLookupError):
                                proc.kill()
                            await proc.wait()
                    self.commands.children.discard(proc)
            if module == "notifications":
                self.state[module] = self.defaults[module].copy()
                self.emit()
            else:
                self.mark(module)
            if time.monotonic() - started > 30:
                delay = 1
            await asyncio.sleep(delay)
            delay = min(delay * 2, self.cfg["intervals"]["reconnect_max"])

    async def workspace_events(self):
        delay = 1
        while True:
            writer = None
            started = time.monotonic()
            try:
                reader, writer = await asyncio.open_unix_connection(self.compositor.socket_path(), limit=4 * 1024 * 1024)
                await self.compositor.subscribe(writer)
                self.mark("workspaces")
                while line := await reader.readline():
                    if self.compositor.relevant(line):
                        self.mark("workspaces")
            except (OSError, ValueError):
                pass
            finally:
                if writer:
                    writer.close()
                    with contextlib.suppress(OSError):
                        await writer.wait_closed()
            self.state["workspaces"] = self.defaults["workspaces"].copy()
            self.emit()
            if time.monotonic() - started > 30:
                delay = 1
            await asyncio.sleep(delay)
            delay = min(delay * 2, self.cfg["intervals"]["reconnect_max"])

    async def client(self, reader, writer):
        # Track clients too, so an in-flight action cannot leave a child after shutdown.
        task = asyncio.current_task()
        self.tasks.add(task)
        try:
            message = json.loads(await asyncio.wait_for(reader.readline(), 2))
            async with self.action_lock:
                if message.get("action") == "state":
                    reply = {"ok": True, "state": self.state}
                elif message.get("action") == "stop":
                    reply = {"ok": True}
                    self.stop.set()
                else:
                    await dispatch(self, message.get("action"), message.get("argument"))
                    reply = {"ok": True}
        except (ValueError, TypeError, AttributeError, RuntimeError, OSError, asyncio.TimeoutError) as exc:
            reply = {"ok": False, "error": str(exc)}
        try:
            writer.write((json.dumps(reply) + "\n").encode())
            await writer.drain()
        except (OSError, UnboundLocalError):
            pass
        finally:
            writer.close()
            with contextlib.suppress(OSError):
                await writer.wait_closed()
            self.tasks.discard(task)

    async def listen(self):
        directory = runtime_dir()
        if (directory / "monitor").exists():
            self.cfg["monitor"] = (directory / "monitor").read_text().strip()
        with (directory / "collector.lock").open("a") as lock:
            # A reload may launch the replacement while the old listener is exiting.
            for attempt in range(50):
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    await asyncio.sleep(.1)
            else:
                raise RuntimeError("another bar collector is already running")
            path = directory / "actions.sock"
            path.unlink(missing_ok=True)
            server = await asyncio.start_unix_server(self.client, path=path, limit=8192)
            self.open_event_pipe(directory)
            loop = asyncio.get_running_loop()
            for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
                loop.add_signal_handler(sig, self.stop.set)
            (directory / "collector.pid").write_text(str(os.getpid()))
            self.emit()
            enabled = self.cfg["modules"]
            self.task(self.refresh())
            self.task(self.control_updates())
            self.task(self.event_actions())
            for module in ("clock", "battery"):
                if enabled[module]:
                    self.task(self.timer(module))
            if enabled["workspaces"]:
                self.task(self.workspace_events())
            if enabled["volume"]:
                self.task(self.stream("volume", ["pw-dump", "--monitor", "--no-colors"], "pipewire"))
            if enabled["brightness"]:
                self.task(self.stream("brightness", ["udevadm", "monitor", "--udev",
                                                      "--subsystem-match=backlight"], "backlight"))
            if enabled["network"]:
                self.task(self.stream("network", ["nmcli", "monitor"]))
            if enabled["notifications"]:
                self.task(self.stream("notifications", ["swaync-client", "-s"]))
            if enabled["music"]:
                if self.cfg["music"]["mpris"]:
                    self.task(self.stream("music", ["dbus-monitor", "--session", *DBUS_MATCHES], "mpris"))
                if self.cfg["music"]["mpd"]:
                    self.task(self.stream("music", ["mpc", "idleloop", "player", "options", "playlist"]))
            try:
                await self.stop.wait()
            finally:
                server.close()
                await server.wait_closed()
                tasks = list(self.tasks)
                for task in tasks:
                    task.cancel()
                await asyncio.gather(*tasks, return_exceptions=True)
                self.close_event_pipe()
                path.unlink(missing_ok=True)
                (directory / "collector.pid").unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("listen", "action", "snapshot", "power-menu"))
    parser.add_argument("name", nargs="?")
    parser.add_argument("argument", nargs="?")
    args = parser.parse_args()
    cfg = settings()
    if args.command == "listen":
        asyncio.run(Collector(cfg).listen())
    elif args.command == "snapshot":
        print(json.dumps(asyncio.run(request("state"))["state"], ensure_ascii=False, indent=2))
    elif args.command == "power-menu":
        return power_menu(cfg)
    elif not local_action(args.name, cfg):
        asyncio.run(request(args.name, args.argument))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, RuntimeError) as exc:
        print(f"bar: {exc}", file=sys.stderr)
        sys.exit(1)
