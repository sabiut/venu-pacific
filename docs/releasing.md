# Releasing Venu Pacific

How to publish a release. Written because none of this existed before the first one, and the
obvious channel doesn't work: **the ISO is ~4.7GB and GitHub Releases rejects any file over
2GB.** That constraint shapes everything below.

## 1. Decide the distribution channel (do this before anything else)

This is a real decision, not a formality. Options, with the honest trade-offs:

**USB sticks and preconfigured machines — recommended for v1.** The strategic review recommended
exactly this ("deliver a preconfigured device or live USB in addition to an ISO download"), and
it fits the project's own founding constraint: a 4.7GB download is punishing on the connections
this distro exists to serve. For a Vanuatu-first pilot, physical media reaches the pilot site
better than any mirror. Cost: doesn't scale past hand-delivery, and needs the checksum published
somewhere so recipients can verify what they were given.

**A free file host with large-file support** (SourceForge, Internet Archive). Works today, no
infrastructure to run, both are used by real distros. Cost: third-party dependency, variable
download speed into the Pacific.

**BitTorrent** (a `.torrent` + magnet link in the repo). Bandwidth-friendly, standard for distro
ISOs, and resumable — which matters a lot on unreliable connections. Cost: needs at least one
stable seed, and some institutional networks block it.

**Self-hosted / regional mirror.** The Phase 4 endgame (a regional mirror is already on the
roadmap) and by far the best fit long-term. Cost: real hosting money and maintenance now.

**Splitting the ISO to fit GitHub's 2GB limit** — technically possible (`split` + reassembly
instructions), but it makes verification and instructions worse for exactly the least technical
users. Not recommended.

Whatever is chosen, **record the decision and the download URL in `README.md`** so there's one
canonical answer to "where do I get it".

## 2. Pre-release verification

- [ ] CI green on `main` (`gh run list --limit 1`)
- [ ] Build a fresh ISO from a clean tree — see the exact command in
      [install-guide.md](install-guide.md); always plain `lb config` with **no arguments**, since
      arguments overwrite saved config (this silently re-stamped the old brand name twice)
- [ ] Walk [release-test-checklist.md](release-test-checklist.md) end to end on that exact ISO,
      on real hardware if at all possible
- [ ] Anything failing in the model-service or assistant-correctness sections blocks the release

## 3. Version and tag

Versioning: `YY.MM` calendar versioning (e.g. `26.08`), matching how Ubuntu/Debian-derivative
users already read distro versions, with `-rc1` suffixes for candidates. Point releases add a
patch: `26.08.1`.

```bash
# from the repo root, on main, with the tree clean
git tag -a v26.08 -m "Venu Pacific 26.08 — first public release"
git push origin v26.08
```

Also update the version shown to users if it has drifted: `strings:` → `version` and
`versionedName` in
`config/config/includes.chroot/etc/calamares/branding/venu-pacific/branding.desc`.

## 4. Checksums (never publish an ISO without these)

Users on unreliable connections get truncated downloads, and USB copies get made by hand — a
checksum is how anyone knows they have an intact image.

```bash
cd config
sha256sum live-image-amd64.hybrid.iso > venu-pacific-26.08-amd64.iso.sha256
cat venu-pacific-26.08-amd64.iso.sha256
```

Rename the ISO to match the published name before hashing (the checksum file records the
filename, so hash what you actually ship):

```bash
mv live-image-amd64.hybrid.iso venu-pacific-26.08-amd64.iso
sha256sum venu-pacific-26.08-amd64.iso > venu-pacific-26.08-amd64.iso.sha256
```

Publish the `.sha256` **in the git repo** (it's tiny) as well as next to the download, so it's
verifiable from a source the ISO host doesn't control. Verification instructions for users:

```bash
sha256sum -c venu-pacific-26.08-amd64.iso.sha256
```

**GPG signing** is the stronger step — it proves *who* built the image, not just that bytes
match, which matters as soon as anyone but you distributes it. Deferred for v1 while
distribution is hand-to-hand; adopt it before the first download link goes public more widely:

```bash
gpg --armor --detach-sign venu-pacific-26.08-amd64.iso   # produces .iso.asc
```

## 5. Release notes

A GitHub Release (tag only, no ISO attached — see the size limit) is the right home for notes.
Cover, in plain language for a non-Linux audience:

- What Venu Pacific is, and the honest scope of this release
- **Known limitations, stated up front** — for v1 that includes: Kolibri ships without content
  channels; the AI assistant is slow on low-end hardware (record the measured tok/s and what
  that means in seconds); assistant answers and translations are best-effort, with Disaster
  Readiness / Services Directory as the authoritative sources; content covers Vanuatu and Fiji
  only
- Hardware requirements: 8GB RAM floor (the assistant needs it), disk space for a ~4.7GB image,
  and the note that a second RAM stick roughly doubles assistant speed
- Where to download / how to request a USB, plus the checksum and how to verify it
- How to report problems

## 6. After publishing

- [ ] `README.md` points at the release and the checksum
- [ ] `docs/install-guide.md` matches what users will actually download (filename, size)
- [ ] Record in `ROADMAP.md` what shipped and what was deferred, so the next release starts from
      a truthful baseline
