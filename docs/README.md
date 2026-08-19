# docs/

Supporting documentation beyond the top-level README.md and CONTRIBUTING.md.
Published as a website at https://venupacific.org/ — built by
`.github/workflows/docs.yml` from `mkdocs.yml` on every push to main that
touches docs/.

- [index.md](index.md) — the site's landing page
- [download.md](download.md) — where to get the ISO and how to verify it
  (the ISO itself is served from Cloudflare R2, not from this site)
- [install-guide.md](install-guide.md) — writing the ISO to a USB drive,
  booting it, and installing to disk
- [updates.md](updates.md) — how installed machines receive fixes through
  `apt` from Venu Pacific's own signed package archive, what is in it, and
  what still needs a new image
- [releasing.md](releasing.md) — how to publish a release: distribution
  channel (the ISO is too large for GitHub Releases), R2 setup, versioning
  and tagging, checksums, release notes, and the "Venu" trademark
  due-diligence record
- [release-test-checklist.md](release-test-checklist.md) — the full
  end-to-end pass over every shipped app and behaviour, run on a freshly
  installed system before a release
- [manual-test-checklist.md](manual-test-checklist.md) — the real-hardware/mouse-required part
  of verifying the Calamares install-to-disk flow (a completed record of
  the 2026-07-21 pass; the release checklist above supersedes it for
  general use)
- [content-sourcing.md](content-sourcing.md) — research into Vanuatu
  educational content: what exists, what's openly licensed, sizes, and
  which institutions to partner with
