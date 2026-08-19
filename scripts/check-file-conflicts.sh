#!/bin/bash
# Fails if any path our packages ship is already owned by a Debian package.
#
# Two packages cannot own the same file. dpkg refuses the unpack outright --
# it does not pick a winner -- so a collision does not degrade the image, it
# stops the build dead. That is the correct behaviour, but until this script
# existed the only thing that noticed was `lb build`, twenty minutes into
# CI, with the message buried in twelve hundred lines of unpack chatter.
#
# It cost exactly that to find /etc/xdg/autostart/light-locker.desktop, where
# venu-pacific-settings was shipping its own copy of a light-locker file. That
# is now solved by not sharing the path at all -- light-locker's entry is
# diverted aside and ours ships under its own name -- so there is currently
# nothing on the expected list. The class of bug recurs every time a file is
# added to system/, so the check is worth having up front.
#
# Uses apt-file, which answers "who owns this path" from the archive's
# Contents index without installing the desktop stack. Skips with a clear
# message when apt-file or its index is unavailable, rather than failing --
# a check that cannot run is not the same as a check that passed, and it says
# which one happened.
set -uo pipefail
cd "$(dirname "$0")/.."

DIST_DIR="dist"

# Paths we knowingly take over, with the mechanism that makes it legal.
# A path listed here is expected to collide; anything else is a bug.
is_expected() {
    case "$1" in
        # Nothing yet. If a package ever genuinely must own a path Debian
        # already owns, take it over with a dpkg diversion (see
        # debian/venu-pacific-settings.preinst for the pattern) and list the
        # path here with the reason -- but prefer shipping under a name of
        # our own, which avoids the contested-conffile problem entirely.
        *) return 1 ;;
    esac
}

shopt -s nullglob
debs=("$DIST_DIR"/*.deb)
if [ ${#debs[@]} -eq 0 ]; then
    echo "No .deb files in $DIST_DIR -- run ./scripts/build-debs.sh first." >&2
    exit 1
fi

if ! command -v apt-file >/dev/null 2>&1; then
    echo "SKIP: apt-file is not installed, cannot check file ownership."
    echo "      CI runs this check; install apt-file to run it locally."
    exit 0
fi
if ! apt-file search -x '^/bin/sh$' >/dev/null 2>&1; then
    echo "SKIP: apt-file has no Contents index (run 'apt-file update')."
    exit 0
fi

fail=0
for d in "${debs[@]}"; do
    pkg="$(dpkg-deb -f "$d" Package)"
    while read -r path; do
        [ -n "$path" ] || continue
        owners="$(apt-file search --fixed-string "$path" 2>/dev/null \
                  | awk -F: -v p="$path" '$2 ~ "^ *"p"$" {print $1}' \
                  | grep -vx "$pkg" | sort -u)"
        [ -n "$owners" ] || continue

        if is_expected "$path"; then
            echo "  ok (diverted): $path -- also in $(echo "$owners" | paste -sd' ')"
        else
            echo "FAIL: $pkg ships $path, which is also in: $(echo "$owners" | paste -sd' ')"
            echo "      dpkg will refuse the unpack. Either stop shipping this path,"
            echo "      or take it over deliberately with a dpkg diversion (see"
            echo "      debian/venu-pacific-settings.preinst) and list it in is_expected()."
            fail=1
        fi
    done < <(dpkg-deb -c "$d" | awk '$1 !~ /^d/ {print $6}' | sed 's|^\./|/|')
done

if [ "$fail" -ne 0 ]; then
    echo
    echo "File-ownership check failed."
    exit 1
fi

echo "No unexpected file conflicts."
