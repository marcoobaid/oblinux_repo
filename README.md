# oblinux_repo

OBLinux's own pacman repository, hosted via GitHub Pages at
`https://marcoobaid.github.io/oblinux_repo/x86_64`. It exists for packages
that aren't in the official Arch repos — starting with `calamares`,
`paru`, and `ckbcomp`, all AUR-only — plus any future custom OBLinux
packages.

## Using this repo

Add to `/etc/pacman.conf` (also already wired into the
[`oblinux`](https://github.com/marcoobaid/oblinux) ISO profile, both at
build time and on the live/installed system):

```
[oblinux_repo]
SigLevel = Required TrustedOnly
Server = https://marcoobaid.github.io/$repo/$arch
```

Packages are **signed** as of 2026-08-12 (ed25519 key,
`D0514F69650F2B9725E12E26297CB74B36C93A92`). Full details — key
generation, backups, the signing workflow, and how trust gets baked into
the `oblinux` ISO — in that repo's
[`docs/PACKAGE_SIGNING.md`](https://github.com/marcoobaid/oblinux/blob/main/docs/PACKAGE_SIGNING.md).
A system consuming this repo needs the signing key trusted locally before
`SigLevel = Required` will work:

```bash
sudo pacman-key --add oblinux-repo.gpg   # the public key, from that repo's airootfs
sudo pacman-key --lsign-key D0514F69650F2B9725E12E26297CB74B36C93A92
```

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
./update_repo.sh    # signs each package, rebuilds+signs oblinux_repo.db.tar.gz
```
This signs any package that doesn't already have a valid `.sig` (needs
the OBLinux signing key present in the calling user's GPG keyring — see
`docs/PACKAGE_SIGNING.md` in the `oblinux` repo), then regenerates the
repo database, signed, from *all* packages currently in `x86_64/` — old
versions of a package should be removed from that directory first if you
don't want them still served. `repo-add` also (re)creates
`oblinux_repo.db`/`oblinux_repo.files` as symlinks pointing at the
`.tar.gz` archives — these are build output, not something to hand-edit or
commit independently of running `update_repo.sh`.

Commit and push `x86_64/` (packages + the regenerated `.db`/`.files`
archives) to publish via GitHub Pages.

## Packages currently published

- `calamares-3.4.2-2` — installer framework, from AUR (not in official repos)
- `paru-2.1.0-2` — AUR helper, from AUR (not in official repos)
- `ckbcomp-1.248-1` — keyboard-layout live-preview helper for Calamares'
  keyboard module, from AUR (not in official repos)

Verified working end to end: built, published, served correctly via GitHub
Pages, and confirmed resolving on a built/booted `oblinux` system (`paru`
itself reports `oblinux_repo is up to date` alongside `core`/`extra`). See
[`oblinux`](https://github.com/marcoobaid/oblinux)'s `docs/TESTING.md`,
round 7.

**Transitional note (2026-08-12)**: all three packages above were built
and published *before* the signing key existed, so they don't have `.sig`
files yet — `SigLevel` was just switched to `Required`, so `./update_repo.sh`
needs to run once (on a machine with the signing key) to sign and
republish them before the next `oblinux` build, or `pacstrap` will fail to
resolve them.

## Gotchas

- **`.nojekyll`**: this repo is a package store, not a Jekyll site, so
  GitHub Pages is told not to run it through Jekyll's build. Without this
  file, Jekyll's build previously failed outright on the `oblinux_repo.db`
  symlink (`Error: No such file or directory ... rb_check_realpath_internal`)
  when its target didn't exist yet (e.g. right after a cleanup, before any
  package had been published) — Jekyll tries to resolve every file's real
  path, including symlinks, and errors on a dangling one. Do not remove
  `.nojekyll`.
- If `x86_64/oblinux_repo.db` or `.files` ever end up as **dangling
  symlinks** (pointing at a `.tar.gz` that doesn't exist — e.g. after
  deleting old packages without also removing/regenerating these), the
  fix is to either remove them (if the repo is meant to be empty for now)
  or run `update_repo.sh` again (if packages exist to regenerate them
  from).
