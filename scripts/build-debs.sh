#!/bin/bash
# Builds every Venu Pacific .deb into dist/.
#
# These are the packages an installed machine upgrades through apt, and the
# same files live-build installs into the ISO (see
# config/config/packages.chroot). Building them is the first step of both a
# release and a local image build.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO_ROOT="$PWD"
DIST_DIR="$REPO_ROOT/dist"

missing=()
for tool in dpkg-buildpackage dh msgfmt; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing build tools: ${missing[*]}" >&2
    echo >&2
    echo "Install them with:" >&2
    echo "    sudo apt install build-essential debhelper devscripts gettext" >&2
    exit 1
fi

KEY=scripts/apt-repo/keys/venu-pacific-archive-keyring.gpg
if [ ! -f "$KEY" ]; then
    echo "Missing $KEY" >&2
    echo >&2
    echo "The keyring package needs the archive's public key. Generate it once with:" >&2
    echo "    ./scripts/apt-repo/make-key.sh" >&2
    exit 1
fi

VERSION="$(dpkg-parsechangelog -SVersion)"
echo "== Building venu-pacific $VERSION =="

# -b: binary only. There is no upstream tarball to build a source package
# against -- this repository is the source.
# -us -uc: the .changes/.dsc signature is not what protects users here; the
# archive's InRelease signature is (see scripts/apt-repo/publish.sh).
dpkg-buildpackage -b -us -uc

# dpkg-buildpackage writes its output to the PARENT of the source tree,
# which is outside the repository. Collect it back into dist/ so everything
# a release needs is in one predictable place.
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/*.deb "$DIST_DIR"/*.buildinfo "$DIST_DIR"/*.changes
mv -f ../venu-pacific*_"$VERSION"_*.deb "$DIST_DIR"/ 2>/dev/null || true
mv -f ../venu-pacific_"$VERSION"_*.buildinfo "$DIST_DIR"/ 2>/dev/null || true
mv -f ../venu-pacific_"$VERSION"_*.changes "$DIST_DIR"/ 2>/dev/null || true

# A package whose maintainer script silently failed to be included installs
# cleanly and configures nothing, which is invisible until someone notices
# the desktop still has Debian's wallpaper three releases later.
echo
echo "== Verifying maintainer scripts made it into the packages =="
missing=0
for src in debian/venu-pacific-*.postinst debian/venu-pacific-*.preinst \
           debian/venu-pacific-*.prerm debian/venu-pacific-*.postrm; do
    [ -e "$src" ] || continue
    base="$(basename "$src")"
    pkg="${base%.*}"
    kind="${base##*.}"
    deb="$(ls "$DIST_DIR/${pkg}"_*.deb 2>/dev/null | head -1)"
    [ -n "$deb" ] || continue
    if dpkg-deb --ctrl-tarfile "$deb" | tar -t 2>/dev/null | grep -q "^\./$kind\$"; then
        echo "  ok   $pkg carries $kind"
    else
        echo "  FAIL $pkg is MISSING $kind" >&2
        missing=1
    fi
done
if [ "$missing" -ne 0 ]; then
    echo "Refusing to ship packages that configure nothing." >&2
    exit 1
fi

echo
echo "== Built into dist/ =="
ls -1sh "$DIST_DIR"/*.deb
