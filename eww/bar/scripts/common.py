"""Paths, validated settings and complete public state for this bar only."""
import hashlib
import json
import os
import re
from pathlib import Path
from calendar_data import calendar_state

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "settings.json"
MODULES = ("launcher", "workspaces", "music", "clock", "volume", "brightness",
           "network", "battery", "notifications", "power")


def compositor_name(cfg, env=None):
    if cfg["compositor"] != "auto":
        return cfg["compositor"]
    env = os.environ if env is None else env
    desktop = env.get("XDG_CURRENT_DESKTOP", "").lower().split(":")
    for name in ("niri", "hyprland"):
        if name in desktop:
            return name
    return "niri" if env.get("NIRI_SOCKET") else "hyprland"


def settings(path=SETTINGS):
    cfg = json.loads(Path(path).read_text())
    if cfg["compositor"] not in ("auto", "hyprland", "niri"):
        raise ValueError("compositor must be auto, hyprland, or niri")
    if not isinstance(cfg["monitor"], (str, int)):
        raise ValueError("monitor must be a connector name or index")
    for name in MODULES:
        if not isinstance(cfg["modules"][name], bool):
            raise ValueError(f"modules.{name} must be boolean")
    device = cfg["brightness"]["device"]
    if not isinstance(device, str) or not re.fullmatch(r"[A-Za-z0-9_.:-]+", device):
        raise ValueError("brightness.device must be auto or an exact sysfs device name")
    if not cfg["workspaces"] or any(type(n) is not int or n < 1 for n in cfg["workspaces"]):
        raise ValueError("workspaces must contain positive integers")
    for key, minimum in (("battery", 5), ("debounce", .05),
                         ("reconnect_max", 1), ("command_timeout", .1)):
        if not minimum <= cfg["intervals"][key] <= 3600:
            raise ValueError(f"intervals.{key} is out of range")
    music = cfg["music"]
    for key in ("mpris", "mpd"):
        if type(music[key]) is not bool:
            raise ValueError(f"music.{key} must be boolean")
    for key in ("preferred", "mpd_bridges"):
        if not isinstance(music[key], list) or any(not isinstance(x, str) for x in music[key]):
            raise ValueError(f"music.{key} must be a list of names")
    if type(music["title_limit"]) is not int or not 1 <= music["title_limit"] <= 24:
        raise ValueError("music.title_limit must be 1–24")
    for name in ("launcher", "network", "notifications", "dnd", "menu", "lock",
                 "suspend", "logout", "reboot", "shutdown"):
        argv = cfg["commands"][name]
        if name == "logout" and argv is None:
            argv = (["niri", "msg", "action", "quit", "--skip-confirmation"]
                    if compositor_name(cfg) == "niri" else ["hyprctl", "dispatch", "hl.dsp.exit()"])
        if not isinstance(argv, list) or not argv or any(not isinstance(x, str) or not x for x in argv):
            raise ValueError(f"commands.{name} must be a nonempty argv array")
        cfg["commands"][name] = [os.path.expanduser(x) for x in argv]
    return cfg


def runtime_dir():
    base = Path(os.environ.get("XDG_RUNTIME_DIR", f"/tmp/eww-{os.getuid()}"))
    digest = hashlib.sha256(os.fsencode(ROOT)).hexdigest()[:12]
    path = base / f"eww-islands-{digest}"
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.is_symlink() or path.stat().st_uid != os.getuid():
        raise RuntimeError(f"unsafe runtime directory: {path}")
    path.chmod(0o700)
    return path


def one_line(value):
    return " ".join(str(value or "").split())


def workspace_layout(value):
    tokens = (ROOT / "styles/_tokens.scss").read_text()
    def px(name):
        match = re.search(r"^\$" + name + r":\s*(\d+)px\s*;", tokens, re.M)
        if not match:
            raise ValueError(f"_tokens.scss needs numeric ${name} in px")
        return int(match[1])
    count = len(value["items"])
    dot = px("workspace-dot-width")
    button = dot + 2 * px("workspace-hit-padding") + px("workspace-gap")
    # Reserve one active pill even during an activation transition.
    value["width"] = min(px("workspace-area"), count * button + px("workspace-active-width") - dot)
    return value


def initial_state(cfg):
    tokens = (ROOT / "styles/_tokens.scss").read_text()
    def token(name, unit):
        match = re.search(r"^\$" + name + r":\s*(\d+)" + unit + r"\s*;", tokens, re.M)
        if not match:
            raise ValueError(f"_tokens.scss needs numeric ${name} in {unit}")
        return int(match[1])
    return {
        "modules": cfg["modules"].copy(),
        "ui": {"icon_box": token("right-icon-box", "px"),
               "island_gap": token("right-island-gap", "px"),
               "reveal_duration": str(token("control-transition", "ms")) + "ms",
               "calendar_duration": str(token("calendar-transition", "ms")) + "ms",
               # Non-exclusive layer surfaces are already placed below the reserved bar.
               "calendar_offset": str(token("calendar-gap-top", "px")) + "px"},
        "workspaces": workspace_layout({"available": False, "items": [
            {"id": n, "name": str(n), "label": str(n), "active": False, "occupied": False}
            for n in sorted(set(cfg["workspaces"]))]}),
        "clock": {"time": "--:--", "date": "", "tooltip": ""},
        "calendar": calendar_state(),
        "music": {"available": False, "source": "", "title": "", "tooltip": "",
                  "icon": "󰎈", "limit": cfg["music"]["title_limit"]},
        "volume": {"available": False, "muted": False, "percent": 0,
                   "text": "--", "icon": "󰝟", "tooltip": "Audio unavailable"},
        "brightness": {"available": False, "device": "", "percent": 0,
                       "text": "--", "icon": "󰃞", "tooltip": "Backlight unavailable"},
        "network": {"available": False, "icon": "󰤭", "tooltip": "Network unavailable"},
        "battery": {"available": False, "warning": False, "text": "", "icon": "",
                    "tooltip": ""},
        "notifications": {"available": False, "dnd": False, "count": 0,
                          "icon": "󰂛", "tooltip": "SwayNC unavailable"},
    }
