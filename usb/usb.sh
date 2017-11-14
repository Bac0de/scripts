#!/bin/bash

# Print to the kernel buffer
exec > /dev/kmsg 2>&1

# Sleep for a bit to give libusb some buffer time
sleep 0.2

if [ -z "$ACTION" ]; then
  echo "batu: missing ACTION variable" 1>&2
  exit 1
fi

if [ "$ACTION" == "add" ]; then
  COMMAND="attach-device"
elif [ "$ACTION" == "remove" ]; then
  COMMAND="detach-device"
else
  echo "batu: Invalid action: $ACTION" 1>&2
  exit 1
fi

# This can be normal as passing sub devices is not supported
if [ -z "$BUSNUM" ]; then
  #echo "batu: missing BUSNUM variable" 1>&2
  exit 1
fi
if [ -z "$DEVNUM" ]; then
  #echo "batu: missing DEVNUM variable" 1>&2
  exit 1
fi

# This is a fatal error
if [ -z "$DEVPATH" ]; then
  echo "batu: missing DEVPATH variable" 1>&2
  exit 1
fi

# Pass if a hub is detected as sub devices must be passed instead of an entire hub
if echo $DRIVER $ID_MODEL $ID_MODEL_ENC $ID_MODEL_FROM_DATABASE | grep -qi hub; then
  exit 0
fi

# Convert variables so that libvirt can understand
BUSNUM=$((10#$BUSNUM))
DEVNUM=$((10#$DEVNUM))

#
# Match where the device belongs
#
# DEVPATH e.g : /devices/pci0000:00/0000:00:01.1/0000:01:00.0/usb1/1-6
# Start parsing from the back
ROOT=
while read node; do
  if [ -z $node ]; then
    continue
  fi
  if echo $node | grep -q ':'; then
    continue
  fi
  if echo $node | grep -q '\-'; then
    # ROOT must be numeric
    regex='^[0-9]+$'
    if [[ "$(echo $node | sed 's@-@@g')" =~ $regex ]]; then
      ROOT=$node
      break
    fi
  fi
done <<< "$(echo $DEVPATH | tr '/' '\n' | tac)"

if [ -z $ROOT ]; then
  echo "batu: unable to find ROOT for $DEVPATH" 1>&2
  exit 1
fi

DOMAIN=$(cat /etc/batu/usb/list | grep -w "$ROOT" | awk '{print $1}')

echo "batu: found USB bus=$BUSNUM device=$DEVNUM root=$ROOT for domain=$DOMAIN to $COMMAND"

echo "
<hostdev mode='subsystem' type='usb'>
  <source>
    <address bus='$BUSNUM' device='$DEVNUM' />
  </source>
</hostdev>
" > /etc/batu/run/usb/$DOMAIN-$BUSNUM-$DEVNUM.xml

# Attach via virsh
virsh $COMMAND $DOMAIN /etc/batu/run/usb/$DOMAIN-$BUSNUM-$DEVNUM.xml

# Delete from persistent storage so that next VM startup won't register
if [[ $COMMAND == "detach-device" ]]; then
  rm /etc/batu/run/usb/$DOMAIN-$BUSNUM-$DEVNUM.xml
fi
