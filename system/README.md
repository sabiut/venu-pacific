# system/

System-level files that make an installed machine a Venu Pacific machine:
the update notifier, session defaults, login branding, systemd units, and the
menu entries for things that have no source directory of their own.

Laid out by role rather than by final path. `debian/rules` decides where each
piece lands:

```
bin/            -> /usr/bin          programs run by the desktop session
sbin/           -> /usr/sbin         root-only (the apt index refresh)
systemd/system/ -> /usr/lib/systemd/system
systemd/user/   -> /usr/lib/systemd/user
applications/   -> /usr/share/applications      menu entries
autostart/      -> /etc/xdg/autostart           session startup
skel/           -> /etc/skel                    defaults for new accounts
help/           -> /usr/share/venu-pacific/help
calamares/      -> /etc/calamares/branding/venu-pacific
etc/            -> installed by postinst, not shipped as files (see below)
```

Nothing here goes to `/usr/local`. Debian policy reserves that directory for
the local administrator, and a package may not own a file there — which means
anything installed to `/usr/local` can never be upgraded by apt. That was the
old arrangement and it is what
[scripts/apt-repo/README.md](../scripts/apt-repo/README.md) exists to
explain. `scripts/lint.sh` fails the build if a `/usr/local` path comes back.

`etc/issue` and `etc/issue.net` are the exception to the table above. Both
belong to `base-files`, and dpkg refuses to let a second package own the same
path, so they ship as templates under `/usr/share/venu-pacific/` and
`venu-pacific-settings`'s postinst installs them over the stock banner —
keeping one backup, restored on purge, and leaving the file alone if an
administrator has edited it since.

## Which package gets what

| Package | From here |
|---|---|
| `venu-pacific-settings` | `bin/venu-pacific-{set-defaults,light-locker-guard,notify-updates}`, `sbin/`, `systemd/system/`, `systemd/user/venu-pacific-notify-updates.*`, `autostart/`, `skel/`, `etc/` |
| `venu-pacific-apps` | `bin/venu-pacific-kolibri`, `applications/` (except the assistant), `help/` |
| `venu-pacific-assistant` | `systemd/user/venu-pacific-llama*.service` |
| `venu-pacific-branding` | `calamares/branding.desc` |

The installer's own menu entry is not here. `calamares-install-debian.desktop`
lives in `config/config/includes.chroot/` because it is only meaningful in
the live session, where Calamares actually exists.
