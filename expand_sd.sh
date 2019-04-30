#!/bin/bash
file="/boot/temporaryfiles.txt"
if [ -f $file ]; then
  sudo rm $file
  sudo raspi-config nonint do_expand_rootfs
  sleep 3
  sudo reboot
fi
