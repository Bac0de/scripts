#!/bin/bash

# Run GUI applications on X
export DISPLAY=:0

# Wait until GUI is initialized (LXDE)
while ! pgrep lxsession > /dev/null; do sleep 0.5; done
sleep 1

# Start libvirtd
service libvirtd start

# Initialize libvirt network
virsh net-start default

# Fix /dev/kvm node permission
chown libvirt-qemu:libvirt-qemu /dev/kvm
