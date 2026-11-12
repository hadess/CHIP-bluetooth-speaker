Turn a CHIP into a Bluetooth speaker

After flashing your CHIP with Debian, log in as root and launch the
setup script:
```
NAME="My CHIP speaker" DEFAULT_PIN=1234 ./setup.sh
```

Don't forget to change the root and chip user passwords after installation.
The video output will be disabled to avoid interferences and noise coming out
of the speakers with some connectors.

Find more information about the project this was built for, Blutella, at:
http://www.hadess.net/2016/05/blutella-bluetooth-speaker-receiver.html

FLASHING, NOW THAT NEXT THING CO. IS GONE
-----------------------------------------

`flash.getchip.com` and the NTC apt repository are both dead. The images survive
on the Internet Archive as the [C.H.I.P. Flash Collection](https://archive.org/details/C.h.i.p.FlashCollection):
`stable-server-b149.zip` is the headless Debian 8 image this script is written
for, and the same item has `CHIP-tools.zip` for flashing it over USB FEL.

Debian 8 has also moved to the archive, so `apt-get` has to be repointed before
`setup.sh` will get past its first command. Replace the contents of
`/etc/apt/sources.list` with:

```
deb [trusted=yes] http://archive.debian.org/debian/ jessie main contrib non-free
deb [trusted=yes] http://archive.debian.org/debian-security/ jessie/updates main contrib non-free
```

and put `Acquire::Check-Valid-Until "false";` in `/etc/apt/apt.conf.d/99archive`.
The `[trusted=yes]` is needed because the jessie signing keys have expired; drop
the old `opensource.nextthing.co` line entirely. Note that `apt-get upgrade` has
nothing left to usefully do from here, and is slow on NAND — consider skipping it.

No monitor or keyboard is required for any of this. A CHIP running the server
image comes up as a USB CDC gadget, giving you both a serial console on the
host's `/dev/ttyACM0` and a USB ethernet interface you can ssh over.

SOURCES
-------

The bt-agent.bin binary is a compiled version of [bluez-tools](https://github.com/khvzak/bluez-tools),
which contains many fixes for crashers experienced during the development of
this script.

HARDWARE
--------

For the power supply to the CHIP, I'd recommend either using a powerful
USB charger, or a large high-quality battery coupled with USB power from
another appliance (I connect my speaker to my amp's MP3 player port).
If you don't supply enough or unstable power, you will likely [get
interferences, plops, and similar](https://bbs.nextthing.co/t/basic-guide-to-turning-chip-into-a-bluetooth-audio-receiver-audio-sink/2187/96?u=hadess).

If you're going to use a battery with an intermittent power supply (USB power
is cut when I turn off my amp), you can use [this script](https://github.com/stadar/chip_batt_autoshutdown)
to turn off the CHIP when power is cut.

One failure worth naming, because it looks like a crash and isn't: if the CHIP
powers itself off roughly 40 seconds into boot, with every LED going dark, that
is the AXP209 capping VBUS input at 500 mA because it detected a USB host rather
than a charger — the WiFi/Bluetooth firmware load then pushes it over the limit.
It happens on a computer's port or a powered hub, but not on a plain wall charger
(which shorts the data lines and so is detected as unlimited). Flashing with
CHIP-tools' `-n` flag writes a `bootcmd` that lifts the limit at every boot.

REPORTING PROBLEMS
------------------

Problems can be reported in the usual manner in the project's issues section:
https://github.com/hadess/CHIP-bluetooth-speaker/issues

Note that the script is usually only tested on a single piece of hardware by
the author, but that the script should work on any recent update to the 4.3
and 4.4 kernel releases from NextThingCo.

CONTRIBUTING
------------
I'd be happy taking in patches to support other similar Linux-powered boards,
but note that I'm not interested in supporting non-systemd systems. A number
of features that make this installation more resilient require systemd, and
replacing them would be too much work.
