# Venu Pacific

**A Debian-based desktop Linux distribution built for the Pacific Islands
region** — designed around the region's real conditions: expensive and
unreliable bandwidth, aging donated hardware, many languages, and routine
cyclone, earthquake, tsunami, and volcano exposure.

*Venu* is the word for volcano on Ambrym, Vanuatu.

## What makes it different

Everything important works **completely offline**:

- **AI Assistant** — questions, translation, printer and Wi-Fi
  troubleshooting, PDF reading. Runs entirely on the machine; nothing is
  sent to the internet unless you explicitly ask and approve.
- **Disaster Readiness** — cyclone, earthquake, tsunami, and volcano
  guidance with real, sourced emergency numbers for Vanuatu and Fiji.
- **Services Directory** — passports, certificates, licenses, hospitals,
  and education contacts for Vanuatu and Fiji.
- **Offline encyclopedias** — Vikidia (for ages 8–13), the
  Bislama-language Wikipedia, and PhET science simulations with a Bislama
  interface. Bundled, no download needed.
- **Learn (Kolibri)** — an offline courses platform, ready for content
  packs downloaded by a school or coordinator.
- **The everyday tools** — LibreOffice, Firefox, GIMP, all preinstalled.

First-run language choice: English, Bislama, or Fijian.

## Built on

- Debian 13 (trixie) stable, XFCE desktop
- `live-build` for the ISO, Calamares for the installer
- Runs on modest hardware — the target is the kind of 8GB donated machine
  Pacific schools actually have

## For users and schools

- [Download & verify](download.md) — where to get the ISO and how to check it
- [Install guide](install-guide.md) — writing a USB stick, booting, installing —
  including a [video walkthrough](install-guide.md) of the whole process
- [Getting updates](updates.md) — installed machines receive fixes through
  `apt` in kilobytes, not by downloading a new 4.7GB image, and never
  without you choosing to

## Status

Pre-release. The first release (26.08.3) is in final testing — a Vanuatu-first
pilot on real hardware comes before any wide distribution. Found a problem
or want to help? [Open an issue](https://github.com/sabiut/venu-pacific/issues).

## License

Venu Pacific's own code is
[GPL-3.0](https://github.com/sabiut/venu-pacific/blob/main/LICENSE). The
underlying OS remains Debian and carries its own package licenses. Bundled
content carries its own licenses (CC BY-SA for Wikipedia content, CC BY for
PhET, and so on), documented per source.
