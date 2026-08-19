#!/bin/bash
# Generates the OpenPGP key that signs the Venu Pacific package archive, and
# exports its public half into the keyring package.
#
# Run this ONCE, ever. The key is the project's identity to every installed
# machine: apt on a user's laptop trusts a package because this key signed
# the archive index it came from. Rotating it later means every existing
# installation stops accepting updates until the new keyring package is
# installed by hand -- which is exactly the situation an update channel
# exists to avoid.
#
# The private half never belongs in this repository. See the "Where the key
# lives" section of scripts/apt-repo/README.md.
set -euo pipefail
cd "$(dirname "$0")"

KEY_DIR="keys"
PUB_KEY="$KEY_DIR/venu-pacific-archive-keyring.gpg"
KEYID_FILE="$KEY_DIR/KEYID"

UID_NAME="Venu Pacific Archive Signing Key"
UID_EMAIL="${VENU_KEY_EMAIL:-archive@venupacific.org}"

if [ -f "$PUB_KEY" ]; then
    echo "$PUB_KEY already exists -- refusing to generate a second archive key."
    echo
    echo "If you genuinely need to rotate it, read the rotation section in"
    echo "scripts/apt-repo/README.md first: every installed machine needs the"
    echo "new keyring package before the old key is retired, so the two keys"
    echo "have to co-sign for a full release cycle."
    exit 1
fi

command -v gpg >/dev/null 2>&1 || { echo "gpg is not installed (sudo apt install gnupg)" >&2; exit 1; }

mkdir -p "$KEY_DIR"

echo "== Generating archive signing key for <$UID_EMAIL> =="
echo
echo "You will be asked for a passphrase. Use one, and store it wherever the"
echo "project's other secrets live -- an unprotected archive key on a laptop"
echo "is a key anyone with the laptop can sign releases with."
echo

# rsa4096 rather than the modern ed25519 default: apt's own signature
# verification handles both, but rsa4096 is what every apt version in the
# field understands without question, and this key has to work on whatever
# old apt a donated machine is running.
#
# No expiry date. An expired archive key breaks `apt update` on every
# installed machine simultaneously, with an error most users cannot act on,
# and the machines this distro targets may go months between connections.
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: $UID_NAME
Name-Email: $UID_EMAIL
Expire-Date: 0
EOF

FPR="$(gpg --with-colons --list-secret-keys "$UID_EMAIL" \
       | awk -F: '/^fpr:/ {print $10; exit}')"

if [ -z "$FPR" ]; then
    echo "Could not read back the fingerprint of the key just generated." >&2
    exit 1
fi

# Exported in binary (not ASCII-armoured) form: that is the format
# Signed-By: in a deb822 sources file expects at a .gpg path.
gpg --export "$FPR" > "$PUB_KEY"
echo "$FPR" > "$KEYID_FILE"

echo
echo "== Done =="
echo "Fingerprint : $FPR"
echo "Public key  : scripts/apt-repo/$PUB_KEY  (commit this -- it ships in"
echo "              venu-pacific-archive-keyring and in the ISO)"
echo "Key id file : scripts/apt-repo/$KEYID_FILE  (commit this too)"
echo
echo "Next steps:"
echo "  1. Back up the PRIVATE key somewhere safe and offline:"
echo "         gpg --export-secret-keys --armor $FPR > venu-pacific-archive.key"
echo "     Then store it in a password manager or offline medium and delete"
echo "     the file. Losing it means no machine can ever be sent an update."
echo "  2. Publish the fingerprint on https://venupacific.org so anyone can"
echo "     verify the key they received is the key you generated."
echo "  3. For CI signing, add that exported private key as the repository"
echo "     secret APT_SIGNING_KEY (see .github/workflows/release.yml)."
