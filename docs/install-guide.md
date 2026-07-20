# Installing Pacific Linux

## What you need

- A USB flash drive, 4GB or larger — writing the ISO to it **erases everything already on it**
- A computer to write the ISO with (any OS works — the write step below uses `dd`, but a GUI
  tool like [Balena Etcher](https://www.balena.io/etcher/) or Rufus works just as well if you'd
  rather not use a terminal)
- The target machine you're installing Pacific Linux on

## 1. Get the ISO

Either download a released ISO, or build one yourself from source:

```sh
./scripts/sync-locales.sh
cd config
lb config \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer live
sudo lb build
```

This produces `config/live-image-amd64.hybrid.iso` (~2.9GB). Building from source needs root
(for the chroot/debootstrap steps) and takes anywhere from 15 minutes to over an hour depending
on your connection — see [CONTRIBUTING.md](../CONTRIBUTING.md) if you want to help build these
as part of a release process instead of one-off locally.

## 2. Write it to a USB drive

Find your drive first — **get this right, the next command erases the whole device**:

```sh
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
```

Look for your USB drive by its size and model (it'll show `TRAN` as `usb`). Then, as root:

```sh
umount /dev/sdX1   # unmount any partitions first, if auto-mounted
dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

Replace `/dev/sdX` with your actual drive (e.g. `/dev/sda`) — **not** a partition like
`/dev/sdX1`. This takes several minutes depending on the drive's write speed.

## 3. Boot from the USB drive

Plug the drive into the target machine, power it on, and hit the boot-menu key during startup —
commonly `F12`, `F2`, `Esc`, or `Del`, shown briefly on the manufacturer's splash screen. Pick the
USB drive from the list.

**If it doesn't show up as a boot option**, the machine's UEFI firmware may have Secure Boot
enabled, which blocks unsigned custom ISOs like this one. Enter the firmware setup (same
boot-menu key, or a dedicated "BIOS/UEFI Setup" option) and disable Secure Boot under
Boot/Security settings.

You'll land on a boot menu with these options:

```
Live system (amd64)
Live system (amd64 fail-safe mode)
Start installer
Start installer with speech synthesis
Advanced install options
Utilities
```

## 4. Try it live first (recommended)

Select **Live system (amd64)** to boot straight into the desktop without touching the machine's
disk at all — nothing is installed or changed until you deliberately run the installer. This is
the best way to check your hardware works well (wifi, graphics, etc.) before committing to an
install. A first-run welcome window will walk through what's included.

If a machine has unusual graphics hardware and the regular option doesn't boot cleanly, try
**Live system (fail-safe mode)** instead, which disables some kernel mode-setting options.

## 5. Install to disk

When you're ready, either select **Start installer** directly from the boot menu, or launch the
installer from the applications menu once inside the live desktop. This runs
[Calamares](https://calamares.io/), which walks through the standard steps:

1. **Welcome** — language for the installer itself
2. **Location** — timezone
3. **Keyboard** — layout
4. **Partitions** — erase the whole disk (simplest, for a dedicated machine), or partition
   manually (for dual-boot or existing partitions you want to keep)
5. **Users** — your name, username, password, and machine name
6. **Summary** — review before committing
7. **Install** — copies the system to disk; takes several minutes
8. **Finish** — reboot into your installed system

> **Not yet independently verified in this repo**: the live boot experience (menu, live session,
> desktop, welcome app) has been tested extensively on both a VM and real hardware. The Calamares
> install-to-disk flow itself — actually completing all the steps above and confirming the
> resulting installed system boots — has not yet been walked through end-to-end here. If you hit
> anything unexpected during installation, please open an issue with what step failed and what
> hardware you're on.

## After installing

On first login, a welcome window shows once, covering what's included and the current language
status (English is the only fully working option in this release; Bislama support is in
progress). Software updates are checked automatically at a scheduled off-peak time and shown as a
notification — nothing downloads without you choosing to, in **Synaptic**, since bandwidth here is
often capped or metered.
