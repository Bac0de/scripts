#!/bin/bash

# Execute when initial VM(common) is setup
# or creating a snapshot
# TODO : implement removal(GC)

NAME=win10
ID=$1
TO=$2

if [[ -z "$ID" ]]; then
  ID=1
fi
if [[ -z "$TO" ]]; then
  TO=common
fi

cd /var/lib/libvirt/images
echo "Moving $NAME-$ID.qcow2 to $NAME-$TO.qcow2"
mv $NAME-$ID.qcow2 $NAME-$TO.qcow2
touch $NAME-${TO}_is_protected_via_chattr
chown libvirt-qemu:kvm $NAME-$TO.qcow2
# Apply CAP_LINUX_IMMUTABLE
chattr +i $NAME-$TO.qcow2
echo "$NAME-$TO.qcow2 is now write-protected"

echo "Creating $NAME-$ID.qcow2 from $NAME-$TO.qcow2"
qemu-img create -f qcow2 -b $NAME-$TO.qcow2 $NAME-$ID.qcow2
chown libvirt-qemu:kvm $NAME-$ID.qcow2

echo "Syncing..."
sync
echo "Synced"
