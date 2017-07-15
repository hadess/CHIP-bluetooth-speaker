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

CONTRIBUTING
------------
I'd be happy taking in patches to support other similar Linux-powered boards,
but note that I'm not interested in supporting non-systemd systems. A number
of features that make this installation more resilient require systemd, and
replacing them would be too much work.
