# Contributing to Pacific Linux

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

`locales/pacific-linux.pot` is the template, extracted from the welcome
app's source strings. `locales/bi/pacific-linux.po` already exists as a
scaffold — every string is there, but every `msgstr` is intentionally
empty, since a guessed machine translation shown to real users is worse
than admitting Bislama isn't ready yet. To help:

1. If your language doesn't have a catalog yet, run
   `msginit --input=locales/pacific-linux.pot --locale=<lang-code> --output=locales/<lang-code>/pacific-linux.po`
2. Fill in the `msgstr` lines (a `.po` file is plain text — any text editor
   or a tool like [Poedit](https://poedit.net/) works)
3. Open a PR — a native or fluent speaker review is required before merge.
   The app only enables a language once its catalog is reviewed, not just
   present.

If the source strings change, `scripts/update-pot.sh` regenerates the
template and merges the changes into every existing catalog without
touching translations already done (needs the `gettext` package for
`xgettext`/`msgmerge`).

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
