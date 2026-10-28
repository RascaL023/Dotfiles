"""Pure parsers and snapshots. No metadata is ever evaluated as shell/Yuck."""
import asyncio
import codecs
import datetime
import json
import os
import re
from pathlib import Path

from common import one_line, compositor_name


class Commands:
    def __init__(self, timeout=3):
        self.timeout = timeout
        self.children = set()

    async def run(self, *argv):
        proc = None
        try:
            proc = await asyncio.create_subprocess_exec(
                *argv, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
                env={**os.environ, "LC_ALL": "C"})
            self.children.add(proc)
            output, _ = await asyncio.wait_for(proc.communicate(), self.timeout)
            return output.decode(errors="replace").rstrip("\n") if proc.returncode == 0 else None
        except (OSError, asyncio.TimeoutError):
            return None
        finally:
            if proc:
                if proc.returncode is None:
                    try:
                        proc.kill()
                    except ProcessLookupError:
                        pass
                    await proc.wait()
                self.children.discard(proc)


class PipeWireEvents:
    """Decode concatenated pw-dump arrays, ignoring clients created by wpctl itself."""
    VOLUME_KEYS = {"volume", "mute", "channelVolumes", "softMute", "softVolumes"}
    DEFAULT_KEYS = {"default.audio.sink", "default.configured.audio.sink"}

    def __init__(self):
        self.buffer = ""
        self.utf8 = codecs.getincrementaldecoder("utf-8")(errors="replace")
        self.decoder = json.JSONDecoder()
        self.sinks = {}
        self.defaults = {}

    def feed(self, chunk):
        self.buffer += self.utf8.decode(chunk)
        changed = False
        while self.buffer.strip():
            self.buffer = self.buffer.lstrip()
            try:
                entries, end = self.decoder.raw_decode(self.buffer)
            except json.JSONDecodeError:
                if len(self.buffer) > 8 * 1024 * 1024:
                    raise ValueError("PipeWire JSON exceeds buffer limit")
                break
            self.buffer = self.buffer[end:]
            if not isinstance(entries, list):
                continue
            for entry in entries:
                if not isinstance(entry, dict) or "id" not in entry:
                    continue
                key = entry["id"]
                if "info" in entry and entry["info"] is None:
                    if key in self.sinks:
                        del self.sinks[key]
                        changed = True
                    for item in [item for item in self.defaults if item[0] == key]:
                        del self.defaults[item]
                        changed = True
                    continue
                info = entry.get("info") or {}
                props = info.get("props") or {}
                if props.get("media.class") == "Audio/Sink" or key in self.sinks:
                    old = self.sinks.get(key)
                    new = dict(old or {})
                    for param in (info.get("params") or {}).get("Props", []):
                        new.update({k: v for k, v in param.items() if k in self.VOLUME_KEYS})
                    if "node.name" in props:
                        new["name"] = props["node.name"]
                    if old != new:
                        self.sinks[key] = new
                        changed = True
                for metadata in entry.get("metadata") or []:
                    name = metadata.get("key")
                    if name in self.DEFAULT_KEYS:
                        index = (key, name)
                        value = metadata.get("value")
                        if index not in self.defaults or self.defaults[index] != value:
                            self.defaults[index] = value
                            changed = True
        return changed


def workspace_state(rows, active, base):
    known = {int(x["id"]): x for x in rows if int(x["id"]) > 0}
    active_id = int(active.get("id", 0))
    ids = set(base) | {n for n, x in known.items() if x.get("windows", 0) > 0}
    if active_id > 0:
        ids.add(active_id)
    return {"available": True, "items": [
        {"id": n, "name": one_line(known.get(n, {}).get("name", n)),
         "label": str(n), "active": n == active_id,
         "occupied": known.get(n, {}).get("windows", 0) > 0} for n in sorted(ids)]}


class Hyprland:
    EVENTS = {"workspace", "workspacev2", "focusedmon", "focusedmonv2", "createworkspace",
              "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "moveworkspace",
              "moveworkspacev2", "openwindow", "closewindow", "movewindow", "movewindowv2"}

    async def subscribe(self, writer):
        pass

    def relevant(self, line):
        return line.decode(errors="replace").split(">>", 1)[0] in self.EVENTS

    @staticmethod
    def socket_path():
        signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        if not signature or "/" in signature:
            raise OSError("Hyprland instance signature unavailable")
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
        candidates = (runtime / "hypr" / signature / ".socket2.sock",
                      Path("/tmp/hypr") / signature / ".socket2.sock")
        return next((p for p in candidates if p.exists()), candidates[0])

    async def snapshot(self, run, cfg):
        rows, active = await asyncio.gather(run("hyprctl", "-j", "workspaces"),
                                           run("hyprctl", "-j", "activeworkspace"))
        if rows is None or active is None:
            return None
        return workspace_state(json.loads(rows), json.loads(active), cfg["workspaces"])

    async def focus(self, run, number):
        # Hyprland's Lua config provider (0.55+) requires dispatcher objects.
        # Only a validated integer is interpolated into this fixed expression.
        result = await run("hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {int(number)} }})")
        if result is None:
            result = await run("hyprctl", "dispatch", "workspace", str(int(number)))
        return result


def niri_workspace_state(rows, monitor):
    output = str(monitor)
    if output not in {w.get("output") for w in rows}:
        output = next((w["output"] for w in rows if w.get("is_focused")), None)
    rows = sorted((w for w in rows if w.get("output") == output), key=lambda w: w["idx"])
    return {"available": True, "items": [
        {"id": int(w["id"]), "label": str(w["idx"]),
         "name": one_line(w.get("name") or f"Workspace {w['idx']}"),
         "active": bool(w.get("is_active")), "occupied": w.get("active_window_id") is not None}
        for w in rows]}


class Niri:
    EVENTS = {"WorkspacesChanged", "WorkspaceActivated", "WorkspaceActiveWindowChanged",
              "WorkspaceUrgencyChanged", "WindowOpenedOrChanged", "WindowClosed"}

    @staticmethod
    def socket_path():
        path = os.environ.get("NIRI_SOCKET")
        if not path:
            raise OSError("NIRI_SOCKET unavailable")
        return path

    async def subscribe(self, writer):
        writer.write(b'"EventStream"\n')
        await writer.drain()

    def relevant(self, line):
        event = json.loads(line)
        return isinstance(event, dict) and bool(self.EVENTS.intersection(event))

    async def snapshot(self, run, cfg):
        rows = await run("niri", "msg", "-j", "workspaces")
        return niri_workspace_state(json.loads(rows), cfg["monitor"]) if rows is not None else None

    async def focus(self, run, number):
        # Use stable IDs: Niri indices shift when workspaces are inserted or removed.
        reader, writer = await asyncio.wait_for(asyncio.open_unix_connection(self.socket_path()), 3)
        try:
            message = {"Action": {"FocusWorkspace": {"reference": {"Id": int(number)}}}}
            writer.write((json.dumps(message) + "\n").encode())
            await writer.drain()
            reply = json.loads(await asyncio.wait_for(reader.readline(), 3))
            return "ok" if "Ok" in reply else None
        finally:
            writer.close()
            await writer.wait_closed()


def compositor(cfg):
    return Niri() if compositor_name(cfg) == "niri" else Hyprland()


def volume_state(output):
    match = re.search(r"Volume:\s*([0-9.]+)", output or "")
    if not match:
        return None
    percent = round(float(match[1]) * 100)
    muted = "[MUTED]" in output
    if muted:
        icon = "󰝟"
    elif percent == 0:
        icon = "󰖁"
    elif percent <= 33:
        icon = "󰕿"
    elif percent <= 66:
        icon = "󰖀"
    else:
        icon = "󰕾"
    return {"available": True, "muted": muted, "percent": percent,
            "text": f"{percent}%", "icon": icon,
            "tooltip": f"Volume {percent}%{' · Muted' if muted else ''}"}


def brightness_state(device="auto", root=Path("/sys/class/backlight")):
    candidates = []
    for path in root.glob("*"):
        if device != "auto" and path.name != device:
            continue
        try:
            maximum = int((path / "max_brightness").read_text())
            if maximum <= 0:
                continue
            current = max(0, min(maximum, int((path / "brightness").read_text())))
            kind = (path / "type").read_text().strip()
            candidates.append(({"raw": 0, "platform": 1, "firmware": 2}.get(kind, 3),
                               path.name, round(current * 100 / maximum)))
        except (OSError, ValueError):
            continue
    if not candidates:
        return None
    _, name, percent = min(candidates)
    return {"available": True, "device": name, "percent": percent, "text": f"{percent}%",
            "icon": "󰃞" if percent <= 33 else ("󰃟" if percent <= 66 else "󰃠"),
            "tooltip": f"Brightness {percent}%\n{name}"}


def nm_fields(line):
    fields, value, escaped = [], "", False
    for char in line:
        if escaped:
            value += char
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            fields.append(value)
            value = ""
        else:
            value += char
    fields.append(value + ("\\" if escaped else ""))
    return fields


def network_state(output):
    if output is None:
        return None
    rows = [nm_fields(line) for line in output.splitlines()]
    connected = [r for r in rows if len(r) == 4 and r[2] == "connected" and r[1] != "loopback"]
    connected.sort(key=lambda r: (r[1] not in ("ethernet", "wifi"), r[0]))
    if not connected:
        return {"available": True, "icon": "󰤭", "tooltip": "Disconnected"}
    icon = "" if connected[0][1] == "wifi" else "󰈀"
    return {"available": True, "icon": icon,
            "tooltip": "\n".join(f"{r[0]} · {r[3]}" for r in connected)}


def battery_state(root=Path("/sys/class/power_supply")):
    batteries = []
    for path in sorted(root.glob("*")):
        try:
            if (path / "type").read_text().strip() != "Battery":
                continue
            if (path / "present").exists() and (path / "present").read_text().strip() == "0":
                continue
            capacity = max(0, min(100, int((path / "capacity").read_text())))
            status = (path / "status").read_text().strip()
            batteries.append((path.name, capacity, status))
        except (OSError, ValueError):
            continue
    if not batteries:
        return None
    percent = round(sum(x[1] for x in batteries) / len(batteries))
    charging = any(x[2] == "Charging" for x in batteries)
    # Nerd Font battery levels: outline, 10%, 20%, ... 100%.
    icons = (("󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅")
             if charging else
             ("󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"))
    return {"available": True, "warning": percent <= 20 and not charging,
            "text": f"{percent}%", "icon": icons[percent // 10],
            "tooltip": "\n".join(f"{n}: {c}% · {s}" for n, c, s in batteries)}


def notification_state(output):
    value = json.loads(output)
    count = max(0, int(value.get("count", 0)))
    dnd = value.get("dnd", False) in (True, "true")
    return {"available": True, "count": count, "dnd": dnd,
            "icon": "󰂛" if dnd else ("󰂚" if count else "󰂜"),
            "tooltip": f"Notifications: {count}\nDo Not Disturb: {'On' if dnd else 'Off'}"}


def clock_state():
    now = datetime.datetime.now().astimezone()
    return {"time": now.strftime("%H:%M"), "date": now.strftime("%a, %d %b"),
            "tooltip": now.strftime("%A, %d %B %Y · %Z")}


def choose_player(players, current, cfg):
    native = any(p["key"] == "mpd" for p in players)
    if native:
        players = [p for p in players if p["kind"] != "mpris" or
                   p["name"].split(".")[0] not in cfg["mpd_bridges"]]
    playing = [p for p in players if p["status"] == "Playing"]
    pool = playing or players
    for player in pool:
        if player["key"] == current:
            return player
    def rank(player):
        prefs = cfg["preferred"]
        names = (player["key"], player["name"].split(".")[0])
        return (min((prefs.index(n) for n in names if n in prefs), default=len(prefs)), player["key"])
    return min(pool, key=rank) if pool else None


async def music_players(run, cfg):
    async def mpris(name):
        prefix = ("playerctl", f"--player={name}")
        status, title, artist = await asyncio.gather(
            run(*prefix, "status"), run(*prefix, "metadata", "xesam:title"),
            run(*prefix, "metadata", "xesam:artist"))
        if status not in ("Playing", "Paused"):
            return None
        return {"key": "mpris:" + name, "name": name, "kind": "mpris",
                "status": status, "title": title or name, "artist": artist or ""}

    async def mpd():
        status, title, artist = await asyncio.gather(
            run("mpc", "status"), run("mpc", "-f", "%title%", "current"),
            run("mpc", "-f", "%artist%", "current"))
        if status is None or not re.search(r"^\[(playing|paused)\]", status, re.M):
            return None
        return {"key": "mpd", "name": "mpd", "kind": "mpd",
                "status": "Playing" if re.search(r"^\[playing\]", status, re.M) else "Paused",
                "title": title or "MPD", "artist": artist or ""}

    names = (await run("playerctl", "-l")) if cfg["mpris"] else None
    tasks = [mpris(n) for n in (names or "").splitlines() if re.fullmatch(r"[A-Za-z0-9_.-]+", n)]
    if cfg["mpd"]:
        tasks.append(mpd())
    return [p for p in await asyncio.gather(*tasks) if p]


def music_state(player, cfg):
    if not player:
        return None
    title = one_line(player["title"])
    limit = cfg["title_limit"]
    return {"available": True, "source": player["key"],
            "title": title if len(title) <= limit else title[:limit - 1] + "…",
            "limit": limit, "icon": "󰎈" if player["status"] == "Playing" else "󰏤",
            "tooltip": f"{player['artist']}\n{player['title']}\n{player['name']} · {player['status']}".strip()}
