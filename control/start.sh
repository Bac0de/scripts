#!/bin/bash

NAME=win10
ID=$1

virsh start $NAME-$ID

# Attach registered USB devices
ls -d /etc/batu/run/usb/$NAME-$ID-*.xml | while read devices; do
  virsh attach-device $NAME-$ID $devices
done
