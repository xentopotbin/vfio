# VFIO scripts

Scripts I use for starting my Windows 10 VM with VFIO / PCI passthrough. It's pretty hacky and poorly explained, but maybe it'll be helpful to someone. I've been using this setup (with very minor tweaks along the way) for almost two years and am very happy with it. Featuring: USB controller rebinding, Synergy with NAT, absolutely no libvirt whatsoever.

Hardware:
- MOBO: ASUS z170 Pro Gaming Aura
- CPU: Intel Skylake 6700k
- Guest GPU: Radeon RX 480
- Host graphics: Integrated

OS:
- Host: Arch Linux
- Guest: Windows 10 Education

## Notes
I never managed to completely eliminate audio crackling, so I cheated and got a USB audio adapter. It works great.

Unfortunately my mobo doesn't have nice USB IOMMU groupings, so the mouse, keyboard, USB mic, and USB audio adapter are plugged into a [USB expansion card](https://www.amazon.com/Mailiya-Expansion-Superspeed-Connector-Desktops/dp/B01G86538S). I just rebind the whole thing to vfio-pci and pass it through as a sort of fake kvm switch.

#### Issues
- GPU performance suspected to degrade after VM reboot - need to confirm this is happening
- xrandr glitch (pink bars in top L corner) sometimes prevents VM from taking control of monitor, happens maybe 10% of the time?
- If VM crashes / shuts down abruptly, often won't recognize GPU again until host is rebooted

#### To do
- [ ] Wait longer/smarter before starting synergy so it doesn't capture mouse & kb too early
- [ ] Pin iothread as well as CPU threads?
- [ ] Clean out cores with cgroups before pinning?
- [ ] Benchmark comparisons for above
- [ ] qemu command line vs libvirt benchmarking

## Requirements

* [OVMF builds](https://www.kraxel.org/repos/)
* [qmp-shell](https://github.com/qemu/qemu/blob/master/scripts/qmp/qmp-shell) - needed for CPU pinning
* [Synergy](https://symless.com/synergy) - mouse & keyboard sharing

## Acknowledgments

* Mark Nipper - [CPU pinning](https://www.redhat.com/archives/vfio-users/2015-August/msg00100.html)

#### Useful guides

* [Arch wiki on PCI passthrough](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)
* [Alex Williamson's guide](https://vfio.blogspot.com/2015/05/vfio-gpu-how-to-series-part-1-hardware.html)
* [DominicM's guide](http://dominicm.com/gpu-passthrough-qemu-arch-linux/)
* [Bufferoverflow.io guide](https://bufferoverflow.io/gpu-passthrough/) - includes setup without libvirt
* [Setting MSI in windows](http://forums.guru3d.com/showthread.php?t=378044)
