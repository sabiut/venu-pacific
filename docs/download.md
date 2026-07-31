# Download & verify

!!! note "First release in final testing"
    Venu Pacific 26.08 — the first public release — is currently in final
    testing. The download link and checksum will appear on this page when it
    ships. If you're part of the pilot, your machine or USB stick comes
    preloaded; this page is only needed for re-installs.

## What you'll download

Two files:

| File | What it is |
|---|---|
| `venu-pacific-26.08-amd64.iso` | The system image (~4.7 GB) |
| `venu-pacific-26.08-amd64.iso.sha256` | Its checksum, for verifying the download |

A 4.7 GB download is heavy on Pacific connections — that's deliberate:
everything (including the AI model and the offline encyclopedias) is inside,
so the machine needs nothing from the internet afterwards. **If a download is
impractical where you are,
[open an issue](https://github.com/sabiut/venu-pacific/issues) to ask about a
preloaded USB stick instead** — for the pilot, physical media is the primary
channel, not the fallback.

## Verifying the download

A partially-downloaded or corrupted ISO produces confusing installation
failures, so always verify before writing the USB stick. On Linux or macOS:

```bash
sha256sum -c venu-pacific-26.08-amd64.iso.sha256
```

On Windows (PowerShell):

```powershell
Get-FileHash venu-pacific-26.08-amd64.iso -Algorithm SHA256
```

then compare the printed hash with the contents of the `.sha256` file. It
must match exactly — if it doesn't, re-download.

## Next step

Once verified, follow the [install guide](install-guide.md) to write the ISO
to a USB stick (8 GB or larger) and install.
