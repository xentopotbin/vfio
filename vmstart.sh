#!/bin/bash

# important files
ovmf_firmware=/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd
uefi_vars=/home/user/VM/my_vars.fd
vm_hd=/home/user/VM/vm_hd.raw

# pci locations
gpu_id=01:00.0
gpu_audio_id=01:00.1
usb_id=03:00.0

#ip addresses (needed for NAT and synergy)
host_ip=10.13.13.1
guest_ip=10.13.13.2
network_interface=enp0s31f6

#===============================================================================

# turn off the display that the VM will use
# this display is wired to both the host GPU and passthrough GPU
xrandr --output HDMI-1 --off

# ramp up CPU frequency
echo "Going fast..."
for i in {0..7}; do
       echo performance > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
done

# rebind USB controller from xcci-hcd to vfio-pci
echo "Rebinding USB controller..."
vfio-bind 0000:${usb_id}

# start samba share, since it isn't enabled by default
echo "Starting Samba..."
systemctl start smbd
systemctl start nmbd

# start qemu
echo "Starting VM..."
taskset -ac 4-7 qemu-system-x86_64 \
  -qmp unix:/run/qmp-sock,server,nowait \
  -rtc base=localtime,clock=host,driftfix=none \
  -enable-kvm \
  -name Windows \
  -cpu host,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff \
  -smp sockets=1,cores=4,threads=1 \
  -m 16000 \
  -mem-path /dev/hugepages \
  -mem-prealloc \
  -vga none \
  -device vfio-pci,host=${gpu_id},multifunction=on \
  -device vfio-pci,host=${gpu_audio_id} \
  -device vfio-pci,host=${usb_id},multifunction=on  \
  -drive if=pflash,format=raw,readonly,file=${ovmf_firmware} \
  -drive if=pflash,format=raw,file=${uefi_vars} \
  -device virtio-scsi-pci,id=scsi \
  -drive file=${vm_hd},id=disk,format=raw,if=none, -device scsi-hd,drive=disk \
  -net nic,model=virtio -net tap,ifname=tap0,script=no,downscript=no &

sleep 5

# pin CPU threads to cores 4 - 7
# blatantly stolen from https://www.redhat.com/archives/vfio-users/2015-August/msg00100.html
cpuid=4
for threadpid in $(echo 'query-cpus' | ./qmp-shell /run/qmp-sock | grep '^(QEMU) {"return":' | sed -e 's/^(QEMU) //' | jq -r '.return[].thread_id'); do
        taskset -p -c ${cpuid} ${threadpid}
        ((cpuid+=1))
done

# enable IP forwarding
echo "Setting up internet..."
sysctl net.ipv4.ip_forward=1
# set IP address for tap adapter
ip addr add ${host_ip}/24 dev tap0
# enable NAT for both ethernet adapter and tunnel adapter (in case I'm using a VPN)
iptables -t nat -A POSTROUTING -o ${network_interface} -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tap0 -o ${network_interface} -j ACCEPT
iptables -A FORWARD -i tap0 -o tun0 -j ACCEPT

#start synergy client, listen for VM host
echo "Starting Synergy..."
synergyc ${guest_ip} &

wait

#===============================================================================
# set things back to normal when the VM shuts down

echo "Stopping VM..."

# give the VM's monitor back to the host
xrandr --output HDMI-1 --mode 1920x1080 --left-of HDMI-2

echo "Stopping Synergy..."
killall synergyc

echo "Rebinding USB controller..."
xhci-bind 0000:${usb_id}

echo "Stopping Samba..."
systemctl stop smbd
systemctl stop nmbd

# turn cpu back down to powersaving mode
for i in {0..7}; do
       echo powersave > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
done
