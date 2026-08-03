#!/bin/bash
# MoET curriculum pack fetcher -- PERMISSION-GATED, see README.md.
#
# Modes:
#   enumerate                        list PDFs the site currently serves (no gate)
#   freeze  --i-have-written-permission   download all + pin sha256s -> manifest.lock
#   fetch   --i-have-written-permission   re-download, verify against manifest.lock
set -eu
cd "$(dirname "$0")"

BASE="https://moet.gov.vu/docs"
DIRS=(textbooks covid-updates ecce-school-packages)
DEST="${MOET_PACK_DEST:-$HOME/venu-pacific-moet-pack}"
LOCK="manifest.lock"
CURL="curl -sfL --retry 3 --retry-delay 5 -m 300"

mode="${1:-}"
flag="${2:-}"

require_permission() {
    if [ "$flag" != "--i-have-written-permission" ]; then
        cat >&2 << 'EOF'
REFUSING: these materials are (c) Ministry of Education and Training, all
rights reserved. Downloading-to-redistribute needs MoET's written yes first
(see README.md). Once you have it, re-run with --i-have-written-permission
and record the permission email as PERMISSION.md in this directory.
EOF
        exit 1
    fi
    if [ ! -f PERMISSION.md ]; then
        echo "NOTE: PERMISSION.md not found here yet -- record the written yes" >&2
        echo "      (from whom, date, scope) before this pack goes anywhere." >&2
    fi
}

list_dir() {
    # Apache directory listing -> PDF filenames, one per line. Short
    # timeout, single try: listings are tiny, and when gov.vu is down
    # (often) the answer should arrive in seconds, not minutes -- the
    # long-retry $CURL is for the actual file downloads only.
    curl -sfL -m 30 "$BASE/$1/" | grep -oiE 'href="[^"]+\.pdf"' | sed 's/^href="//i;s/"$//' \
        | grep -v '^/' | sort -u
}

case "$mode" in
enumerate)
    for d in "${DIRS[@]}"; do
        echo "=== $BASE/$d/ ==="
        list_dir "$d" || echo "(unreachable right now -- gov.vu sites are flaky, retry later)"
    done
    # Radio lessons (/docs/sounds/) deliberately not listed: dropped from
    # the permission request 2026-08-03 -- see README.md.
    ;;
freeze)
    require_permission
    mkdir -p "$DEST"
    : > "$LOCK.tmp"
    for d in "${DIRS[@]}"; do
        mkdir -p "$DEST/$d"
        list_dir "$d" | while IFS= read -r f; do
            out="$DEST/$d/$f"
            echo "fetching $d/$f" >&2
            $CURL "$BASE/$d/$f" -o "$out"
            printf '%s  %s/%s\n' "$(sha256sum "$out" | cut -d' ' -f1)" "$d" "$f" >> "$LOCK.tmp"
        done
    done
    mv "$LOCK.tmp" "$LOCK"
    echo "pinned $(wc -l < "$LOCK") files into $LOCK; content in $DEST"
    ;;
fetch)
    require_permission
    [ -f "$LOCK" ] || { echo "no $LOCK -- run freeze first" >&2; exit 1; }
    mkdir -p "$DEST"
    while IFS= read -r line; do
        hash="${line%%  *}"
        rel="${line#*  }"
        out="$DEST/$rel"
        mkdir -p "$(dirname "$out")"
        [ -f "$out" ] || { echo "fetching $rel" >&2; $CURL "$BASE/$rel" -o "$out"; }
        echo "$hash  $out" | sha256sum -c - >&2
    done < "$LOCK"
    echo "all files present and verified in $DEST"
    ;;
*)
    echo "usage: $0 enumerate | freeze --i-have-written-permission | fetch --i-have-written-permission" >&2
    exit 1
    ;;
esac
