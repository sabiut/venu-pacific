# Vanuatu educational content: what exists and what we can ship

Deep research done 2026-08-01 (three parallel investigations: MoET/VESP government
sources, openly licensed content, and the library landscape). Everything below was
verified against live pages and, for licensing, against the actual text inside
downloaded PDFs — not assumed. This document is the sourcing map for the "Learn
shelf" / digital-library workstream.

## The context that makes this matter

- ~459 primary + 141 secondary schools (MoET Statistical Report 2023); an NGO
  estimate says roughly 4 in 5 primary schools have no functioning library.
  **There is exactly one public lending library in the country** (Port Vila).
  MoET publishes no library/ICT statistics at all — the gap is undocumented.
- ~80% of Year 4 children are below basic reading proficiency (PILNA 2021 /
  Save the Children).
- The offline-server model is already ministry-endorsed in Vanuatu: COL gave MoET
  20 Aptus offline OER servers (2015), and Teacher in a Box deploys Kolibri-based
  offline servers there today. OLPC (2008-09) died for lack of ministry ownership.
  **Pattern that works: cheap + offline + ministry-blessed + locally relevant.**
- Electricity is as binding as connectivity — low-power/solar operation matters.

## Tier 1 — shippable today, no permission needed (licenses verified)

| What | Size | License | Where |
|---|---|---|---|
| **Bislama Wikipedia** (Kiwix ZIM, the only Bislama encyclopedia anywhere) | 16.6 MB | CC BY-SA | download.kiwix.org/zim/wikipedia/wikipedia_bi_all_maxi_2026-07.zim |
| **PhET science sims, Bislama UI** (ZIM) | 4.4 MB | CC BY 4.0 | download.kiwix.org/zim/phet/phet_bi_all_2026-05.zim |
| **PhET sims, all languages incl. EN+FR** (ZIM) | 152.6 MB | CC BY 4.0 | download.kiwix.org/zim/phet/phet_mul_all_2026-05.zim |
| **Bloom Library Vanuatu corpus** — "Vanuatu Literacy Nasara" (1,383 books, produced by **MoET's own Curriculum Development Unit** with GPE/Save the Children/SIL: graded ECCE + Y1-3 shelves in Bislama, English, French) + SIL Vanuatu (1,168 books incl. 18 vernacular languages) + Bislama shelf (374) | ~3 MB/book avg; a curated graded set of ~500 books ≈ 2-3 GB | **Per-book CC** (sampled: CC BY, CC BY-SA, CC BY-NC, CC BY-NC-SA — all fine for a free distro; a small "custom"-licensed minority must be filtered out) | bloomlibrary.org/Vanuatu-Literacy-Nasara · /SIL-Vanuatu · /language:bi — scriptable via the OPDS API (api.bloomlibrary.org/v1/opds); **request a free API key first** (anonymous access being discontinued; docs.bloomlibrary.org/opds) |
| **Library For All Vanuatu readers hosted by MoET** — 59 English + 59 French levelled readers, Vanuatu-localized (July 2026) | ~1.3 GB | **CC BY-NC-ND 4.0** (verified inside the PDFs) — verbatim non-commercial redistribution is allowed, modification is not | moet.gov.vu/docs/library/books/ |
| **Kolibri channels: PhET EN (1.1 GB) + PhET FR (0.12 GB) + Blockly Games (~0.3 GB)** — fills the empty Learn shelf with real interactive content | ~1.5 GB total | CC BY 4.0 / open source | Kolibri Studio tokens: PhET EN 197934f1…, PhET FR 3e7b3ae5…, Blockly e409b964… |

Confirmed negatives: no Vanuatu/Pacific/Bislama Kolibri channels exist (checked via
Studio's public API); Global Storybooks and StoryWeaver have nothing Pacific;
Khan Academy's channel is 54.8 GB with no official lite subset; Vanuatu Cultural
Centre archives are culturally governed (tabu restrictions — men-only/women-only/
kin-restricted material) and are ethically and legally not bundleable.

## Tier 2 — exists, free to download, but ALL-RIGHTS-RESERVED: needs MoET's written yes

Verified from copyright pages inside the actual PDFs ("All rights reserved,
© Ministry of Education... no reproduction without written permission" — and the
Bislama equivalent "Raet blong buk ia i stap wetem Gavman blong Vanuatu"):

- **The full national curriculum**: primary syllabuses Y1-3/Y4-6 (EN+FR, ~104 MB
  each), complete junior secondary Y7-10 syllabus/teacher-guide/resource tree,
  curriculum policies (EN+FR+Bislama). Live on the CDU hub: cdu.schools.edu.vu
  (public Google Drive folders; moet.gov.vu's own curriculum page is broken —
  empty directories with PHP errors).
- **VESP Bislama early-grade readers** (~75 titles on the CDU Drive) and the 2017
  Bislama Year 3 teacher guides (Matematiks, Saens, Lanwis, Laef long Komyuniti —
  ~100 MB, on moet.gov.vu/docs/textbooks/).
- **COVID home-learning packs** (ECCE/primary/junior-secondary, EN/FR/Bislama,
  ~300 MB) and **40 radio-lesson WAVs (~12-13 GB** — would need Opus transcoding).

The case for a yes is strong — MoET already gives all of it away free online, and
an offline mirror advances their own access goals. But the yes must be in writing.

**Who to ask:** Curriculum Development Unit (Kurikulum Divelopmen Yunit), MoET,
Port Vila — via education@vanuatu.gov.vu / +678 22309, cc the MoET ICT Unit.
For VESP-funded materials the rights sit with the Government of Vanuatu (stated in
the books), so CDU is the right door; VAESP (espvanuatu.org, Tetra Tech/DFAT) as a
supporting contact. Note: many of the same readers are ALSO on Bloom Library with
per-book CC licenses — **when a book is on Bloom, ship the Bloom copy** (the
license travels with it) rather than the CDU Drive copy.

## Partner institutions (from the landscape research)

1. **MoET CDU + Save the Children Vanuatu** — they jointly ran the 2025-26 national
   distribution of 100+ ni-Vanuatu readers to every primary school (by horseback on
   Tanna). Shipping those books offline rides an existing government priority.
2. **Vanuatu National Library / Cultural Centre** — legal-deposit holder; a
   partnership legitimizes "national digital library" framing; VKS curates what
   cultural material is appropriate for open school use.
3. **Alliance Française de Port-Vila** — the ready channel for French content;
   physical presence on 5+ islands; serves the francophone ~third of schools.

## Recommended shape (post-v1 workstream, sized)

- **On the ISO** (cheap, tiny): the two Bislama ZIMs (Wikipedia 16.6 MB + PhET-bi
  4.4 MB) — 21 MB for "the only Bislama encyclopedia anywhere" plus science sims
  with a Bislama UI. Optionally PhET multilingual (152 MB).
- **"Venu Pacific Library" companion pack** (USB/download, ~5-6 GB): curated Bloom
  graded shelves (Literacy Nasara ECCE→Y3 + Bislama + top vernaculars), the 118
  LFA readers, PhET EN/FR + Blockly Kolibri channels. A simple offline shelf app
  or folder tree + BloomPUB viewer decision needed.
- **The MoET conversation** during the pilot: curriculum + teacher guides offline
  is the single request that would make this the reference machine for every
  teacher in the country.

## Verification caveats

School-library gap percentages and pass-rate claims are NGO self-reports; PILNA,
school counts, program existence, and every license quoted above are verified.
Bloom bulk pipeline needs the free API key. Bloom license filtering must be
per-book (a small custom-licensed minority exists). LFA's broader catalog (their
app/Spark kits) is claimed-CC but unverified per-title — only the 118 MoET-hosted
readers were license-verified.
