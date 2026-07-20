# branding/

Visual identity for Pacific Linux — a wayfinding star compass crossed with
wave-swell lines (echoing Marshallese stick charts), in a deep-ocean palette.
Chosen deliberately over the palm-tree/sunset cliché.

- `logo/` — `mark.svg` (the star mark, transparent), `icon-square.svg` (badge
  variant with an ink circular backing, for app-icon contexts), `lockup.svg`
  (mark + wordmark, for docs), plus rasterized PNG exports of each.
- `wallpapers/` — `pacific-ocean.{svg,png}`, 1920x1080, the same motif as a
  full desktop background: scattered wayfinding stars, the mark glowing
  bottom-right, a faint horizon swell line. Calm in the top-left where XFCE
  places desktop icons.
- `plymouth/pacific-linux/` — a Plymouth `script`-plugin boot theme: the
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

- `config/config/includes.chroot/usr/share/backgrounds/pacific-linux/` —
  wallpaper
- `config/config/includes.chroot/usr/share/plymouth/themes/pacific-linux/` —
  boot theme
- `config/config/includes.chroot/usr/share/pixmaps/pacific-linux.png` — app
  icon / about-dialog badge
- `config/config/hooks/normal/0100-pacific-linux-plymouth.hook.chroot` —
  activates the Plymouth theme and rebuilds the initramfs at build time
- `config/config/includes.chroot/etc/xdg/autostart/pacific-linux-set-defaults.desktop`
  + `.../usr/local/bin/pacific-linux-set-defaults` — sets the default
  wallpaper on first XFCE login. Done this way (not baked into a config
  file) because the per-monitor xfconf property namespace isn't known until
  xfdesktop has actually started and created it.

## Verified by actually booting the ISO (QEMU/KVM)

- **Plymouth boot theme** — confirmed working: background, centered mark,
  progress bar all render correctly during boot.
- **Boot menu / installer branding** — confirmed correct (Debian's isolinux
  menu shows the right build metadata; base XFCE desktop boots fine).
- **Desktop wallpaper — confirmed NOT working, root cause still open.** The
  first-login script does run (marker file created at boot time) and does
  correctly write `image-path`, `last-image`, and `image-show=true` in
  xfconf for every monitor found (verified directly with `xfconf-query`,
  values are exactly right). But the rendered XFCE desktop never picks up
  the change — not via the script, not via `xfdesktop --reload`, not via
  fully killing and restarting `xfdesktop`. The data layer is provably
  correct; something in xfdesktop's actual repaint isn't happening in this
  test environment (headless QEMU, std VGA, no real compositor session
  during manual testing). Needs a check on real hardware, or someone more
  familiar with this XFCE version's rendering internals, before trusting
  this to work for real users. Left the script fix in (it's strictly more
  correct than before) but do not consider this closed.
