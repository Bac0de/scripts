#!/bin/bash

NAME=win10
ID=$1
FROM=$2
# $3 in GB unit
# SIZE is only relevant when creating an initial image
# TODO : allow multiple guests to have its own dynamic sizes
SIZE=$3

UUID=$(uuidgen)
# batu -> ba:40
MAC=$(hexdump -n4 -e'/4 "ba:40" 4/1 ":%02x"' /dev/urandom)

if [[ -z "$FROM" ]]; then
  FROM=0
fi

echo "Creating $NAME-$ID"
echo "UUID - $UUID"
echo "MAC -  $MAC"

# Create a new VM using new credentials
# TODO : Check duplicates with existing VMs across network
cp /etc/batu/skeleton/$NAME.xml          /tmp/$NAME-$ID-$UUID.xml
sed -i -e s@BATU_CREATE_NAME@$NAME-$ID@g /tmp/$NAME-$ID-$UUID.xml
sed -i -e s@BATU_CREATE_UUID@$UUID@g     /tmp/$NAME-$ID-$UUID.xml
sed -i -e s@BATU_CREATE_MAC@$MAC@g       /tmp/$NAME-$ID-$UUID.xml

cd /var/lib/libvirt/images
if [[ "$FROM" != "0" ]]; then
  # Fork from another VM
  ORIG=$FROM-$(date "+%y%m%d")-$(uuidgen)
  /etc/batu/control/initial.sh $FROM $ORIG
  qemu-img create -f qcow2 -b $NAME-$ORIG.qcow2 $NAME-$ID.qcow2
  sed -i -e s@BATU_CREATE_IMG@$NAME-$ID.qcow2@g /tmp/$NAME-$ID-$UUID.xml
else
  # Fork from base image
  if [ -e $NAME-common.qcow2 ]; then
    qemu-img create -f qcow2 -b $NAME-common.qcow2 $NAME-$ID.qcow2
    sed -i -e s@BATU_CREATE_IMG@$NAME-$ID.qcow2@g /tmp/$NAME-$ID-$UUID.xml
  else
    # Create an initial image
    # ID must be 1
    if [[ "$ID" != "1" ]]; then
      echo "Initial image hasn't been created with $NAME-1!" 1>&2
      echo "Please run initial.sh after setting up $NAME-1!" 1>&2
      exit 1
    fi
    qemu-img create -f qcow2 -S ${SIZE}G $NAME-$ID.qcow2
  fi
fi

chown libvirt-qemu:kvm $NAME-$ID.qcow2
virsh undefine $NAME-$ID 2>/dev/null
virsh define /tmp/$NAME-$ID-$UUID.xml
rm /tmp/$NAME-$ID-$UUID.xml
