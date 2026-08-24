# Download & verify

!!! note "First release in final testing"
    Venu Pacific 26.08.3 — the first public release — is currently in final
    testing. The download links below go live the moment it ships; until
    then they will show "not found". If you're part of the pilot, your
    machine or USB stick comes preloaded; this page is only needed for
    re-installs.

## What you'll download

Two files:

| File | What it is |
|---|---|
| [`venu-pacific-26.08.3-amd64.iso`](https://download.venupacific.org/venu-pacific-26.08.3-amd64.iso) | The system image (~4.7 GB) |
| [`venu-pacific-26.08.3-amd64.iso.sha256`](https://download.venupacific.org/venu-pacific-26.08.3-amd64.iso.sha256) | Its checksum, for verifying the download |

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
sha256sum -c venu-pacific-26.08.3-amd64.iso.sha256
```

On Windows (PowerShell):

```powershell
Get-FileHash venu-pacific-26.08.3-amd64.iso -Algorithm SHA256
```

then compare the printed hash with the contents of the `.sha256` file. It
must match exactly — if it doesn't, re-download.

## The archive signing key

Updates after installation come from Venu Pacific's own package archive, and
every index it publishes is signed with this key:

```
Venu Pacific Archive Signing Key <archive@venupacific.org>
37034C65 973FF8A0 99FEF888 C3911397 DCE079CB
```

You do not need to do anything with it — an installed system already carries
it, and `apt` checks the signature on every update. It is published here so
that the fingerprint on your machine can be checked against a source other
than the machine itself. See [Getting updates](updates.md#the-archive-signing-key).

## Next step

Once verified, follow the [install guide](install-guide.md) to write the ISO
to a USB stick (8 GB or larger) and install.
