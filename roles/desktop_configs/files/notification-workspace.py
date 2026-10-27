#!/usr/bin/python3
"""Focus notification senders in i3, only after a left-click dismissal."""

import configparser
import ctypes as C
import ctypes.util
import json
import logging
import os
from pathlib import Path
import re
import subprocess
import time

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


class XEvent(C.Union):
    pass


class EventCookie(C.Structure):
    _fields_ = [("type", C.c_int), ("serial", C.c_ulong), ("send_event", C.c_int),
                ("display", C.c_void_p), ("extension", C.c_int), ("evtype", C.c_int),
                ("cookie", C.c_uint), ("data", C.c_void_p)]


class RawButton(C.Structure):
    _fields_ = [("type", C.c_int), ("serial", C.c_ulong), ("send_event", C.c_int),
                ("display", C.c_void_p), ("extension", C.c_int), ("evtype", C.c_int),
                ("time", C.c_ulong), ("deviceid", C.c_int), ("sourceid", C.c_int),
                ("detail", C.c_int)]


class EventMask(C.Structure):
    _fields_ = [("deviceid", C.c_int), ("mask_len", C.c_int),
                ("mask", C.POINTER(C.c_ubyte))]


XEvent._fields_ = [("type", C.c_int), ("cookie", EventCookie), ("pad", C.c_long * 24)]


class ClassHint(C.Structure):
    _fields_ = [("name", C.c_void_p), ("class_name", C.c_void_p)]


class X11:
    """Observe raw mouse events, including releases during Dunst's mouse grab."""
    def __init__(self):
        self.lib = C.CDLL(ctypes.util.find_library("X11"))
        signatures = {
            "XOpenDisplay": (C.c_void_p, [C.c_char_p]),
            "XDefaultRootWindow": (C.c_ulong, [C.c_void_p]),
            "XConnectionNumber": (C.c_int, [C.c_void_p]),
            "XQueryTree": (C.c_int, [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong),
                                    C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)),
                                    C.POINTER(C.c_uint)]),
            "XGetClassHint": (C.c_int, [C.c_void_p, C.c_ulong, C.POINTER(ClassHint)]),
            "XPending": (C.c_int, [C.c_void_p]),
            "XNextEvent": (C.c_int, [C.c_void_p, C.POINTER(XEvent)]),
            "XFree": (C.c_int, [C.c_void_p]),
            "XFlush": (C.c_int, [C.c_void_p]),
            "XSetErrorHandler": (C.c_void_p, [C.c_void_p]),
            "XQueryExtension": (C.c_int, [C.c_void_p, C.c_char_p, C.POINTER(C.c_int),
                                         C.POINTER(C.c_int), C.POINTER(C.c_int)]),
            "XQueryPointer": (C.c_int, [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong),
                                       C.POINTER(C.c_ulong), C.POINTER(C.c_int),
                                       C.POINTER(C.c_int), C.POINTER(C.c_int),
                                       C.POINTER(C.c_int), C.POINTER(C.c_uint)]),
            "XGetEventData": (C.c_int, [C.c_void_p, C.POINTER(EventCookie)]),
            "XFreeEventData": (None, [C.c_void_p, C.POINTER(EventCookie)]),
        }
        for name, (result, args) in signatures.items():
            function = getattr(self.lib, name)
            function.restype, function.argtypes = result, args
        # Windows can disappear between discovery and subscription.
        self.error_handler = C.CFUNCTYPE(C.c_int, C.c_void_p, C.c_void_p)(lambda *_: 0)
        self.lib.XSetErrorHandler(self.error_handler)
        self.display = self.lib.XOpenDisplay(None)
        if not self.display:
            raise RuntimeError("Cannot open X11 display")
        self.root = self.lib.XDefaultRootWindow(self.display)
        self.dunst_windows = set()
        self.pressed = set()
        self.xi = C.CDLL(ctypes.util.find_library("Xi"))
        self.xi.XIQueryVersion.argtypes = [C.c_void_p, C.POINTER(C.c_int), C.POINTER(C.c_int)]
        self.xi.XISelectEvents.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(EventMask), C.c_int]
        major, minor = C.c_int(2), C.c_int(1)
        if self.xi.XIQueryVersion(self.display, C.byref(major), C.byref(minor)) != 0:
            raise RuntimeError("XInput 2.1 is required")
        self.opcode, first_event, first_error = C.c_int(), C.c_int(), C.c_int()
        self.lib.XQueryExtension(self.display, b"XInputExtension", C.byref(self.opcode),
                                 C.byref(first_event), C.byref(first_error))
        # XIAllMasterDevices; RawButtonPress (15), RawButtonRelease (16).
        bits = (C.c_ubyte * 3)(0, 128, 1)
        mask = EventMask(1, 3, bits)
        self.xi.XISelectEvents(self.display, self.root, C.byref(mask), 1)
        self.lib.XFlush(self.display)

    def pointer_window(self):
        root, child, state = C.c_ulong(), C.c_ulong(), C.c_uint()
        rx, ry, wx, wy = C.c_int(), C.c_int(), C.c_int(), C.c_int()
        self.lib.XQueryPointer(self.display, self.root, C.byref(root), C.byref(child),
                               C.byref(rx), C.byref(ry), C.byref(wx), C.byref(wy),
                               C.byref(state))
        return child.value

    def watch_dunst(self):
        root, parent, count = C.c_ulong(), C.c_ulong(), C.c_uint()
        children = C.POINTER(C.c_ulong)()
        if not self.lib.XQueryTree(self.display, self.root, C.byref(root),
                                  C.byref(parent), C.byref(children), C.byref(count)):
            return
        try:
            found = set()
            for window in children[:count.value]:
                hint = ClassHint()
                if self.lib.XGetClassHint(self.display, window, C.byref(hint)):
                    try:
                        labels = [C.string_at(value).decode(errors="replace").lower()
                                  for value in (hint.name, hint.class_name) if value]
                        if "dunst" in labels:
                            found.add(window)
                    finally:
                        for value in (hint.name, hint.class_name):
                            if value:
                                self.lib.XFree(value)
            self.dunst_windows = found
        finally:
            if children:
                self.lib.XFree(children)
        self.lib.XFlush(self.display)

    def buttons(self):
        while self.lib.XPending(self.display):
            event = XEvent()
            self.lib.XNextEvent(self.display, C.byref(event))
            if event.type != 35 or event.cookie.extension != self.opcode.value:
                continue
            if not self.lib.XGetEventData(self.display, C.byref(event.cookie)):
                continue
            try:
                raw = C.cast(event.cookie.data, C.POINTER(RawButton)).contents
                if event.cookie.evtype == 15:
                    # Do not retain clicks in other applications.
                    self.watch_dunst()
                    if self.pointer_window() in self.dunst_windows:
                        self.pressed.add(raw.detail)
                elif event.cookie.evtype == 16 and raw.detail in self.pressed:
                    self.pressed.discard(raw.detail)
                    yield raw.detail
            finally:
                self.lib.XFreeEventData(self.display, C.byref(event.cookie))


def command_json(*args):
    return json.loads(subprocess.check_output(args, timeout=3))


def identity(value):
    return re.sub(r"[^a-z0-9]", "", value.lower())


def identities(value):
    values = {identity(value), identity(value.removesuffix(".desktop").rsplit(".", 1)[-1])}
    for suffix in ("esr", "desktop"):
        values.update(item[:-len(suffix)] for item in list(values)
                      if item.endswith(suffix))
    return values - {""}


def application_classes(appname):
    """Use desktop files to bridge notification names and X11 WM_CLASS."""
    names = identities(appname)
    roots = [os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))]
    roots += os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    for root in roots:
        for path in (Path(root) / "applications").glob("*.desktop"):
            entry = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                entry.read(path)
                section = entry["Desktop Entry"]
                labels = identities(path.stem) | identities(section.get("Name", ""))
                if names & labels:
                    names |= identities(section.get("StartupWMClass", ""))
            except (OSError, configparser.Error, KeyError):
                continue
    return names


def windows(tree):
    """Yield windows in i3's most-recently-focused order."""
    if tree.get("window_properties"):
        yield tree
    children = tree.get("nodes", []) + tree.get("floating_nodes", [])
    order = tree.get("focus", [])
    children.sort(key=lambda node: order.index(node["id"])
                  if node["id"] in order else len(order))
    for child in children:
        yield from windows(child)


def focus_sender(notification_id):
    history = command_json("dunstctl", "history")
    notification = next((item for group in history["data"] for item in group
                         if item["id"]["data"] == notification_id), None)
    if not notification:
        return
    names = application_classes(notification["appname"]["data"])
    for window in windows(command_json("i3-msg", "-t", "get_tree")):
        props = window["window_properties"]
        if any(names & identities(props.get(key) or "") for key in ("class", "instance")):
            subprocess.run(["i3-msg", f'[con_id={window["id"]}] focus'],
                           check=True, capture_output=True, timeout=3)
            return


class NotificationClicks:
    def __init__(self):
        self.x = X11()
        self.last_click = (0, 0)
        self.scan()
        GLib.io_add_watch(self.x.lib.XConnectionNumber(self.x.display),
                          GLib.IO_IN, self.events)
        GLib.timeout_add(1000, self.scan)

    def scan(self):
        self.x.watch_dunst()
        self.events()
        return True

    def events(self, *_):
        for button in self.x.buttons():
            self.last_click = (button, time.monotonic())
        return True

    def closed(self, notification_id, reason):
        if int(reason) == 2:
            # The X11 event and D-Bus signal arrive on separate connections.
            GLib.timeout_add(100, self.maybe_focus, int(notification_id))

    def maybe_focus(self, notification_id):
        self.events()
        button, timestamp = self.last_click
        if button == 1 and time.monotonic() - timestamp < 0.5:
            self.last_click = (0, 0)
            try:
                focus_sender(notification_id)
            except (OSError, subprocess.SubprocessError, ValueError, KeyError):
                logging.exception("Could not focus notification sender")
        return False


def main():
    DBusGMainLoop(set_as_default=True)
    clicks = NotificationClicks()
    bus = dbus.bus.BusConnection(dbus.bus.BUS_SESSION)

    def message_received(connection, message):
        if (message.get_interface() == "org.freedesktop.Notifications"
                and message.get_member() == "NotificationClosed"):
            clicks.closed(*message.get_args_list())

    bus.add_message_filter(message_received)
    # A dedicated monitor receives directed signals even after the sender exits.
    bus.call_blocking("org.freedesktop.DBus", "/org/freedesktop/DBus",
                      "org.freedesktop.DBus.Monitoring", "BecomeMonitor", "asu",
                      (["type='signal',interface='org.freedesktop.Notifications',"
                        "member='NotificationClosed'"], dbus.UInt32(0)))
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
