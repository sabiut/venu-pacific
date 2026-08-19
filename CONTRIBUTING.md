# Contributing to Venu Pacific

Thanks for helping build this. A few ground rules that follow directly from
the project's phased roadmap:

## The sequencing principle

We are **not** trying to support every Pacific language and country at once
— that's the most common way projects like this stall. v1 ships English +
Bislama. Everything is built so adding a language or country later is a
translation/content task, not an engineering one. If you want to bring your
own language or country in, the localization framework in `locales/` is the
place to do it — please don't ask for special-casing in the core build.

## What we're looking for right now (Phase 0/1)

- Testing on real, aging Pacific-region hardware (this matters more than
  testing on a modern laptop — that's not the target device)
- Package list review for `config/` once live-build config lands
- Branding assets (`branding/`) — logo, wallpaper, icon direction
- Anyone from a pilot school/NGO/office willing to test an early ISO

## Translations

`locales/venu-pacific.pot` is the template, extracted from the welcome
app's source strings. `locales/bi/venu-pacific.po` (Bislama) is done and
reviewed by a fluent speaker — v1 ships English and Bislama both. To add
another language:

1. If your language doesn't have a catalog yet, run
   `msginit --input=locales/venu-pacific.pot --locale=<lang-code> --output=locales/<lang-code>/venu-pacific.po`
2. Fill in the `msgstr` lines (a `.po` file is plain text — any text editor
   or a tool like [Poedit](https://poedit.net/) works)
3. Open a PR — a native or fluent speaker review is required before merge.
   The app only enables a language once its catalog is reviewed, not just
   present.

If the source strings change, `scripts/update-pot.sh` regenerates the
template and merges the changes into every existing catalog without
touching translations already done (needs the `gettext` package for
`xgettext`/`msgmerge`).

## Country content (disaster-readiness, services directory)

Both `disaster-info/content/` and `services-directory/content/` have one
JSON file per country (Vanuatu and Fiji so far) — emergency contacts and
cyclone/tsunami/earthquake safety guidance in the former, government
e-services/health facilities/education resources in the latter. See each
directory's `content/README.md` for its schema. Disaster-readiness content
especially can put someone in actual danger if it's wrong, so both hold to
the same standard:

1. Cite an official source (government agency, ministry, meteorological
   service, or a recognized body like UNESCO-IOC/PTWC/UNDRR) for every
   fact — not tourism sites or blogs.
2. If official sources conflict or can't be verified (this happens — e.g.
   a government site being unreachable, or two official pages disagreeing),
   say so explicitly in the file's `_editorial_notes` field rather than
   picking one silently. A flagged gap is far better than a confident wrong
   answer here.
3. Open a PR — ideally with review from someone who can verify against the
   original source or has local knowledge of the country in question.

## How your change reaches a real machine

Everything Venu Pacific-specific ships as a `.deb`, built from `debian/` by
`scripts/build-debs.sh` and published to Venu Pacific's own signed apt
archive. That is what lets a fix reach machines that are already installed,
in kilobytes rather than as a new 4.7GB image — see
[docs/updates.md](docs/updates.md).

Two practical consequences for a PR:

- **Nothing installs to `/usr/local`.** Debian policy reserves it for the
  local administrator, and a package cannot own a file there — so anything
  put there can never be upgraded by `apt`. Programs go to `/usr/bin` (or
  `/usr/sbin`); `scripts/lint.sh` fails the build if a `/usr/local` path
  reappears.
- **New files need a home in `debian/rules`.** Adding a script, icon or data
  file to one of the source directories does not ship it — say which package
  installs it and where. `debian/control` explains what each package is for.

A content fix (the JSON above) needs nothing beyond editing the file: it is
already inside `venu-pacific-content`.

## Code changes

- Keep the desktop XFCE-class in resource use — the target machine is an
  8-15 year old donated laptop, not a modern one
- Don't add features ahead of the phase they belong to — small, working
  increments over speculative scope
- Explain platform-specific or region-specific decisions in code comments;
  everything else should be self-explanatory

## Reporting issues

Open a GitHub issue (once the repo has a remote) describing what you tried,
what happened, and your hardware/locale if relevant — that context matters
more here than on a typical desktop-Linux bug report.
