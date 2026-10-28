#!/usr/bin/env python3
"""Explicit desktop checks: lifecycle, reversible controls, or /proc resource samples.

Run only on a live Hyprland or Niri session. No session-ending power action is invoked.
"""
import argparse
import asyncio
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from common import ROOT, runtime_dir, settings
from actions import dispatch, request
from adapter import Collector
from sources import Commands, compositor, choose_player, music_players


def command(*argv):
    return subprocess.check_output(argv, text=True, timeout=15).strip()


def ctl(*args):
    return command(str(ROOT / "barctl"), *args)


def state():
    return asyncio.run(request("state"))["state"]


def eventually(predicate, timeout=6):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = state()
        if predicate(value):
            return value
        time.sleep(.1)
    raise AssertionError("state did not converge")


def processes():
    result = {}
    for path in Path("/proc").iterdir():
        if not path.name.isdecimal():
            continue
        try:
            raw = (path / "stat").read_text()
            fields = raw[raw.rindex(")") + 2:].split()
            args = (path / "cmdline").read_bytes().split(b"\0")
            # Include reaped children's CPU, so brief wpctl/playerctl snapshots are counted.
            result[int(path.name)] = {"ppid": int(fields[1]), "ticks": sum(int(fields[i]) for i in (11, 12, 13, 14)),
                                     "start": int(fields[19]), "rss": int(fields[21]) * os.sysconf("SC_PAGE_SIZE"),
                                     "status": fields[0], "argv": [a.decode(errors="replace") for a in args if a]}
        except (OSError, ValueError):
            pass
    return result


def bar_processes():
    all_procs = processes()
    roots = {pid for pid, p in all_procs.items() if str(ROOT) in p["argv"] and
             p["argv"] and Path(p["argv"][0]).name == "eww" and "daemon" in p["argv"]}
    assert len(roots) == 1, f"expected one Eww daemon, found {roots}"
    included = roots.copy()
    while True:
        expanded = included | {pid for pid, p in all_procs.items() if p["ppid"] in included}
        if expanded == included:
            break
        included = expanded
    result = {pid: all_procs[pid] for pid in included}
    collectors = [p for p in result.values() if "./scripts/adapter.py" in p["argv"]]
    assert len(collectors) == 1, f"expected one collector, found {len(collectors)}"
    return result


def assert_gone(previous):
    current = processes()
    leftover = {pid: p for pid, p in previous.items() if pid in current and
                p["start"] == current[pid]["start"] and current[pid]["status"] != "Z"}
    assert not leftover, f"listeners left behind: {leftover}"


def cycles(count):
    ctl("stop")
    for index in range(count):
        ctl("start")
        eventually(lambda s: s["workspaces"]["available"])
        before = bar_processes()
        ctl("reload")
        eventually(lambda s: s["workspaces"]["available"])
        assert_gone(before)
        before = bar_processes()
        ctl("stop")
        assert_gone(before)
        assert not (runtime_dir() / "collector.pid").exists()
        assert ctl("status") == "stopped"
        print(f"cycle {index + 1}/{count}: start, reload, stop; no surviving processes", flush=True)
    ctl("start")


def controls():
    original = state()
    active = next(w["id"] for w in original["workspaces"]["items"] if w["active"])
    volume = command("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
    percent = float(volume.split()[1])
    muted = "[MUTED]" in volume
    dnd = command("swaync-client", "-D")
    mpd_status = command("mpc", "status")
    assert "[paused]" in mpd_status, "run controls with MPD paused; refuse to disturb active playback"
    track = re.search(r"#(\d+)/\d+\s+(\d+):(\d+)/", mpd_status)
    assert track, "cannot save MPD track/position"
    song, minutes, seconds = (int(x) for x in track.groups())
    try:
        target = next(w["id"] for w in original["workspaces"]["items"] if w["id"] != active)
        ctl("action", "workspace", str(target))
        eventually(lambda s: any(w["active"] and w["id"] == target for w in s["workspaces"]["items"]))
        ctl("action", "workspace", str(active))
        command("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.98")
        eventually(lambda s: s["volume"]["percent"] == 98)
        ctl("action", "volume-scroll", "up")
        eventually(lambda s: s["volume"]["percent"] == 100)
        ctl("action", "volume-mute")
        eventually(lambda s: s["volume"]["muted"] != muted)
        command("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0")
        ctl("action", "dnd")
        eventually(lambda s: s["notifications"]["dnd"] != original["notifications"]["dnd"])
        ctl("action", "dnd")
        ctl("action", "music-toggle")
        eventually(lambda s: "Playing" in s["music"]["tooltip"])
        ctl("action", "music-toggle")
        eventually(lambda s: "Paused" in s["music"]["tooltip"])
        title = state()["music"]["title"]
        ctl("action", "music-scroll", "down")
        eventually(lambda s: s["music"]["title"] != title)
        ctl("action", "music-scroll", "up")
        eventually(lambda s: s["music"]["title"] == title)
        command("mpc", "pause")
        eventually(lambda s: "Paused" in s["music"]["tooltip"])
        # Same live MPD via its MPRIS bridge, without changing the main collector's settings.
        async def bridge():
            cfg = settings()
            cfg["music"]["mpd"] = False
            collector = Collector(cfg, lambda _: None)
            players = await music_players(collector.commands.run, cfg["music"])
            chosen = choose_player(players, "", cfg["music"])
            assert chosen and chosen["kind"] == "mpris", "no MPRIS bridge available"
            collector.selected = chosen
            await dispatch(collector, "music-toggle")
            assert "[playing]" in (await collector.commands.run("mpc", "status"))
            await dispatch(collector, "music-toggle")
            print("MPRIS control:", chosen["key"], flush=True)
        asyncio.run(bridge())
        print("Workspace, volume limit/mute, DND, MPD and MPRIS controls: PASS", flush=True)
    finally:
        asyncio.run(compositor(settings()).focus(Commands().run, active))
        command("swaync-client", "-dn" if dnd == "true" else "-df")
        command("mpc", "play", str(song))
        command("mpc", "seek", str(minutes * 60 + seconds))
        command("mpc", "pause")
        command("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", str(percent))
        command("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1" if muted else "0")


def measure(seconds, label):
    before = bar_processes()
    start = time.monotonic()
    samples = []
    for index in range(seconds // 5):
        time.sleep(5)
        samples.append(bar_processes())
        if (index + 1) % 6 == 0:
            print(f"{label}: {index * 5 + 5}/{seconds}s sampled", flush=True)
    elapsed = time.monotonic() - start
    after = samples[-1]
    ticks = sum(p["ticks"] for p in after.values()) - sum(p["ticks"] for p in before.values())
    rss = [sum(p["rss"] for p in sample.values()) / 1048576 for sample in samples]
    result = {"label": label, "seconds": round(elapsed, 3), "cpu_percent_one_core": round(
        100 * ticks / os.sysconf("SC_CLK_TCK") / elapsed, 3),
        "rss_mean_mib": round(sum(rss) / len(rss), 2), "rss_max_mib": round(max(rss), 2),
        "processes": [p["argv"] for p in after.values()]}
    print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
    return result


def music_measure(seconds):
    saved = command("mpc", "status")
    assert "[paused]" in saved, "start with MPD paused"
    track = re.search(r"#(\d+)/\d+\s+(\d+):(\d+)/", saved)
    assert track, "cannot save MPD track/position"
    song, minutes, position = (int(x) for x in track.groups())
    muted = "[MUTED]" in command("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
    try:
        command("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1")
        command("mpc", "play")
        eventually(lambda s: "Playing" in s["music"]["tooltip"])
        time.sleep(2)
        return measure(seconds, "music")
    finally:
        command("mpc", "play", str(song))
        command("mpc", "seek", str(minutes * 60 + position))
        command("mpc", "pause")
        command("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1" if muted else "0")


def workspaces():
    original = state()["workspaces"]["items"]
    active = next(w["id"] for w in original if w["active"])
    target = next(w["id"] for w in original if not w["active"])
    try:
        ctl("action", "workspace", str(target))
        eventually(lambda s: any(w["id"] == target and w["active"] for w in s["workspaces"]["items"]))
        print("Workspace change via displayed stable ID: PASS", flush=True)
    finally:
        asyncio.run(compositor(settings()).focus(Commands().run, active))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("cycles", "controls", "workspaces", "measure", "music-measure"))
    parser.add_argument("--count", type=int, default=20)
    parser.add_argument("--seconds", type=int, default=60)
    parser.add_argument("--label", default="idle")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.mode == "cycles":
        cycles(args.count)
    elif args.mode == "controls":
        controls()
    elif args.mode == "workspaces":
        workspaces()
    else:
        if args.seconds < 5 or args.seconds % 5:
            parser.error("seconds must be a positive multiple of five")
        result = music_measure(args.seconds) if args.mode == "music-measure" else measure(args.seconds, args.label)
        if args.output:
            args.output.write_text(json.dumps(result, indent=2) + "\n")
