#!/bin/bash
# Regenerates locales/pacific-linux.pot from the welcome app's source
# strings, then merges any new/changed msgids into each locales/*/pacific-linux.po
# catalog (msgmerge preserves existing translations, marks changed ones
# fuzzy for re-review, and never overwrites a filled-in msgstr with an
# empty one). Requires the `gettext` package (xgettext, msgmerge).
set -eu
cd "$(dirname "$0")/.."

xgettext \
    --language=Python \
    --keyword=_ \
    --from-code=UTF-8 \
    --package-name=pacific-linux \
    --msgid-bugs-address=https://github.com/sabiut/pacific-linux/issues \
    --output=locales/pacific-linux.pot \
    welcome-app/pacific-linux-welcome

for po in locales/*/pacific-linux.po; do
    [ -f "$po" ] || continue
    msgmerge --update --backup=off "$po" locales/pacific-linux.pot
    echo "updated $po"
done

echo "locales/pacific-linux.pot regenerated."
