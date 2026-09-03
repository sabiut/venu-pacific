# scripts/

Build and maintenance tooling.

| | |
|---|---|
| `build-debs.sh` | builds Venu Pacific's own `.deb` packages into `dist/`. Run before `lb build` — the image installs them from `config/config/packages.chroot/`, and they are what an installed machine upgrades through `apt`. Needs `debhelper`. |
| `build-debs-in-docker.sh` | the same build inside a Debian trixie container, for machines where `debhelper` cannot be installed (no sudo). Hands the output back to your user so publishing works afterwards. |
| `lint.sh` | the CI checks: shell and Python syntax, systemd unit validity, XML/JSON/gettext validity, packaging metadata, and that nothing has drifted back to `/usr/local`. |
| `update-pot.sh` | regenerates the gettext template from the source strings. |
| `eval-assistant.py` | scores the assistant's behaviour -- tool routing, grounding in the reviewed content, arithmetic, honesty about unverified facts, declined actions, formatting -- against a fixed set of questions, using the app's own prompt, tool schemas, round loop and renderer. Run it before and after any change to the prompt, the tools, or the model, and compare with `--baseline`. Also reports the size and cold cost of the fixed prompt prefix. |
| `eval-translation.py` | scores a candidate model's Bislama/Fijian translation against the reviewed catalogs. Exists because two models in a row produced plausible-looking wrong-language output; the header records their baseline scores. Run before ever re-adding translation features. |
| `sync-docs-version.sh` | rewrites the release version in the published docs to match `debian/changelog`. Run it after bumping the version — `lint.sh` fails if the two disagree, because a stale filename on the download page means the checksum command users copy would fail for all of them. |
| `apt-repo/` | the signed package archive installed machines update from — key handling, archive metadata config, and the publish script. See [its README](apt-repo/README.md). |
| `moet-pack/` | permission-gated tooling for the MoET curriculum pack. Ships nothing until written permission exists — see [its README](moet-pack/README.md). |

## The usual loop

```sh
./scripts/lint.sh                       # fast, run this first
./scripts/build-debs.sh                 # produces dist/*.deb
cp dist/*.deb config/config/packages.chroot/
cd config && sudo lb build              # the ISO
```

Without sudo, swap the second line for `./scripts/build-debs-in-docker.sh`.

Publishing a fix to machines that are already installed does not involve the
ISO at all:

```sh
./scripts/build-debs.sh
R2_ACCOUNT_ID=<account-id> ./scripts/apt-repo/publish.sh
```
