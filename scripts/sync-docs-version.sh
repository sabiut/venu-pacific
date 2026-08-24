#!/bin/bash
# Rewrites the release version in the published docs to match
# debian/changelog, which is the single place a version is defined.
#
# This exists because the two drifted and nobody noticed: the site advertised
# venu-pacific-26.08-amd64.iso while the packages had moved to 26.08.2, so
# the download filename and the checksum command on the page would both have
# been wrong the moment an image was actually uploaded. scripts/lint.sh fails
# if they disagree, and this is the one command that fixes it.
#
# Only the user-facing pages are touched. The maintainer docs (releasing.md,
# release-test-checklist.md) quote specific past versions as worked examples
# and history -- rewriting those would falsify the record.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(dpkg-parsechangelog -SVersion)"
PAGES=(docs/download.md docs/install-guide.md docs/index.md docs/updates.md)

# Anchored on the contexts a version actually appears in, NOT on the shape of
# a version number. A bare "YY.MM(.P)" pattern looks safe and is not: it also
# matches the 56.25% padding that sets the aspect ratio of the video embed in
# install-guide.md, and silently rewriting that to "26.08.2%" breaks the page
# in a way no version check would ever flag.
V='[0-9]{2}\.[0-9]{2}(\.[0-9]+)?'

changed=0
for page in "${PAGES[@]}"; do
    [ -f "$page" ] || continue
    before="$(cat "$page")"
    after="$(printf '%s' "$before" \
        | sed -E "s/venu-pacific-$V-amd64/venu-pacific-$VERSION-amd64/g" \
        | sed -E "s/Venu Pacific $V/Venu Pacific $VERSION/g" \
        | sed -E "s/release \($V\)/release ($VERSION)/g")"
    if [ "$before" != "$after" ]; then
        printf '%s\n' "$after" > "$page"
        echo "  updated $page"
        changed=1
    fi
done

if [ "$changed" -eq 0 ]; then
    echo "Docs already at $VERSION."
else
    echo "Docs synced to $VERSION."
fi
