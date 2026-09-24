# oblinux_repo

OBLinux's own pacman repository, hosted via GitHub Pages at
`https://marcoobaid.github.io/oblinux_repo/x86_64`. It exists for packages
that aren't in the official Arch repos — starting with `calamares`,
`paru`, and `ckbcomp`, all AUR-only — plus any future custom OBLinux
packages.

## Using this repo

Add to `/etc/pacman.conf` (also already wired into the
[`oblinux-arch-iso-dev`](https://github.com/marcoobaid/oblinux-arch-iso-dev) ISO profile,
both at build time and on the live/installed system):

```
[oblinux_repo]
SigLevel = Required TrustedOnly
Server = https://marcoobaid.github.io/$repo/$arch
```

Packages and repository databases are **signed**. The active Ed25519
fingerprint after the September 2026 rotation is:
`F83C29998D979B913298C40E7E0180391C821D13`.
The previous private key became unavailable after the build-machine rebuild.
All four packages and both databases have already been re-signed and pushed.
The new portable private-key export and revocation certificate were backed
up off-machine (owner-confirmed); neither secrets nor backup locations
belong in Git. A portable secret-key export is a required recovery artifact.

Full key history, required backups, trust propagation, and the proposed
migration for old installations are documented in
[`docs/PACKAGE_SIGNING.md`](https://github.com/marcoobaid/oblinux-arch-iso-dev/blob/main/docs/PACKAGE_SIGNING.md).
A consumer must authenticate the public key's full fingerprint through a
trusted project channel before importing and locally trusting it:

```bash
# Public key from the reviewed ISO profile's airootfs/usr/share/pacman/keyrings/
gpg --show-keys --with-fingerprint oblinux-repo.gpg
# Proceed only after independently confirming the full fingerprint above.
sudo pacman-key --add oblinux-repo.gpg
sudo pacman-key --lsign-key F83C29998D979B913298C40E7E0180391C821D13
```

Installations from the previously published ISO still trusting only the
old OBLinux key cannot verify the newly signed database or packages.
The ISO overlay has no automatic OBLinux keyring update mechanism; those
systems need a separately approved, authenticated manual trust migration.
A package signed only by the new key cannot bootstrap that trust itself.
Keep `SigLevel = Required TrustedOnly`; do not disable signature checking.

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
This signs packages with a missing `.sig` or a `.sig` older than the
package (needs the OBLinux signing key present in the calling user's GPG keyring — see
`docs/PACKAGE_SIGNING.md` in `oblinux-arch-iso-dev`), then regenerates the
repo database, signed, from *all* packages currently in `x86_64/` — old
versions of a package should be removed from that directory first if you
don't want them still served. `repo-add` also (re)creates
`oblinux_repo.db`/`oblinux_repo.files` as symlinks pointing at the
`.tar.gz` archives — these are build output, not something to hand-edit or
commit independently of running `update_repo.sh`.

The script defaults to the active fingerprint above; `OBLINUX_REPO_KEYID`
can override it. Existing signatures are not cryptographically checked by
the skip logic: verify every package and both database signatures explicitly
after a publish or rotation.

Commit and push `x86_64/` (packages + the regenerated `.db`/`.files`
archives) to publish via GitHub Pages.

## Packages currently published

- `calamares-3.4.2-2` — installer framework, from AUR (not in official repos)
- `paru-2.1.0-2` — AUR helper, from AUR (not in official repos)
- `ckbcomp-1.248-1` — keyboard-layout live-preview helper for Calamares'
  keyboard module, from AUR (not in official repos)
- `oblinux-icon-theme-2.0.0-1` — OBLinux's default icon theme, from
  [`oblinux-icon-theme`](https://github.com/marcoobaid/oblinux-icon-theme)

All four are signed (`SigLevel = Required TrustedOnly`). Don't trust this
list alone for what's actually published, though — check
`tar -tzf x86_64/oblinux_repo.db.tar.gz` against it, since it's
hand-maintained prose and can lag a real publish.

Verified working end to end: built, published, served correctly via GitHub
Pages, and confirmed resolving on a built/booted `oblinux` system (`paru`
itself reports `oblinux_repo is up to date` alongside `core`/`extra`). See
[`oblinux`](https://github.com/marcoobaid/oblinux)'s `docs/TESTING.md`,
round 7.

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
