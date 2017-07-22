#!/usr/bin/python

import os
import sys
import signal
import logging
import logging.handlers
from gi.repository import GLib
from gi.repository import Gio

def play_sound(name):
    if name == 'disconnect':
        sound_name = 'device-removed'
    elif name == 'connect':
        sound_name = 'device-added'
    else:
        return

    cmd = "paplay /usr/share/sounds/freedesktop/stereo/{}.oga".format(sound_name)
    os.system(cmd)

def media_property_changed_cb(conn, sender_name, path, interface, signal, parameters):

    if not path.startswith('/org/bluez/hci0/dev_'):
        return

    arg0 = parameters.unpack()[0]
    if not arg0 == 'org.bluez.MediaTransport1' and not arg0 == 'org.bluez.MediaControl1':
        return

    volume = parameters.unpack()[1].get('Volume')
    connected = parameters.unpack()[1].get('Connected')
    state = parameters.unpack()[1].get('State')

    if volume != None:
        volume_percentage = format(volume / 1.27, '.2f')
        print ("Detected volume change: {}/127 ({}%)".format(volume, volume_percentage))
        cmd = "amixer -q cset numid=1 {}%".format(volume_percentage)
        os.system(cmd)

    if connected != None:
        if connected == False:
            cmd = play_sound('disconnect')
        elif connected == True:
            cmd = play_sound('connect')

def shutdown(signum, frame):
	mainloop.quit()

if __name__ == "__main__":
    # shut down on a TERM signal
    signal.signal(signal.SIGTERM, shutdown)

    # Get the system bus
    try:
        conn = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    except Exception as ex:
        GLib.warning("Unable to get the system dbus: '{0}'. Exiting. Is dbus running?".format(ex.message))
        sys.exit(1)

    # listen for MediaTransport1 signals
    conn.signal_subscribe("org.bluez",
            None,
            "PropertiesChanged",
            None,
            None,
            Gio.DBusSignalFlags.NONE,
            media_property_changed_cb)

    try:
        mainloop = GLib.MainLoop()
        mainloop.run()
    except KeyboardInterrupt:
        pass
    except:
        sys.exit(1)

    sys.exit(0)
