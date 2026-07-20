#!/bin/bash
# Copies the translation catalogs from locales/ into config/config/includes.chroot
# so live-build ships them into the image. Hooks run inside the chroot and
# can't read files from outside it, so this has to happen before `lb build`
# — see docs/install-guide.md and 0140-pacific-linux-locales.hook.chroot,
# which compiles these .po files into .mo at build time.
set -eu
cd "$(dirname "$0")/.."

DEST_ROOT="config/config/includes.chroot/usr/share/pacific-linux/locales"
rm -rf "$DEST_ROOT"

for po in locales/*/pacific-linux.po; do
    [ -f "$po" ] || continue
    lang="$(basename "$(dirname "$po")")"
    mkdir -p "$DEST_ROOT/$lang"
    cp "$po" "$DEST_ROOT/$lang/pacific-linux.po"
done

echo "Locale catalogs synced into $DEST_ROOT"
