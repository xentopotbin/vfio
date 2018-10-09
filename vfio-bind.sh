#!/bin/bash

modprobe vfio-pci

for dev in "$@"; do
	if [ -e /sys/bus/pci/drivers/vfio-pci/$dev ]; then
		continue
	fi
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        # Unbind the device from the current driver that is using
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
                echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        #Bind the device to the vfio-pci module
        echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id
done
