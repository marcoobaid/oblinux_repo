# oblinux_repo

OBLinux's own pacman repository, hosted via GitHub Pages at
`https://marcoobaid.github.io/oblinux_repo/x86_64`. It exists for packages
that aren't in the official Arch repos — starting with `calamares` and
`paru`, both AUR-only — plus any future custom OBLinux packages.

## Using this repo

Add to `/etc/pacman.conf` (also already wired into the
[`oblinux`](https://github.com/marcoobaid/oblinux) ISO profile, both at
build time and on the live/installed system):

```
[oblinux_repo]
SigLevel = Optional TrustedOnly
Server = https://marcoobaid.github.io/$repo/$arch
```

Packages are currently **unsigned** (`Optional`). TODO: generate a signing
key and switch to `SigLevel = Required` once one exists — this is a clean
addition later, not something that requires rebuilding the packages
themselves; see `x86_64/update_repo.sh`'s commented-out `-s` flag.

## Publishing a package

Build on an Arch machine with `base-devel` installed. Two cases:

**An AUR package** (e.g. `calamares`, `paru`):
```bash
git clone https://aur.archlinux.org/calamares.git
cd calamares
makepkg -s          # -s: also resolve/install build deps from your own repos
cp *.pkg.tar.zst /path/to/oblinux_repo/x86_64/
```

**A custom OBLinux package**: same idea — write/obtain a `PKGBUILD`,
`makepkg -s`, copy the resulting `.pkg.tar.zst` into `x86_64/`.

Then, from `x86_64/`:
```bash
./update_repo.sh    # rebuilds oblinux_repo.db.tar.gz from whatever .pkg.tar.zst files are present
```
This regenerates the repo database from *all* packages currently in
`x86_64/` — old versions of a package should be removed from that directory
first if you don't want them still served.

Commit and push `x86_64/` (packages + the regenerated `.db`/`.files`
archives) to publish via GitHub Pages.

## Packages currently published

- `calamares` — installer framework, from AUR (not in official repos)
- `paru` — AUR helper, from AUR (not in official repos)
