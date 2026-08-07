# Venu Pacific

A Debian-based desktop Linux distribution built for the Pacific Islands
region. Designed around the region's real conditions: expensive/unreliable
bandwidth, aging donated hardware, many languages, and routine
cyclone/tsunami/earthquake exposure.

**Website & docs:** https://venupacific.org · **Download:**
https://venupacific.org/download/ (first release in final testing)

## Base

- Debian 13 (trixie) stable
- XFCE desktop
- `live-build` for the ISO, Calamares for the installer

## Repo layout

```
config/          live-build configuration (Phase 1)
branding/         logo, wallpapers, boot splash, icon theme (Phase 1)
locales/          gettext translation catalogs — en, bi, fj (Phase 2)
welcome-app/     first-run language picker / setup (Phase 1)
disaster-info/    offline cyclone/tsunami/earthquake safety info (Phase 2)
services-directory/ offline government/health/education directory (Phase 2)
kiwix-content/    curated offline-content download guide (Phase 2)
scripts/          build and maintenance scripts
docs/             supporting documentation
```

## Installing

See [docs/install-guide.md](docs/install-guide.md) for writing the ISO to a
USB drive, booting it, and installing to disk.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Venu Pacific's own code is licensed under [GPL-3.0](LICENSE). The
underlying OS remains Debian and carries its own package licenses.
