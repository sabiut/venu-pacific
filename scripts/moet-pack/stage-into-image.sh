#!/bin/bash
# THE distribution gate for MoET materials. Copies the staged pack (from
# fetch.sh) into config/config/includes.chroot so the next ISO build ships
# it -- and refuses to do so unless the CDU's written permission is
# recorded as PERMISSION.md in this directory. Staging (fetch.sh --stage)
# is lawful preparation; THIS step is redistribution, and this is where
# the written yes is checked. Do not weaken this check.
set -eu
cd "$(dirname "$0")"

SRC="${MOET_PACK_DEST:-$HOME/venu-pacific-moet-pack}"
DEST="../../config/config/includes.chroot/usr/share/venu-pacific/moet"

if [ ! -f PERMISSION.md ]; then
    cat >&2 << 'EOF'
REFUSING to stage MoET materials into the image: PERMISSION.md not found.
These materials are (c) Ministry of Education and Training, all rights
reserved -- putting them on an ISO or USB is redistribution and needs the
CDU's written yes first. When their email arrives, save it here as
PERMISSION.md (from whom, date, exact scope granted), then re-run.
EOF
    exit 1
fi
if [ ! -f manifest.lock ]; then
    echo "No manifest.lock -- run ./fetch.sh freeze first (see README.md)." >&2
    exit 1
fi

# Verify every staged file against the pinned hashes before it ships.
while IFS= read -r line; do
    hash="${line%%  *}"
    rel="${line#*  }"
    echo "$hash  $SRC/$rel" | sha256sum -c - >/dev/null \
        || { echo "HASH MISMATCH: $rel -- refusing to stage" >&2; exit 1; }
done < manifest.lock

mkdir -p "$DEST"
cp PERMISSION.md "$DEST/PERMISSION.md"
rsync -a --delete "$SRC/" "$DEST/content/"
echo "Staged $(wc -l < manifest.lock) verified files into $DEST"
echo "Next: add the shelf/menu entry, sync, commit, rebuild."
