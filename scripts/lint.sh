#!/bin/bash
# CI lint checks for Venu Pacific's live-build config: shell syntax,
# systemd unit validity, XML validity, and executable-bit sanity on
# everything that ships into the built image. Run locally with
# ./scripts/lint.sh, or via .github/workflows/ci.yml.
#
# Deliberately writes failures to a file rather than a shell variable —
# the checks below run inside `while read` loops fed by process
# substitution, and relying on a variable set inside a pipeline subshell
# is a classic way to silently lose failures.

set -u
cd "$(dirname "$0")/.."

FAIL_LOG="$(mktemp)"
trap 'rm -f "$FAIL_LOG"' EXIT

check_executable() {
    local f="$1"
    if [ ! -x "$f" ]; then
        echo "FAIL: $f is not executable (live-build requires this)" | tee -a "$FAIL_LOG"
    fi
}

# Dispatches on the shebang's interpreter rather than assuming shell — the
# app directories hold Python scripts (the welcome app and friends) next to
# the shell ones in system/, and running `sh -n` against those would be a
# false-positive syntax failure, not a real one.
check_script() {
    local f="$1"
    local shebang
    shebang="$(head -1 "$f" 2>/dev/null)"

    case "$shebang" in
        '#!'*python*)
            # Deliberately not `python3 -m py_compile` — it writes a
            # __pycache__ dir next to the file regardless of
            # PYTHONDONTWRITEBYTECODE, and those .pyc files would then be
            # picked up by the packaging. compile() in memory has no such
            # side effect.
            if ! python3 -c "
import sys
with open(sys.argv[1]) as fh:
    compile(fh.read(), sys.argv[1], 'exec')
" "$f" 2>&1; then
                echo "FAIL: $f has a Python syntax error" | tee -a "$FAIL_LOG"
            fi
            ;;
        '#!'*bash)
            # bash, not sh -- a script declaring #!/bin/bash may legitimately
            # use bash-only syntax (arrays, [[ ]], etc.), which sh -n would
            # false-fail on.
            if ! bash -n "$f" 2>&1; then
                echo "FAIL: $f has a shell syntax error" | tee -a "$FAIL_LOG"
            fi
            ;;
        '#!'*sh|'#!'*dash)
            if ! sh -n "$f" 2>&1; then
                echo "FAIL: $f has a shell syntax error" | tee -a "$FAIL_LOG"
            fi
            ;;
        '#!'*)
            echo "NOTE: $f has an unrecognized interpreter ($shebang), skipping syntax check"
            ;;
    esac

    check_executable "$f"
}

echo "== live-build hook scripts =="
while IFS= read -r -d '' f; do
    check_script "$f"
done < <(find config/config/hooks -type f \( -name "*.hook.chroot" -o -name "*.hook.binary" \) -print0 2>/dev/null)

echo "== packaged programs (app directories + system/) =="
while IFS= read -r -d '' f; do
    if head -c2 "$f" 2>/dev/null | grep -q '^#!'; then
        check_script "$f"
    fi
done < <(find ai-assistant disaster-info hub services-directory welcome-app \
              system/bin system/sbin scripts scripts/apt-repo scripts/moet-pack \
              -maxdepth 1 -type f -print0 2>/dev/null)

# Nothing shipped may still point at /usr/local. Debian policy reserves it
# for the local administrator: a package cannot own a file there, which
# means anything installed to /usr/local can never be upgraded by apt —
# the exact failure this packaging exists to fix. Everything now installs to
# /usr/bin and /usr/sbin; this catches a reference sneaking back in.
echo "== no /usr/local references in packaged files =="
while IFS= read -r -d '' f; do
    if grep -qs '/usr/local/s\?bin' "$f"; then
        echo "FAIL: $f references /usr/local (packages must install to /usr)" | tee -a "$FAIL_LOG"
    fi
done < <(find ai-assistant disaster-info hub kiwix-content services-directory \
              welcome-app system -type f -not -path "*/__pycache__/*" \
              \( -name "*.desktop" -o -name "*.service" -o -name "*.timer" \
                 -o -name "venu-pacific-*" \) -print0 2>/dev/null)

echo "== systemd unit files =="
if ! command -v systemd-analyze >/dev/null 2>&1; then
    echo "NOTE: systemd-analyze not installed, skipping unit validation"
fi
while IFS= read -r -d '' f; do
    command -v systemd-analyze >/dev/null 2>&1 || break
    output="$(systemd-analyze verify "$f" 2>&1)" || true
    # ExecStart targets don't exist on the lint host (they're only present
    # in the built rootfs) — that's expected, not a real failure. Anything
    # else systemd-analyze flags is real.
    real_errors="$(echo "$output" | grep -v 'is not executable: No such file or directory' || true)"
    if [ -n "$real_errors" ]; then
        echo "FAIL: $f" | tee -a "$FAIL_LOG"
        echo "$real_errors" | tee -a "$FAIL_LOG"
    fi
done < <(find system/systemd -type f \( -name "*.service" -o -name "*.timer" \) -print0 2>/dev/null)

echo "== XML files =="
while IFS= read -r -d '' f; do
    if ! python3 -c "import xml.dom.minidom as m; m.parse('$f')" >/dev/null 2>&1; then
        echo "FAIL: $f is not valid XML" | tee -a "$FAIL_LOG"
    fi
done < <(find system -name "*.xml" -print0 2>/dev/null)

echo "== SVG files (config/config/bootloaders/, branding/) =="
while IFS= read -r -d '' f; do
    if ! python3 -c "import xml.dom.minidom as m; m.parse('$f')" >/dev/null 2>&1; then
        echo "FAIL: $f is not valid XML/SVG" | tee -a "$FAIL_LOG"
    fi
done < <(find config/config/bootloaders branding -name "*.svg" -print0 2>/dev/null)

echo "== JSON content (disaster-info/, services-directory/) =="
while IFS= read -r -d '' f; do
    if ! python3 -c "import json; json.load(open('$f'))" >/dev/null 2>&1; then
        echo "FAIL: $f is not valid JSON" | tee -a "$FAIL_LOG"
    fi
done < <(find disaster-info services-directory -name "*.json" -print0 2>/dev/null)

echo "== gettext catalogs (locales/) =="
# Tool-absence is not a lint failure. This project is maintained from an
# account that cannot install packages, so a check that reports FAIL when
# its own tool is missing trains everyone to ignore the output -- and the
# real failures with it. CI installs gettext, so the catalogs are still
# genuinely checked before anything ships.
if command -v msgfmt >/dev/null 2>&1; then
    while IFS= read -r -d '' f; do
        if ! msgfmt --check -o /dev/null "$f" 2>&1; then
            echo "FAIL: $f failed msgfmt --check" | tee -a "$FAIL_LOG"
        fi
    done < <(find locales -type f \( -name "*.po" -o -name "*.pot" \) -print0 2>/dev/null)
else
    echo "NOTE: msgfmt not installed (gettext), skipping catalog validation"
fi

echo "== Debian packaging metadata =="
# dpkg-parsechangelog is the cheapest thing that reads debian/changelog and
# debian/control the way the real build will, so a typo in either fails the
# lint job in seconds instead of 90 minutes into an ISO build.
if command -v dpkg-parsechangelog >/dev/null 2>&1; then
    if ! dpkg-parsechangelog -l debian/changelog >/dev/null 2>&1; then
        echo "FAIL: debian/changelog is not parseable" | tee -a "$FAIL_LOG"
    fi
else
    echo "NOTE: dpkg-parsechangelog not available, skipping changelog check"
fi

# Every maintainer script in debian/ must actually reach its package.
#
# Six of them were deleted by a cleanup command whose glob
# ("rm -rf debian/venu-pacific-*") was meant for the staging directories and
# also matched debian/venu-pacific-branding.postinst and its siblings. The
# commit went through, three releases shipped, and nobody noticed: the
# packages still built, still installed, and still contained every file --
# they simply stopped configuring anything. The desktop kept Debian's
# wallpaper and boot splash, os-release lost its version, and the screen
# locker guard was never wired up.
#
# Nothing about a package with a missing postinst looks wrong from the
# outside, which is exactly why this needs a check rather than vigilance.
echo "== maintainer scripts present =="
for script in debian/venu-pacific-*.postinst debian/venu-pacific-*.preinst \
              debian/venu-pacific-*.prerm debian/venu-pacific-*.postrm; do
    [ -e "$script" ] || continue
    base="$(basename "$script")"
    pkg="${base%.*}"
    grep -q "^Package: $pkg\$" debian/control \
        || echo "NOTE: $base has no matching package in debian/control"
done
for expected in venu-pacific-branding.postinst venu-pacific-branding.prerm \
                venu-pacific-desktop.postinst venu-pacific-settings.preinst \
                venu-pacific-settings.postinst venu-pacific-settings.postrm; do
    if [ ! -f "debian/$expected" ]; then
        echo "FAIL: debian/$expected is missing" | tee -a "$FAIL_LOG"
        echo "      without it the package installs but configures nothing" | tee -a "$FAIL_LOG"
    fi
done

# The published docs name the release version in download filenames and in
# the checksum command users copy. When that drifted behind debian/changelog
# nothing noticed -- the site advertised an ISO filename the release would
# never produce, and the sha256sum command on the page would have failed for
# every user. ./scripts/sync-docs-version.sh is the fix.
if command -v dpkg-parsechangelog >/dev/null 2>&1; then
    doc_version="$(dpkg-parsechangelog -SVersion 2>/dev/null)"
    for page in docs/download.md docs/install-guide.md docs/index.md; do
        [ -f "$page" ] || continue
        stale="$(grep -oE "venu-pacific-[0-9]{2}\.[0-9]{2}(\.[0-9]+)?-amd64" "$page" \
                 | grep -v "venu-pacific-$doc_version-amd64" | sort -u || true)"
        if [ -n "$stale" ]; then
            echo "FAIL: $page names $stale but debian/changelog says $doc_version" | tee -a "$FAIL_LOG"
            echo "      run ./scripts/sync-docs-version.sh" | tee -a "$FAIL_LOG"
        fi
    done
fi

# The keyring package is what points an installed machine at the archive.
# Building it without the archive's public key would produce a keyring that
# trusts nothing, and apt would reject every Venu Pacific package on every
# user's machine at once.
if [ ! -f scripts/apt-repo/keys/venu-pacific-archive-keyring.gpg ]; then
    echo "NOTE: no archive signing key yet (scripts/apt-repo/make-key.sh)."
    echo "      .deb builds will fail until it exists; see scripts/apt-repo/README.md"
fi

echo
if [ -s "$FAIL_LOG" ]; then
    echo "Lint failed."
    exit 1
fi

echo "Lint passed."
