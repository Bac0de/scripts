#!/bin/bash

# Execute when initial VM(common) is setup

NAME=win10
ID=1

cd /var/lib/libvirt/images
echo "Moving $NAME-$ID.qcow2 to $NAME-common.qcow2"
mv $NAME-$ID.qcow2 $NAME-common.qcow2
touch $NAME-common_is_protected_via_chattr
chown libvirt-qemu:kvm $NAME-common.qcow2
# Apply CAP_LINUX_IMMUTABLE
chattr +i $NAME-common.qcow2
echo "$NAME-common.qcow2 is now write-protected"

echo "Creating $NAME-$ID.qcow2 from $NAME-common.qcow2"
qemu-img create -f qcow2 -b $NAME-common.qcow2 $NAME-$ID.qcow2
chown libvirt-qemu:kvm $NAME-$ID.qcow2

echo "Syncing..."
sync
echo "Synced"
