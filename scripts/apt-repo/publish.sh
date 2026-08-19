#!/bin/bash
# Builds the signed APT archive from dist/*.deb and uploads it to Cloudflare
# R2, where https://download.venupacific.org/apt serves it.
#
# Usage:
#   ./scripts/build-debs.sh          # produces dist/*.deb
#   ./scripts/apt-repo/publish.sh    # signs and uploads them
#
# Built with apt-ftparchive and gpg rather than reprepro or aptly. Those are
# the conventional tools, but both need installing as root, and this project
# is maintained from an account without sudo. apt-ftparchive is what reprepro
# wraps anyway, it ships in apt-utils on every Debian system, and doing the
# signing here with plain gpg keeps the archive key on the maintainer's own
# machine instead of inside whatever tool or container builds the indices.
#
# Environment:
#   R2_ACCOUNT_ID   Cloudflare account id (R2 dashboard sidebar). Required
#                   unless R2_ENDPOINT_URL is set directly. Normally read
#                   from scripts/apt-repo/r2.env -- see r2.env.example.
#   R2_BUCKET       defaults to venu-pacific-releases
#   AWS_PROFILE     defaults to r2 -- the named profile from
#                   docs/releasing.md, kept separate from real AWS creds
#   DRY_RUN=1       build and sign the archive but upload nothing
#   PRUNE_POOL=1    also delete pool files the new indices no longer
#                   reference (see the upload section for why this is off
#                   by default)
set -euo pipefail
cd "$(dirname "$0")/../.."

REPO_ROOT="$PWD"
DIST_DIR="$REPO_ROOT/dist"
WORK_DIR="$REPO_ROOT/dist/apt"
KEYID_FILE="scripts/apt-repo/keys/KEYID"
RELEASE_CONF="$REPO_ROOT/scripts/apt-repo/conf/release.conf"

SUITE="trixie"
COMPONENT="main"
ARCH="amd64"

# Local settings, if present. Read BEFORE the defaults below so the
# environment still wins: `R2_BUCKET=other ./publish.sh` overrides the file.
# This exists because the account id is otherwise nowhere on disk -- it is
# not in the repo (deliberately) and not in ~/.aws, so it ends up being
# recovered from shell history at exactly the wrong moment.
R2_ENV="$REPO_ROOT/scripts/apt-repo/r2.env"
if [ -f "$R2_ENV" ]; then
    # shellcheck disable=SC1090
    . "$R2_ENV"
fi

R2_BUCKET="${R2_BUCKET:-venu-pacific-releases}"
AWS_PROFILE="${AWS_PROFILE:-r2}"
DRY_RUN="${DRY_RUN:-0}"
PRUNE_POOL="${PRUNE_POOL:-0}"

for tool in apt-ftparchive gpg; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "$tool is not installed." >&2
        echo "apt-ftparchive comes from apt-utils, gpg from gnupg -- both are" >&2
        echo "normally already present on a Debian system." >&2
        exit 1
    }
done

if [ ! -f "$KEYID_FILE" ]; then
    echo "Missing $KEYID_FILE -- run ./scripts/apt-repo/make-key.sh first." >&2
    exit 1
fi
SIGNWITH="$(cat "$KEYID_FILE")"

if ! gpg --list-secret-keys "$SIGNWITH" >/dev/null 2>&1; then
    echo "The archive signing key $SIGNWITH is not in this machine's gpg keyring." >&2
    echo "Import the private key before publishing:" >&2
    echo "    gpg --import venu-pacific-archive.key" >&2
    exit 1
fi

shopt -s nullglob
debs=("$DIST_DIR"/*.deb)
if [ ${#debs[@]} -eq 0 ]; then
    echo "No .deb files in dist/ -- run ./scripts/build-debs.sh first." >&2
    exit 1
fi

# The archive tree is derived state, rebuilt from the .debs on every run.
# That is both faster than reasoning about drift and immune to a
# half-finished previous run.
rm -rf "$WORK_DIR"
POOL_REL="pool/$COMPONENT/v/venu-pacific"
BINDIR_REL="dists/$SUITE/$COMPONENT/binary-$ARCH"
mkdir -p "$WORK_DIR/$POOL_REL" "$WORK_DIR/$BINDIR_REL"
cp "${debs[@]}" "$WORK_DIR/$POOL_REL/"

echo "== Indexing $(ls -1 "$WORK_DIR/$POOL_REL" | wc -l) packages =="
# Run from the archive root so the Filename: fields come out relative to it,
# which is exactly how apt resolves them against the URI in the sources file.
cd "$WORK_DIR"
apt-ftparchive packages pool > "$BINDIR_REL/Packages"
gzip -9 -c "$BINDIR_REL/Packages" > "$BINDIR_REL/Packages.gz"

# The per-component Release stub. apt cross-checks these fields against the
# suite it thinks it is fetching, which is what stops a repository from
# quietly serving one component's index in another's place.
cat > "$BINDIR_REL/Release" <<EOF
Archive: $SUITE
Component: $COMPONENT
Origin: Venu Pacific
Label: Venu Pacific
Architecture: $ARCH
EOF

# Written to a temp file OUTSIDE the tree and moved in, not redirected
# straight to its final path. Shell redirection creates the target before
# apt-ftparchive runs, so the scan finds a Release file already sitting in
# the directory it is indexing and lists a hash for it -- a self-reference
# describing a file that no longer has that size the moment writing
# finishes. apt ignores the bogus entry, but publishing metadata that is
# knowably wrong is not worth the one saved line.
release_tmp="$(mktemp)"
apt-ftparchive -c "$RELEASE_CONF" release "dists/$SUITE" > "$release_tmp"
mv "$release_tmp" "dists/$SUITE/Release"
chmod 0644 "dists/$SUITE/Release"

echo
echo "== Signing =="
# Two signatures, because apt accepts either and old clients only know the
# second: InRelease is the inline-signed Release (what modern apt fetches
# first), Release.gpg is the detached signature beside the plain Release.
rm -f "dists/$SUITE/InRelease" "dists/$SUITE/Release.gpg"
gpg --batch --yes --local-user "$SIGNWITH" \
    --clearsign -o "dists/$SUITE/InRelease" "dists/$SUITE/Release"
gpg --batch --yes --local-user "$SIGNWITH" \
    --detach-sign --armor -o "dists/$SUITE/Release.gpg" "dists/$SUITE/Release"

# Verify against the exact public key that ships in the keyring package, not
# against whatever happens to be in the maintainer's personal keyring. This
# is the check that would catch signing with the wrong key -- which looks
# completely fine here and fails on every user's machine.
KEYRING="$REPO_ROOT/scripts/apt-repo/keys/venu-pacific-archive-keyring.gpg"
gpg --no-default-keyring --keyring "$KEYRING" \
    --verify "dists/$SUITE/InRelease" 2>&1 | sed 's/^/  /'
gpg --no-default-keyring --keyring "$KEYRING" \
    --verify "dists/$SUITE/Release.gpg" "dists/$SUITE/Release" >/dev/null 2>&1 \
    || { echo "Release.gpg failed verification -- refusing to publish." >&2; exit 1; }

cd "$REPO_ROOT"

echo
echo "== Archive contents =="
awk '/^Package:/ {p=$2} /^Version:/ {print "  " p " " $2}' \
    "$WORK_DIR/$BINDIR_REL/Packages"

if [ "$DRY_RUN" = "1" ]; then
    echo
    echo "DRY_RUN=1 -- archive built and signed at $WORK_DIR, nothing uploaded."
    echo
    echo "Inspect it with:"
    echo "  head -20 $WORK_DIR/dists/$SUITE/InRelease"
    exit 0
fi

command -v aws >/dev/null 2>&1 || {
    echo "aws CLI is not installed -- see docs/releasing.md §1a." >&2
    exit 1
}

ENDPOINT="${R2_ENDPOINT_URL:-}"
if [ -z "$ENDPOINT" ]; then
    if [ -z "${R2_ACCOUNT_ID:-}" ]; then
        echo "R2_ACCOUNT_ID is not set." >&2
        echo >&2
        echo "Save it once and it is picked up automatically from then on:" >&2
        echo "    cp scripts/apt-repo/r2.env.example scripts/apt-repo/r2.env" >&2
        echo "    \$EDITOR scripts/apt-repo/r2.env" >&2
        echo >&2
        echo "The value is the host part of the bucket's S3 API endpoint:" >&2
        echo "  Cloudflare -> R2 -> venu-pacific-releases -> Settings -> S3 API" >&2
        exit 1
    fi
    ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
fi

s3() { aws s3 "$@" --profile "$AWS_PROFILE" --endpoint-url "$ENDPOINT"; }

# Order matters, and it is the one thing an apt archive upload can get wrong
# in a way users see. The pool goes up FIRST: dists/ is the index that names
# and hashes every file in pool/, so publishing the index before the packages
# leaves anyone who runs `apt update` in that window with a repository
# advertising files that 404.
echo
echo "== Uploading pool/ =="
# Additive, not --delete. Deleting superseded .debs before the new index is
# live would break exactly the users whose apt still has the old index
# cached. They are a few hundred KB each; reclaim the space deliberately
# with PRUNE_POOL=1 once the new metadata has propagated.
s3 sync "$WORK_DIR/pool/" "s3://$R2_BUCKET/apt/pool/"

# Metadata second, and with a short cache lifetime. download.venupacific.org
# is served through Cloudflare's cache; without this, a cached InRelease can
# keep pointing at the previous release's hashes long enough for `apt update`
# to fail with a hash-mismatch error that looks like corruption.
echo
echo "== Uploading dists/ =="
s3 sync "$WORK_DIR/dists/" "s3://$R2_BUCKET/apt/dists/" \
    --delete \
    --cache-control "public, max-age=300"

if [ "$PRUNE_POOL" = "1" ]; then
    echo
    echo "== Pruning pool/ of files the new indices no longer reference =="
    s3 sync "$WORK_DIR/pool/" "s3://$R2_BUCKET/apt/pool/" --delete
fi

echo
echo "== Published =="
echo "  https://download.venupacific.org/apt"
echo
echo "Verify from a clean machine, exactly as a user's apt would:"
echo "  curl -fsS https://download.venupacific.org/apt/dists/$SUITE/InRelease | head -20"
