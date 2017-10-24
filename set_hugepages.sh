#!/bin/bash

if ! grep -q 'default_hugepagesz=1G' /proc/cmdline; then
  echo "Default hugepagesz not set to 1G!" 1>&2
  exit 1
fi

COUNT=$(virsh list --all --uuid | grep '\-' | wc -l)
TOTAL=$(($(virsh domstats --balloon | grep 'balloon.maximum=' | tr '=' ' ' | awk '{print $2}' | tr '\n' '+')0))

echo "Total RAM size required by VMs $TOTAL"

if (($TOTAL % 1048576)); then
  # Hugepage is set to 1G, $TOTAL should be divisible to 1G
  # but it's not a critical error
  echo "Total RAM size $TOTAL is not divisible by 1048576" 1>&2
  # Leave a buffer room for allocation to not fail
  TOTAL=$((($TOTAL / 1048576 + 1) * 1048576))
  echo "Rounding up to $TOTAL" 1>&2
fi

TLB=$(($TOTAL / 1048576))
echo "Reserving $TLB hugepages ($TLB GB)"
echo $TLB > /proc/sys/vm/nr_hugepages
