#!/bin/bash

# Run GUI applications on X
export DISPLAY=:0

# Wait until GUI is initialized (LXDE)
while ! pgrep lxsession > /dev/null; do sleep 0.5; done
sleep 1

# Check for batu kernel
if ! uname -a | grep -q batu; then
  echo "Generic Linux kernel detected!" 1>&2
  echo "Using Batu Linux kernel is required for Batu to properly function." 1>&2
  echo "Use at your own risk!" 1>&2
fi

# Start libvirtd
service libvirtd start

# Initialize libvirt default network
virsh net-start default

# Fix /dev/kvm node permission
chown libvirt-qemu:libvirt-qemu /dev/kvm

# Fix XAuth permission
runuser -u batu xhost si:localuser:libvirt-qemu
runuser -u batu xhost si:localuser:root

# Set hugepages
/etc/batu/set_hugepages.sh

# Set tunables
# - Tweak THP
#   QEMU runs on hugepages explicitly
#   but allow rest of the system(including QEMU other than VM allocation)
#   to benefit from jemalloc's THP
echo "Tweaking THP"
echo "madvise" > /sys/kernel/mm/transparent_hugepage/enabled
echo "madvise" > /sys/kernel/mm/transparent_hugepage/defrag
# - Disable entropy contributions
#   Should be the default for non-rotational storage,
#   disable it altogether to prevent additional latency
echo "Disabling entropy contributions"
find /sys -name add_random -exec sh -c 'echo "0" > {}' \;
# - Set I/O schedulers to CFQ
#   Distribute I/O requests to VMs fairly
#   Setting on NVMe might fail - ignore it
echo "Setting I/O schedulers to CFQ"
find /sys/devices -name scheduler | grep -v virtual | while read file; do echo cfq > $file 2>/dev/null; done
# - Set readahead to 128 kB
#   Not meaningful to non-rotational storage, set to minimum to minimize memory thrashing
echo "Setting readahead buffer to minimum (128kB)"
find /sys/devices -name read_ahead_kb | grep -v virtual | while read file; do echo 128 > $file; done
