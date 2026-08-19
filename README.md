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
config/           live-build configuration for the ISO
debian/           packaging — turns the directories below into .deb packages
branding/         logo, wallpapers, boot splash, icon theme
locales/          gettext translation catalogs — en, bi, fj
welcome-app/      first-run language picker / setup
hub/              the launcher that ties the apps together
ai-assistant/     offline AI assistant
disaster-info/    offline cyclone/tsunami/earthquake safety info
services-directory/ offline government/health/education directory
kiwix-content/    curated offline-content download guide
system/           systemd units, session defaults, update notifier
scripts/          build and maintenance scripts
scripts/apt-repo/ the package archive installed machines update from
docs/             supporting documentation
```

## Installing

See [docs/install-guide.md](docs/install-guide.md) for writing the ISO to a
USB drive, booting it, and installing to disk.

## Updating

Installed machines get fixes through `apt`, from Venu Pacific's own signed
package archive at `download.venupacific.org/apt` — in kilobytes, not by
downloading a new 4.7GB image. Nothing is ever fetched or installed without
the user choosing it, since bandwidth here is often capped or metered.

See [docs/updates.md](docs/updates.md) for how it works, and
[scripts/apt-repo/README.md](scripts/apt-repo/README.md) for publishing one.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Venu Pacific's own code is licensed under [GPL-3.0](LICENSE). The
underlying OS remains Debian and carries its own package licenses.
