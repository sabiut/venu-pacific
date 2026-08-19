# config/

Live-build configuration for the ISO.

Note what is *not* here: Venu Pacific's own apps, branding, translations and
settings. Those are built as `.deb` packages by `scripts/build-debs.sh` and
installed from `packages.chroot/`, so that dpkg owns them and an installed
machine can upgrade them through `apt` — see
[docs/updates.md](../docs/updates.md). `includes.chroot/` now holds only what
is meaningful in the live session alone.

The tree was originally generated with:

```sh
sudo apt install live-build
cd config/
lb config \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer live
```

That generates the standard live-build tree (`package-lists/`, `includes.chroot/`,
`hooks/normal/`, `bootloaders/`, etc.). Customizations live in:

- `package-lists/venu-pacific.list.chroot` — the Debian package set, plus
  `venu-pacific-desktop` (our metapackage, resolved from `packages.chroot/`)
- `packages.chroot/` — the `.deb` files `scripts/build-debs.sh` produces.
  live-build turns this directory into a local apt repository, so the
  metapackage above installs with real dependency resolution.
- `includes.chroot/` — live-session-only files. Just the Calamares menu
  entry: anything an installed machine keeps belongs in a package instead,
  since files copied in here are owned by nothing and can never be upgraded.
- `hooks/normal/` — build-time steps that cannot be packages: fetching the
  Kiwix ZIMs, building llama.cpp and its model, Kolibri, the xfdesktop4 fix,
  and edits to files other packages own (Calamares' `settings.conf`,
  LightDM's greeter config).

Do not commit `chroot/`, `binary/`, or `cache/` — see `.gitignore` at the repo root.
