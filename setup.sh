#!/bin/bash

# With help from:
# https://bbs.nextthing.co/t/basic-guide-to-turning-chip-into-a-bluetooth-audio-receiver-audio-sink/2187
# https://possiblelossofprecision.net/?p=1956
# http://kodi.wiki/view/HOW-TO:Autostart_Kodi_for_Linux#Add_a_new_systemd_script

NAME=${NAME:-CHIP Bluetooth speaker}
DEFAULT_PIN=${DEFAULT_PIN:-0000}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Exit on failure
set -e
# Debug
# set -x

# More early checks
if ! grep -q CONFIG_NAMESPACES /boot/config-$(uname -r) ; then
   echo "The kernel used doesn't seem to support namespaces, make sure the CHIP has been upgraded" 1>&2
   exit 1
fi

# Update, install the necessary plugins

apt-get update
apt-get upgrade -y
apt-get install -y bluez-tools pulseaudio-module-bluetooth pulseaudio libnss-myhostname crudini

# See git log for details
cp -f bt-agent.bin /usr/bin/bt-agent

# Setup default hostname (and Bluetooth adapter name)
hostnamectl set-hostname "$NAME"
hostnamectl set-chassis embedded 2>&1 > /dev/null || :

# Setup "no video" video mode
# See https://bbs.nextthing.co/t/u-boot-2016-01-00088-g99c771f/11642/2
DELETE_FW_ENV=0
if [ ! -f /etc/fw_env.config ] ; then
   echo "/dev/mtdblock3 0 0x400000 0x4000" > /etc/fw_env.config
   DELETE_FW_ENV=1
fi
# Disable video in U-Boot
# FIXME the logo still appears
# fw_setenv video-mode sunxi:720x576-24@60,monitor=none
# Disable video in Linux
BOOTARGS=$(fw_printenv | grep "^bootargs=" | sed 's,bootargs=,,')
if ! echo $BOOTARGS | grep -q video=none ; then
   fw_setenv bootargs "$BOOTARGS video=none"
fi
# Delete config file if we created it
if [ $DELETE_FW_ENV == "1" ] ; then
   rm -f /etc/fw_env.config
fi

# Disable the blinking light
if [ -f /sys/class/leds/chip\:white\:status/trigger ] ; then
   echo "@reboot root echo none | tee /sys/class/leds/chip\:white\:status/trigger > /dev/null" >> /etc/cron.d/disable-heartbeat-led
fi

# Setup bluez
cat <<EOF > /etc/bluetooth/audio.conf
[General]
Disable=Socket
Enable=Media,Source,Sink,Gateway
EOF

mkdir -p /home/chip/.config/
cat <<EOF > /home/chip/.config/bluetooth-default-pin
* $DEFAULT_PIN
EOF
chown -R chip:chip /home/chip/.config/
chmod 0600 /home/chip/.config/bluetooth-default-pin

cat <<EOF > /etc/systemd/system/bt-agent.service
[Unit]
Description=Bluetooth pairing agent
After=bt_rtk_hciattach@ttyS1.service

[Install]
WantedBy=multi-user.target

[Service]
User=chip
Group=chip
Type=simple
PrivateTmp=true
ExecStartPre=/usr/bin/bt-adapter --set Powered 1
ExecStartPre=/usr/bin/bt-adapter --set DiscoverableTimeout 0
ExecStartPre=/usr/bin/bt-adapter --set Discoverable 1
ExecStartPre=/usr/bin/bt-adapter --set PairableTimeout 0
ExecStartPre=/usr/bin/bt-adapter --set Pairable 1
ExecStart=/usr/bin/bt-agent -c NoInputNoOutput -p /home/chip/.config/bluetooth-default-pin
Restart=on-failure
EOF

sed -i 's|^#Class =|Class=|' /etc/bluetooth/main.conf
# http://bluetooth-pentest.narod.ru/software/bluetooth_class_of_device-service_generator.html
# Major Service Class: Rendering/Audio
# Major Device Class: Audio/Video
# Minor Device Class: Loudspeaker/HiFi Audio Device
crudini --set /etc/bluetooth/main.conf General Class 0x24043C

systemctl restart bluetooth
systemctl enable bt-agent.service
systemctl restart bt-agent.service

# Setup pulseaudio
cat <<EOF > /etc/systemd/system/pulseaudio.service
[Unit]
Description=PulseAudio Daemon

[Install]
WantedBy=multi-user.target

[Service]
User=chip
Group=chip
Type=simple
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --realtime --disallow-exit --no-cpu-limit
Restart=on-abort
RestartSec=5
EOF

systemctl enable pulseaudio.service
systemctl restart pulseaudio.service

# Volume control
install -m0755 bluetooth-volume-handler.py /usr/bin/
install -m0644 bluetooth-volume-handler.service /etc/systemd/system/

systemctl enable bluetooth-volume-handler.service
systemctl start bluetooth-volume-handler.service
