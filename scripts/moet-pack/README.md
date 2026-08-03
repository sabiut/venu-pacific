# MoET curriculum pack — PERMISSION-GATED, do not ship yet

Tooling for packaging the Vanuatu Ministry of Education and Training's own
learning materials for offline distribution in Venu Pacific.

## The gate

Every file in scope is **© Ministry of Education and Training, all rights
reserved** — verified from the copyright pages inside the actual PDFs
(including the Bislama ones: "Raet blong buk ia i stap wetem Gavman blong
Vanuatu"). They are free to *download* from MoET's own sites, but that does
not grant *redistribution* rights. **Nothing produced by this tooling ships
until MoET's written permission exists** (an email from the Curriculum
Development Unit is sufficient). The request letter has been drafted and the
conversation is being pursued; see docs/content-sourcing.md for the full
research, contacts, and licensing evidence.

`fetch.sh` enforces this: it refuses to run without
`--i-have-written-permission`, except in `enumerate` mode (listing what
exists infringes nothing).

## What's in scope (from the 2026-08-01 research)

Directly fetchable from moet.gov.vu (Apache directory listings):

- `/docs/textbooks/` — 17 PDFs (~140MB) incl. the 2017 VESP Bislama Year 3
  teacher guides: Matematiks, Saens, Lanwis mo Komyunikesen, Laef long
  Komyuniti
- `/docs/covid-updates/` — home-school packages: ECCE (Bislama), Primary
  (EN-BI ~129MB, FR-BI ~130MB), Junior Secondary (EN 6.7MB, FR 2.8MB)
- `/docs/ecce-school-packages/` — the 2024 ECCE re-issue
- `/docs/sounds/` — 40 radio-lesson WAVs (~12-13GB; transcode to Opus
  before packing — do NOT ship WAVs)

Needs manual handling (Google Drive, not directly scriptable):

- cdu.schools.edu.vu — the national syllabuses (Primary Y1-6 EN/FR ~104MB
  each, Junior Secondary Y7-10 trees), curriculum policies, VESP readers
  (~75 Bislama titles). Note: many readers also exist on Bloom Library
  under per-book CC licenses — when a book is on Bloom, ship the Bloom
  copy instead (the license travels with the file); see the library-pack
  workstream.

## Workflow

```sh
# 1. Any time (no permission needed): list what the site currently serves
./fetch.sh enumerate

# 2. When MoET's site is reachable: download everything and pin sha256s
#    into manifest.lock (the same freeze-then-verify pattern as the build
#    hooks). Requires the permission flag because it creates the local
#    redistribution copy.
./fetch.sh freeze --i-have-written-permission

# 3. Reproducible re-fetch, verified against the pinned hashes:
./fetch.sh fetch --i-have-written-permission
```

moet.gov.vu is frequently slow or unreachable (it was down the day this
tooling was written) — the script retries and can resume; just re-run.

## When the written yes arrives

1. Commit the permission record: save the email as
   `PERMISSION.md` in this directory (from whom, date, exact scope granted).
2. Run `freeze`, commit `manifest.lock`.
3. Packaging follows the established patterns: checksummed downloads,
   attribution + copyright notice preserved on every file, a shelf/index
   page consistent with the library pack's UX.
