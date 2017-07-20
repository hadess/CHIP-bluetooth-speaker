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
