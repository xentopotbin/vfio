#!/bin/bash
for dev in "$@"; do

#unbind existing driver (if any)
  if [ -e /sys/bus/pci/devices/$dev/driver ]; then
      echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
  fi

  #binds the device to to xhci_hcd
  echo $dev > /sys/bus/pci/drivers/xhci_hcd/bind

done
