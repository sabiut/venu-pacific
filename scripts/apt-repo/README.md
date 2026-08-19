# scripts/apt-repo/

The Venu Pacific package archive: the thing that makes `apt update` on a
user's machine see releases published here.

## Why this exists

Before this, everything Venu Pacific-specific was copied into the image as
loose files under `/usr/local`. That works exactly once. Nothing there is
owned by dpkg, `/usr/local` is the one place Debian policy reserves for the
local administrator and forbids packages from touching, and no apt source on
the installed machine pointed anywhere but `deb.debian.org`. A correction to
the cyclone guidance meant rebuilding and redistributing a 4.7GB image —
across connections this project exists precisely because they are bad.

Now every component is a `.deb`, and an installed machine carries a signed
source entry pointing at `https://download.venupacific.org/apt`. A content
fix is a few hundred kilobytes.

## The parts

| | |
|---|---|
| `../../debian/` | the packaging: one source package, eight binary packages |
| `../build-debs.sh` | builds them into `dist/` |
| `make-key.sh` | generates the archive signing key (run once, ever) |
| `keys/venu-pacific-archive-keyring.gpg` | the public half — **committed**, ships in `venu-pacific-archive-keyring` |
| `keys/KEYID` | the fingerprint `publish.sh` signs with — committed |
| `conf/release.conf` | the archive-level fields for `dists/trixie/Release` |
| `publish.sh` | indexes the packages, signs the archive, uploads it to R2 |
| `r2.env` | local R2 account id / bucket / profile — **gitignored**, copy `r2.env.example` |

## First-time setup

```bash
./scripts/apt-repo/make-key.sh
```

Run this **once**. It generates the key and writes both `keys/` files. Commit
them, back the private half up offline, and publish the fingerprint on
venupacific.org so anyone can check the key they received is the key you
generated.

Until it exists, `./scripts/build-debs.sh` refuses to run and CI fails — on
purpose. A keyring package built around no key would leave every machine
rejecting every Venu Pacific package at once, and it would look like a
working build right up to the moment users tried to upgrade.

## Publishing a release

```bash
./scripts/build-debs.sh
./scripts/apt-repo/publish.sh
```

On a machine that cannot install `debhelper`, use
`./scripts/build-debs-in-docker.sh` for the first line — it builds in a
container and hands the output back to your user, so the signing step (which
stays on the host, and needs write access to `dist/`) still works.

`publish.sh` reads the R2 account id from `r2.env`. Without that file the id
exists nowhere on disk: not in the repo, deliberately, and not in `~/.aws`
either — leaving shell history as the only copy, which is not somewhere to
be searching in the middle of a release.

### Why apt-ftparchive and not reprepro

reprepro and aptly are the conventional tools, and the first version of this
used reprepro. Both have to be installed as root, and this project is
maintained from an account without sudo — so the conventional choice was
simply unavailable, and working around it with a container would have meant
handing the archive's private key to that container.

`apt-ftparchive` is what reprepro wraps. It ships in `apt-utils`, which is
already on every Debian system, and the signing is then plain `gpg` on the
maintainer's own machine. The result is byte-for-byte an ordinary apt
archive; nothing about it is unusual from a client's point of view.

The one thing reprepro gave us for free and this does not is pool
housekeeping: superseded `.deb` files are left in place rather than removed,
because deleting them before the new index has propagated breaks exactly the
users whose apt still has the old index cached. Run `PRUNE_POOL=1
./scripts/apt-repo/publish.sh` to reclaim that space once a release has
settled.

`DRY_RUN=1` builds and signs the archive under `dist/apt/` without uploading
anything — worth doing the first time.

Then check it as a user's apt would, over the public URL rather than the
bucket, since that is the only way a Cloudflare cache or custom-domain
mistake shows up:

```bash
curl -fsS https://download.venupacific.org/apt/dists/trixie/InRelease | head -20
```

## Where the key lives

The private key is the project's identity to every installed machine. apt
accepts a package because this key signed the index it came from.

- **Never** commit it. `.gitignore` has patterns for the usual filenames, but
  those are a safety net, not the rule.
- Back it up offline — a password manager, or an encrypted drive kept
  somewhere other than the build laptop. Losing it means no machine can ever
  be sent an update again.
- It has **no expiry date**, deliberately. An expired archive key breaks
  `apt update` on every installed machine simultaneously, with an error most
  users cannot act on, and these machines may go months between connections.

### Publishing from CI

`.github/workflows/release.yml` can publish on a version tag, but only if
`APT_SIGNING_KEY` (and optionally `APT_SIGNING_PASSPHRASE`) plus the R2
credentials are configured as repository secrets. Without them it still
builds the packages and uploads them as an artifact, and says so.

That is a real trade-off, not an oversight. Putting the signing key in a
GitHub secret means GitHub, and anyone who can push a workflow change, can
sign packages every Venu Pacific machine will install without question. For
v1 — where the ISO is already uploaded by hand — **publishing from a
maintainer's machine is the safer default**, and the workflow exists for
when release cadence makes that inconvenient.

### Rotation

Rotating the archive key is expensive, so plan it rather than react to it.
Every installed machine must receive the *new* keyring package, signed by
the *old* key, before the old key stops signing. In practice: publish one
release where both keys sign the archive, wait for machines to pick it up,
then retire the old key. A key retired before that has happened leaves those
machines unable to fetch anything — including the fix.

## Suites

The archive's suite is `trixie`, tracking the Debian base rather than the
Venu Pacific version. A machine installed from 26.08 and one installed from
26.11 are both trixie machines and want the same packages. When Venu Pacific
moves to a newer Debian, it publishes into a new suite, and machines still on
trixie keep receiving trixie-compatible packages instead of silently jumping
base underneath a user who never asked for it.
