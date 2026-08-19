# How updates reach an installed machine

Venu Pacific ships its own package archive. Once a machine is installed, it
receives fixes the same way it receives Debian's: through `apt`, in
kilobytes, without downloading a new image.

## For users

Nothing to set up. Every Venu Pacific installation already trusts and points
at the archive.

Once a day, at an off-peak hour, the machine refreshes the list of what is
available — a few hundred kilobytes of index, no packages — and if anything
can be updated you get a desktop notification saying how many.

**Nothing is ever downloaded or installed without you choosing it.** Data
here is often capped or metered, so applying an update is always a deliberate
act: open **Synaptic**, or run

```bash
sudo apt update && sudo apt upgrade
```

To check where updates come from:

```bash
apt policy venu-pacific-desktop
```

## What is in the archive

| Package | What it holds |
|---|---|
| `venu-pacific-content` | Disaster Readiness and Services Directory data — the cyclone, tsunami and earthquake guidance, and the government/health/education contacts |
| `venu-pacific-apps` | Welcome, Hub, Disaster Readiness, Services Directory, Help |
| `venu-pacific-assistant` | the offline AI assistant |
| `venu-pacific-branding` | wallpapers, boot splash, icons |
| `venu-pacific-l10n` | Bislama and Fijian translations |
| `venu-pacific-settings` | session defaults and the update notifier |
| `venu-pacific-archive-keyring` | the archive's signing key and source entry |
| `venu-pacific-desktop` | metapackage depending on all of the above |

The split is not cosmetic. `venu-pacific-content` is separate because it is
the part most likely to need correcting between releases and the part where
being wrong matters most — an out-of-date evacuation instruction is a safety
problem, and at a few hundred kilobytes it can be fixed over a connection
that could never carry a 4.7GB image.

The large bundled content — the Kiwix encyclopedias, Kolibri, the assistant's
2.4GB model — is **not** in the archive. Those are fetched at image-build
time and are far too big to push over the connections this distro serves.
They change with a new image, not with `apt upgrade`.

## Verifying the archive

Every index is signed. apt checks that signature on every `apt update` and
refuses anything that fails, so a mirror or network that tampers with a
package cannot get it installed.

The signing key ships in `venu-pacific-archive-keyring` at
`/usr/share/keyrings/venu-pacific-archive-keyring.gpg`, and the source entry
in `/etc/apt/sources.list.d/venu-pacific.sources` binds it to this one
archive with `Signed-By:` — so the Venu Pacific key can never vouch for
something claiming to be from Debian.

Check the fingerprint against the one published on venupacific.org:

```bash
gpg --show-keys /usr/share/keyrings/venu-pacific-archive-keyring.gpg
```

## For maintainers

Publishing a release, key handling and the archive layout are covered in
[scripts/apt-repo/README.md](https://github.com/sabiut/venu-pacific/blob/main/scripts/apt-repo/README.md)
and in the release runbook. The short version:

```bash
./scripts/build-debs.sh
R2_ACCOUNT_ID=<account-id> ./scripts/apt-repo/publish.sh
```

A content fix — the common case, and the reason for all of this — is: edit
the JSON, add a `debian/changelog` entry, run those two commands. Machines
pick it up at their next daily check and notify their users. No image
rebuild, no re-imaging, no USB run to the pilot site.

The version is defined in exactly one place, `debian/changelog`. Everything
else derives from it: `/etc/venu-pacific-release`, the `PRETTY_NAME` and
`VENU_PACIFIC_VERSION` fields in `/etc/os-release`, the version on the Help
page, and the installer's title.

### What still needs a new image

Anything installed by a live-build hook rather than a package: the llama.cpp
build and its 2.4GB model, Kolibri, the Kiwix ZIM files, the xfdesktop4 fix,
and the base Debian package selection. These are either too large to push
over these connections or sit outside what a package can reasonably own.
