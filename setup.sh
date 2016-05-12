#!/bin/bash

# With help from:
# https://bbs.nextthing.co/t/basic-guide-to-turning-chip-into-a-bluetooth-audio-receiver-audio-sink/2187
# https://possiblelossofprecision.net/?p=1956
# http://kodi.wiki/view/HOW-TO:Autostart_Kodi_for_Linux#Add_a_new_systemd_script

NAME=${NAME:-CHIP Bluetooth speaker}
DEFAULT_PIN=${DEFAULT_PIN:-0000}

# Exit on failure
set -e
# Debug
# set -x

# Update, install the necessary plugins

apt-get update
apt-get upgrade -y
apt-get install -y bluez-tools pulseaudio-module-bluetooth pulseaudio

# See git log for details
cp -f bt-agent.bin /usr/bin/bt-agent

# Setup default hostname (and Bluetooth adapter name)
hostnamectl set-hostname "$NAME"
# FIXME: When the systemd version supports it
# hostnamectl set-chassis embedded
HOST_NAME=`hostname`
sed -i "s|chip$|$HOST_NAME|" /etc/hosts

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
chown -R chip:chip /home/chip/.config/bluetooth-default-pin
chmod 0600 /home/chip/.config/bluetooth-default-pin

cat <<EOF > /etc/systemd/system/bt-agent.service
[Unit]
Description=Bluetooth pairing agent

[Install]
WantedBy=multi-user.target

[Service]
User=chip
Group=chip
Type=simple
PrivateTmp=true
ExecStart=/usr/bin/bt-agent -c NoInputNoOutput -p /home/chip/.config/bluetooth-default-pin
Restart=on-failure
EOF

# http://bluetooth-pentest.narod.ru/software/bluetooth_class_of_device-service_generator.html
sed -i 's|^Class =|Class=0x200414|; s|^#Class =|Class=0x200414|' /etc/bluetooth/main.conf

systemctl restart bluetooth

bt-adapter --set Powered 1
bt-adapter --set DiscoverableTimeout 0
bt-adapter --set Discoverable 1
bt-adapter --set PairableTimeout 0
bt-adapter --set Pairable 1

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
