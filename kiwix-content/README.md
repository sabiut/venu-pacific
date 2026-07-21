# kiwix-content/

A curated, branded HTML page recommending specific Kiwix ZIM files to
download — not bundled directly (every genuinely relevant one is
0.6-4.2GB+, which would meaningfully grow the ISO size for every user,
working against the project's bandwidth constraint) and not a custom app
(Kiwix's own `kiwix-desktop` binary has no documented way to pre-seed or
filter its built-in library browser, so rather than reverse-engineer an
undocumented Qt settings format, this just curates a shortlist with direct
download links and lets people use Kiwix's existing File → Open).

**One exception**: Vikidia (a children's encyclopedia) is only ~103MB with
images — small enough that it's bundled directly
(`0160-pacific-linux-kiwix-vikidia.hook.chroot` downloads it at build time,
not committed to git) with its own launcher
(`pacific-linux-vikidia.desktop`) that opens Kiwix straight to it, no
download needed.

- `index.html` — the guide itself, opened in Firefox
- `pacific-linux-kiwix-content.desktop` — applications-menu entry for the guide
- `pacific-linux-vikidia.desktop` — applications-menu entry that launches
  Kiwix directly on the bundled Vikidia ZIM

Every recommendation and its direct download URL was verified against
Kiwix's actual OPDS catalog (opds.library.kiwix.org) and download mirror
(download.kiwix.org) before being added — see the page itself for the
honest caveats on each pick (e.g. the agriculture collection being older
public-domain texts, not modern extension material).

Wired into the build via `config/config/includes.chroot/usr/share/pacific-linux/kiwix-content/`
and `.../usr/share/applications/` — copies of the files here, kept in sync
manually (same pattern as `disaster-info/` and `welcome-app/`).
