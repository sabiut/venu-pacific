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
infrastructure to run, both are used by real distros, and **zero billing exposure** — no card,
no way to run up a bill. Cost: third-party dependency, variable download speed into the Pacific.

**BitTorrent** (a `.torrent` + magnet link in the repo). Bandwidth-friendly, standard for distro
ISOs, and resumable — which matters a lot on unreliable connections. Cost: needs at least one
stable seed, and some institutional networks block it.

**Cloudflare R2** — the best option if you want a download URL you control (setup: §1a below).

**Self-hosted / regional mirror.** The Phase 4 endgame (a regional mirror is already on the
roadmap) and by far the best fit long-term. Cost: real hosting money and maintenance now.

**Splitting the ISO to fit GitHub's 2GB limit** — technically possible (`split` + reassembly
instructions), but it makes verification and instructions worse for exactly the least technical
users. Not recommended.

Whatever is chosen, **record the decision and the download URL in `README.md`** so there's one
canonical answer to "where do I get it".

### How other distros solve this, and what transfers

Debian — the upstream this project is built on — doesn't pay for bandwidth at all. Their model,
and what's actually copyable at this project's scale:

- **A worldwide volunteer mirror network** (universities, ISPs, research institutes donating
  servers). Decades in the making; unavailable to a new distro on day one. But note *how* it
  came about: institutions donated capacity. The natural donors here are exactly the partners
  already in this roadmap's Phase 4 — USP, SPC, national ICT ministries. A USP-hosted mirror
  would be faster inside the region than any commercial CDN, and asking costs nothing.
- **BitTorrent as a first-class channel** — official `.torrent` files published alongside every
  ISO and prominently linked, precisely because of bandwidth economics. Directly copyable, and
  its resumability is worth more on Pacific connections than almost anywhere else.
- **Checksums + GPG signatures on every image**, with the signing key documented. Copyable
  verbatim; this is §4 below.
- **A published list of physical-media vendors.** Debian formally endorses buying pressed
  DVDs/USBs for people who can't download. That's institutional validation for the USB-first
  approach recommended above — following upstream's reasoning, not improvising.
- (Jigdo, their tool for rebuilding an ISO from already-mirrored packages, is clever but niche
  and fiddly — not worth adopting.)

### The number that actually decides this: egress

Storing 4.7GB is trivial everywhere (cents per month). **Bandwidth is the cost.** Every download
ships 4.7GB out the door:

| Downloads | AWS S3 (~$0.09/GB egress) | Cloudflare R2 | Archive.org / torrent |
|---|---|---|---|
| 100 | ~$42 | $0 | $0 |
| 1,000 | ~$420 | $0 | $0 |
| 10,000 | ~$4,200 | $0 | $0 |

The asymmetry is categorical, not marginal: R2 has **no egress fees on any tier**, by design, to
compete with AWS. For a project serving under-resourced communities, uncapped S3 egress is a
genuinely bad failure mode — success generates the bill. **Do not put a public ISO on plain S3**
without CloudFront and a hard billing alarm.

### 1a. Cloudflare R2 setup (recommended controllable option)

**Provisioned 2026-07-30**: bucket `venu-pacific-releases`, location hint Asia-Pacific (APAC),
bucket-scoped Object Read & Write API token created and CLI access verified. Public
Development URL enabled 2026-08-05 (`https://pub-5c5e5d1fa33748e99ea39f47ec77d4a8.r2.dev`),
then superseded the same week by the custom domain **`https://download.venupacific.org`**
(venupacific.org registered on Cloudflare; docs/download.md links point there; file links
404 until the release upload). The docs site lives at **https://venupacific.org/** (GitHub
Pages custom domain, CNAME-flattened apex). The account ID for `--endpoint-url` is on the
bucket's Settings page under **S3 API** (the host part of that URL, without the bucket name).

Cost at this project's scale: the free tier covers 10GB storage, 1M writes and 10M reads per
month, egress always free. One ISO (4.7GB) or two versions (9.4GB) = **$0/month**. Three versions
(~14GB) exceeds the free storage and costs about **$0.07/month** on the overage
($0.015/GB/month). Downloads never add anything.

Caveats, stated honestly:

- **A credit card is required even on the free tier.** There is no card-free path. If zero
  billing exposure matters more than control, use Archive.org + torrent instead — both are
  genuinely free and cannot generate a bill.
- **The free public URL is ugly and rate-limited**: `https://pub-<hash>.r2.dev/...`, which
  Cloudflare treats as development-grade. A clean branded URL needs a domain on Cloudflare
  (~$10-15/year) — plausibly worth having anyway.
- Keep the bucket **read-only to the public**. Write access is where surprise costs come from.

Setup, roughly an hour:

1. Create a Cloudflare account, then **R2 → Create bucket** (name e.g. `venu-pacific-releases`,
   location hint: Asia-Pacific). Adding a payment method is required even on the free tier.
2. **R2 → Manage API Tokens → Create token**, permission **Object Read & Write**, scoped to that
   bucket. Save the Access Key ID and Secret — the secret is shown once.
3. Note your **Account ID** (R2 dashboard sidebar); the endpoint is
   `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`.
4. Configure a named AWS-CLI profile so R2 credentials never mix with real AWS ones (this
   machine also has live AWS credentials, so the separate profile matters):

   ```bash
   aws configure --profile r2      # paste the R2 key/secret; region: auto
   ```

   Region must be the literal `auto` -- R2 has no AWS-style regions (bucket location is set by
   the location hint at creation), but the CLI needs a value to sign requests with.

   Configure and upload as the **same user** throughout: each user has its own `~/.aws/`, so
   credentials set up as a regular user are invisible to `root` and vice versa.

   Verify with a command scoped to the bucket, NOT `aws s3 ls` on its own -- a bucket-scoped
   token is correctly denied permission to list all buckets in the account, which looks like a
   credentials failure but isn't:

   ```bash
   aws s3 ls s3://venu-pacific-releases/ --profile r2 \
     --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com
   ```

   An empty result with no error means it works.

5. Upload (R2 speaks the S3 API, so the ordinary `aws s3` client works):

   ```bash
   aws s3 cp venu-pacific-26.08-amd64.iso \
     s3://venu-pacific-releases/ \
     --profile r2 \
     --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com

   aws s3 cp venu-pacific-26.08-amd64.iso.sha256 \
     s3://venu-pacific-releases/ \
     --profile r2 \
     --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com
   ```

   Multi-gigabyte uploads are chunked automatically and can be resumed by re-running the same
   command.
6. **Enable public access**: bucket → Settings → **Public Development URL** (gives the
   `pub-<hash>.r2.dev` link), or connect a custom domain for a branded URL.
7. Verify the published file end to end, as a user would:

   ```bash
   curl -L -o /tmp/test.iso <PUBLIC_URL>/venu-pacific-26.08-amd64.iso
   curl -L <PUBLIC_URL>/venu-pacific-26.08-amd64.iso.sha256
   sha256sum /tmp/test.iso     # must match
   ```

8. Set a **billing alert** in the Cloudflare dashboard anyway. Free tier or not, an alert is how
   you find out early if something is misconfigured.

**Recommended combination for v1**: USB/preconfigured machines for the pilot (the download
question is nearly moot when machines are hand-delivered), R2 or Archive.org for the public HTTP
link, a torrent alongside it once there's demand, and an institutional regional mirror as the
Phase 4 goal — which is, at this project's scale, Debian's actual answer.

## 1b. The name: trademark due diligence (researched 2026-07-30)

Not legal advice -- a documented gut-check by a non-lawyer, done before the name went public,
so the reasoning is on record. Conclusion first: **proceed with "Venu Pacific" for v1; the
risk is low**. Revisit with a real IP lawyer only if the project incorporates, takes funding,
or moves into commercial channels.

What exists (all verified against live sources on the date above):

- **Garmin's VENU** is the strongest mark in the space: US-registered (app. 88199274, Garmin
  Switzerland GmbH), International Class 9, actively used (Venu 4 shipped 2026) -- but its
  goods specification is wearables/GPS: smartwatches, activity-tracker wristbands, GPS
  navigation hardware and software. Not operating systems, not desktop software.
- **The field is already crowded**: VENU registrations coexist today under different owners
  even inside Class 9 -- Abuzz Entertainment (media display app software, reg. 4677507), VenU
  LLC (eLearning platform), plus Trimark (flatware), Venu Holding Corp (music venues, NYSE
  American-listed), VENU+ (attractions retail). A crowded field means every owner's
  enforceable scope is narrow; nobody owns "Venu" across the board.
- **Venu Sports** (the Disney/Fox/WBD streaming venture) was shut down January 2025 before
  launch.
- **No "Venu Pacific" exists anywhere** -- no company, trademark, or brand. No Linux
  distribution or OS project uses "Venu" (closest: Victron's "Venus OS", an embedded energy-
  device distro -- different word, different world).

Why the risk is low for this project specifically: the mark is the composite "Venu Pacific",
not bare "Venu"; the derivation is genuinely independent and documented (venu is the word for
volcano on Ambrym, Vanuatu -- the project's identity, not a riff on anyone's brand); the
product is a free, non-commercial desktop OS for Pacific schools and communities, sharing no
goods, channels, or customers with a $400 smartwatch; and the visual identity is a volcano.
Trademark risk is about likelihood of confusion, and there is no plausible consumer who
downloads a free Debian respin believing it comes from Garmin.

Two standing rules that keep it that way, and one caveat:

1. **Always the full name.** "Venu Pacific" in every user-visible and marketing context;
   never shorten to just "Venu" where wearables could conceivably be in frame.
2. **Never ship anything wearable/GPS/fitness-adjacent under this name.** That is Garmin's
   exact registered territory, and they enforce it.
3. If the project ever seeks its own US/EU trademark registration, expect the examiner to
   cite Garmin's Class 9 mark; the composite name + unrelated goods are the counter-argument,
   but budget for that conversation. A Vanuatu (VanIPO) check is also worth doing at
   incorporation time -- nothing suggests a conflict, but it wasn't searchable online for
   this pass.

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
