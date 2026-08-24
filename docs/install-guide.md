# Installing Venu Pacific

Prefer to watch first? The whole process, start to finish:

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; margin: 1em 0; border-radius: 6px;">
  <iframe src="https://www.youtube-nocookie.com/embed/K9iK1J_cpV0"
          style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"
          allow="encrypted-media; picture-in-picture; fullscreen"
          allowfullscreen
          title="Venu Pacific installation walkthrough"></iframe>
</div>

(Requires internet to play — the written steps below cover everything offline.)

## What you need

- A USB flash drive, **8GB or larger** (the ISO is ~4.7GB) — writing the ISO to it
  **erases everything already on it**
- A computer to write the ISO with (any OS works — the write step below uses `dd`, but a GUI
  tool like [Balena Etcher](https://www.balena.io/etcher/) or Rufus works just as well if you'd
  rather not use a terminal)
- The target machine you're installing Venu Pacific on

## 1. Get the ISO

Either download a released ISO (see [Download & verify](download.md)), or build one yourself
from source:

```sh
./scripts/build-debs.sh
cp dist/*.deb config/config/packages.chroot/
cd config
sudo lb clean
lb config
sudo lb build
```

The first two commands build Venu Pacific's own `.deb` packages and stage them where
live-build can find them. Everything Venu Pacific-specific — the apps, branding, translations
and settings — reaches the image as real packages, which is what lets an installed machine
receive updates through `apt` afterwards (see [Getting updates](updates.md)). You need
`build-essential debhelper gettext` installed, and the archive signing key must exist
(`./scripts/apt-repo/make-key.sh`, once).

If you can't install `debhelper` (no sudo), use `./scripts/build-debs-in-docker.sh` instead of
the first line — it runs the same build in a Debian trixie container and hands the output back
to your own user.

Run `lb config` **with no arguments** — every setting (distribution, archive areas, the
"Venu Pacific" ISO volume label, no classic Debian Installer) is already committed in the
`config/` tree, and `lb config` regenerates from those saved values. Passing flags on the
command line overrides the committed configuration and is how stale branding once ended up
on a build.

This produces `config/live-image-amd64.hybrid.iso` (~4.7GB — it includes the AI model and
the offline encyclopedias). Building needs root (for the chroot/debootstrap steps), downloads
several GB on the first run, and takes from under an hour to several hours depending on
connection and hardware — see
[CONTRIBUTING.md](https://github.com/sabiut/venu-pacific/blob/main/CONTRIBUTING.md) if you
want to help build these as part of a release process instead of one-off locally.

## 2. Write it to a USB drive

Find your drive first — **get this right, the next command erases the whole device**:

```sh
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
```

Look for your USB drive by its size and model (it'll show `TRAN` as `usb`). Then, as root:

```sh
umount /dev/sdX1   # unmount any partitions first, if auto-mounted
dd if=venu-pacific-26.08.2-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

(Use the filename of the ISO you actually have — a self-built one is named
`live-image-amd64.hybrid.iso`.)

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
Utilities
```

("Utilities" is just a hardware-detection tool, unrelated to installing — live-build ships it
on every image.)

## 4. Try it live first (recommended)

Select **Live system (amd64)** to boot straight into the desktop without touching the machine's
disk at all — nothing is installed or changed until you deliberately run the installer. This is
the best way to check your hardware works well (wifi, graphics, etc.) before committing to an
install. A first-run welcome window will walk through what's included.

If a machine has unusual graphics hardware and the regular option doesn't boot cleanly, try
**Live system (fail-safe mode)** instead, which disables some kernel mode-setting options.

## 5. Install to disk

When you're ready, boot into the live desktop (step 4) and launch **Install System** from the
applications menu (this is Calamares' own menu entry). It runs
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

> **Verified end-to-end**: the full flow above — Erase Disk, Users, Summary, Install, Finish —
> has been walked through in a QEMU/KVM VM, including confirming the resulting installed system
> reboots to a working login screen, logs in, and loads the desktop correctly. If you hit
> anything unexpected, please open an issue with what step failed and what hardware you're on.

## After installing

On first login, a welcome window shows once, covering what's included, with a language choice
of English, Bislama, or Fijian (Bislama has been reviewed by a fluent speaker; the Fijian
translation is new and still awaiting native review). Software updates are checked automatically
at a scheduled off-peak time and shown as a notification — nothing downloads without you
choosing to, in **Synaptic**, since bandwidth here is often capped or metered.
