# branding/

Visual identity for Venu Pacific.

**The mark (2026-07-30, current)**: a twin-peaked volcano forming a V, its
slopes traced with circuit lines, a wave at its base and an eruption above,
inside a ring on deep navy — venu is the word for volcano on Ambrym, and this
is that identity drawn literally. Supplied by the project owner
(`venu-mark-source.png`, 1254px square); deployed everywhere as a
circle-cropped badge (`venu-mark-circle-{1024,512,256}.png`) because the navy
field is part of the design — the ring is an outline, so background removal
would hollow the emblem out, and the round badge matches the greeter's
circular avatar crop anyway.

- `logo/` — the volcano mark above (current), plus the earlier wayfinding-star
  compass set (`mark.svg`, `icon-square.svg`, `lockup.svg` + PNG exports),
  kept for the wordmark lockup and history. The compass was always a
  placeholder; the volcano mark replaces it in every deployed location.
- `wallpapers/` — `pacific-ocean.{svg,png}`, 1920x1080, the same motif as a
  full desktop background: scattered wayfinding stars, the mark glowing
  bottom-right, a faint horizon swell line. Calm in the top-left where XFCE
  places desktop icons.
- `plymouth/venu-pacific/` — a Plymouth `script`-plugin boot theme: the
  wallpaper as background, the mark centered, and a simple progress bar.
  Written against patterns verified in Debian's own bundled theme
  (`/usr/share/plymouth/themes/spacefun`) rather than from memory, since a
  script error there fails silently at boot.

## Icon theme

Not building a custom icon set for v1 — that's a much larger effort than
Phase 1 branding calls for. Using **Papirus** (`papirus-icon-theme`, in the
package list already): actively maintained, XFCE-friendly, and light enough
for the old hardware this project targets.

## Wired into the build

- `config/config/includes.chroot/usr/share/backgrounds/venu-pacific/` —
  wallpaper
- `config/config/includes.chroot/usr/share/plymouth/themes/venu-pacific/` —
  boot theme
- `config/config/includes.chroot/usr/share/pixmaps/venu-pacific.png` — app
  icon / about-dialog badge
- `config/config/hooks/normal/0100-venu-pacific-plymouth.hook.chroot` —
  activates the Plymouth theme and rebuilds the initramfs at build time
- `config/config/includes.chroot/etc/xdg/autostart/venu-pacific-set-defaults.desktop`
  + `.../usr/local/bin/venu-pacific-set-defaults` — sets the default
  wallpaper on first XFCE login (belt-and-suspenders; see below for the
  actual fix).
- `config/config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml`
  — pre-seeds the backdrop xfconf properties before xfdesktop ever
  constructs itself for a fresh user.
- `config/config/hooks/normal/0120-venu-pacific-xfdesktop-fix.hook.chroot`
  — the actual fix (see below).

## The xfdesktop wallpaper bug (resolved)

trixie ships `xfdesktop4` 4.20.1-1, which has a confirmed bug: it never
renders a configured custom wallpaper. Extensively verified before
concluding this — xfconf properties (`image-path`, `last-image`,
`image-show`, `image-style`, `single-workspace-mode`,
`single-workspace-number`, pre-seeded before construction via `/etc/skel`)
were all confirmed correct via direct `xfconf-query`, yet the image was
**never even opened** (confirmed with `--enable-debug` +
`G_MESSAGES_DEBUG=all`: zero `GdkPixbuf` calls for our file, though icon
loads show up fine in the same trace). Reproduced identically on real
hardware (Blackview mini PC), ruling out a QEMU-only artifact.

**Fix**: `0120-venu-pacific-xfdesktop-fix.hook.chroot` downloads
`xfdesktop4` and `xfdesktop4-data` 4.20.2-2 directly from the Debian pool
(sid) by URL and installs them with `apt-get install ./*.deb` after the
main package set is in — 4.20.2 doesn't have the bug. Every other library
`xfdesktop4` 4.20.2 depends on is already satisfied by trixie's own
package versions (verified against the real `.deb` control file);
`xfdesktop4-data` has no dependencies of its own.

This is a direct download + `dpkg`-level install, deliberately **not** an
apt source pin — an earlier attempt to add sid as a low-priority pinned
archive broke live-build's own `installer_debian-installer` script (it
checks package availability via `apt-cache show | wc -l -eq 1`, which
breaks the moment any second suite has a same-named package, regardless
of pin priority). The direct-download approach also means nothing
sid-related ever ships in the final image.

## Verified by actually booting the ISO (QEMU/KVM + real hardware)

- **Plymouth boot theme** — confirmed working: background, centered mark,
  progress bar all render correctly during boot.
- **Boot menu / installer branding** — confirmed correct (Debian's isolinux
  menu shows the right build metadata; base XFCE desktop boots fine).
- **Desktop wallpaper — confirmed working** after the xfdesktop4 4.20.2
  fix above. Verified on a fresh boot with zero manual intervention: the
  ocean wallpaper renders correctly on first login.
