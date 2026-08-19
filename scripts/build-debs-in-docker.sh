#!/bin/bash
# Builds the .deb packages inside a Debian trixie container, for machines
# where debhelper cannot be installed.
#
# Building a Debian package needs debhelper, and installing debhelper needs
# root. This project is maintained from an account without sudo, so the
# packages are built in a container that has it. Publishing deliberately
# stays on the host: scripts/apt-repo/publish.sh needs only apt-ftparchive
# and gpg, both already present, which keeps the archive's private signing
# key out of the container entirely.
#
# The container also matches what users actually run -- these packages are
# built against Debian 13's debhelper and dpkg, not whatever the host has.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v docker >/dev/null 2>&1 || {
    echo "docker is not available." >&2
    echo "With sudo, the direct route is:" >&2
    echo "    sudo apt install build-essential debhelper gettext" >&2
    echo "    ./scripts/build-debs.sh" >&2
    exit 1
}

IMAGE="${BUILD_IMAGE:-debian:trixie}"

echo "== Building in $IMAGE =="
# The uid/gid are passed in so the build output can be handed back to the
# invoking user at the end. Without that the container leaves a root-owned
# dist/ behind, and the very next step -- publish.sh, running as you --
# cannot write into it.
docker run --rm \
    -v "$PWD":/src \
    -e DEBIAN_FRONTEND=noninteractive \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    "$IMAGE" \
    bash -c '
        set -e
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends \
            build-essential debhelper gettext >/dev/null
        cd /src
        ./scripts/build-debs.sh
        chown -R "$HOST_UID:$HOST_GID" dist debian
    '

echo
echo "Next: sign and publish from this machine (the key never enters the container)"
echo "    DRY_RUN=1 ./scripts/apt-repo/publish.sh"
