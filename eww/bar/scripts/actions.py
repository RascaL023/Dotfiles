"""Allowlisted actions; application commands are argv arrays, never shell code."""
import asyncio
import json
import math
import os
import subprocess
import sys

from common import ROOT, runtime_dir

MENU = {"Kunci layar": "lock", "Suspend": "suspend", "Logout": "logout",
        "Restart": "reboot", "Shutdown": "shutdown"}
CONFIRM = {"logout", "reboot", "shutdown"}


def power_menu(cfg, run=subprocess.run):
    options = ["Batal", *MENU]
    result = run([*cfg["commands"]["menu"], "-p", "Daya"],
                 input="\n".join(options) + "\n", text=True, capture_output=True)
    if result.returncode != 0 or result.stdout.strip() not in MENU:
        return 0
    choice = result.stdout.strip()
    action = MENU[choice]
    if action in CONFIRM:
        answer = run([*cfg["commands"]["menu"], "-p", choice + "?"],
                     input="Batal\nYa, " + choice + "\n", text=True, capture_output=True)
        if answer.returncode != 0 or answer.stdout.strip() != "Ya, " + choice:
            return 0
    return run(cfg["commands"][action], check=False).returncode


def detach(argv):
    # These are user-launched applications, not data listeners. They may outlive the bar.
    subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)


def local_action(name, cfg):
    if name in ("launcher", "network"):
        detach(cfg["commands"][name])
        return True
    if name == "power":
        detach([sys.executable, str(ROOT / "scripts/adapter.py"), "power-menu"])
        return True
    return False


async def dispatch(collector, name, argument=None):
    cfg, run = collector.cfg, collector.commands.run
    if name in ("calendar-toggle", "calendar-previous", "calendar-next", "calendar-today"):
        await collector.calendar_action(name)
        return
    if name in ("music-panel-toggle", "music-panel-close"):
        await collector.music_panel.action(name)
        return
    if name in ("volume-set", "brightness-set"):
        try:
            value = float(argument)
        except (TypeError, ValueError):
            raise ValueError("slider requires a percentage from 0 to 100") from None
        if not math.isfinite(value) or not 0 <= value <= 100:
            raise ValueError("slider requires a percentage from 0 to 100")
        module = name.removesuffix("-set")
        if not cfg["modules"][module] or not collector.state[module]["available"]:
            raise ValueError("control unavailable")
        collector.control_values[module] = round(value)
        collector.control_changed.set()
        return
    if name == "workspace":
        try:
            number = int(argument)
        except (ValueError, TypeError):
            raise ValueError("workspace requires a displayed numeric ID") from None
        if number not in {w["id"] for w in collector.state["workspaces"]["items"]}:
            raise ValueError("workspace is not displayed")
        result = await collector.compositor.focus(run, number)
        collector.mark("workspaces")
    elif name == "volume-mute":
        result = await run("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle")
        collector.mark("volume")
    elif name == "volume-scroll":
        if argument not in ("up", "down"):
            raise ValueError("scroll must be up or down")
        result = await run("wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@",
                           "5%+" if argument == "up" else "5%-")
        collector.mark("volume")
    elif name == "brightness-scroll":
        if argument not in ("up", "down"):
            raise ValueError("scroll must be up or down")
        state = collector.state["brightness"]
        if not state["available"]:
            raise ValueError("backlight unavailable")
        result = await run("brightnessctl", "--quiet", "--class=backlight",
                           "--device=" + state["device"], "--min-value=0", "set",
                           "5%+" if argument == "up" else "5%-")
        collector.mark("brightness")
    elif name in ("music-toggle", "music-scroll", "music-previous", "music-next"):
        player = collector.selected
        if not player:
            raise ValueError("no displayed player")
        if name == "music-scroll" and argument not in ("up", "down"):
            raise ValueError("scroll must be up or down")
        action = ("play-pause" if name == "music-toggle" else "previous"
                  if name == "music-previous" or (name == "music-scroll" and argument == "up") else "next")
        if player["kind"] == "mpd":
            result = await run("mpc", {"play-pause": "toggle", "previous": "prev", "next": "next"}[action])
        else:
            result = await run("playerctl", "--player=" + player["name"], action)
        collector.mark("music")
    elif name in ("notifications", "dnd"):
        result = await run(*cfg["commands"][name])
    else:
        raise ValueError("unknown action")
    if result is None:
        raise RuntimeError("service unavailable or action timed out")


async def request(name, argument=None):
    reader, writer = await asyncio.open_unix_connection(runtime_dir() / "actions.sock")
    try:
        writer.write((json.dumps({"action": name, "argument": argument}) + "\n").encode())
        await writer.drain()
        reply = json.loads(await asyncio.wait_for(reader.readline(), 5))
        if not reply.get("ok"):
            raise RuntimeError(reply.get("error", "action failed"))
        return reply
    finally:
        writer.close()
        await writer.wait_closed()
