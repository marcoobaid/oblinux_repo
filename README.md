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
first if you don't want them still served. `repo-add` also (re)creates
`oblinux_repo.db`/`oblinux_repo.files` as symlinks pointing at the
`.tar.gz` archives — these are build output, not something to hand-edit or
commit independently of running `update_repo.sh`.

Commit and push `x86_64/` (packages + the regenerated `.db`/`.files`
archives) to publish via GitHub Pages.

## Packages currently published

**None yet** — this repo was cleaned out of old/stale builds and is
waiting on `calamares` and `paru` to be built and published (see above).
Until then, anything depending on `[oblinux_repo]` (e.g. the `oblinux` ISO
build) will fail to resolve those packages.

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
