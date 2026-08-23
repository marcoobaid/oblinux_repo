# AGENTS.md — oblinux_repo operating guide

Repository-specific guide. For the broader OBLinux project (the ISO
profile, package-sourcing strategy, signing infrastructure in full) see
the primary repository's
[`AGENTS.md`](https://github.com/marcoobaid/oblinux/blob/main/AGENTS.md)
and `docs/PACKAGE_SIGNING.md`/`docs/CUSTOM_REPO.md` — this file only
covers what's specific to working in *this* repository.

## Repository purpose

This repository **is** a live pacman repository, served as static files
via GitHub Pages at `https://marcoobaid.github.io/oblinux_repo/x86_64`.
It exists to host prebuilt packages the OBLinux distribution needs that
aren't in the official Arch repos — currently AUR-only tools (`calamares`,
`paru`, `ckbcomp`) and one OBLinux-maintained package
(`oblinux-icon-theme`). It owns nothing about *how* those packages are
built (that's each package's own repo/PKGBUILD) — only their **published,
signed, installable form** and the repo database that makes them
resolvable by pacman.

## Relationship to OBLinux

- **Consumer**: the primary `oblinux` repo's `pacman.conf` (build-time)
  and `airootfs/etc/pacman.conf` (live/installed system) both declare an
  `[oblinux_repo]` section pointing at this repo's GitHub Pages URL, with
  `SigLevel = Required TrustedOnly`. `mkarchiso`'s `pacstrap` resolves
  `calamares`/`paru`/`ckbcomp`/`oblinux-icon-theme` from here, exactly
  like any package from `core`/`extra`.
- **Hard build-order dependency**: a package must already be built,
  signed, and pushed here **before** an `oblinux` ISO build that
  references it — `pacstrap` fails outright otherwise. This repo cannot
  be updated *by* an `oblinux` build; it's always a prerequisite step.
- **Producers**: packages arrive here from two kinds of sources — plain
  AUR packages (`calamares`, `paru`, `ckbcomp` — built directly from the
  AUR, no separate OBLinux repo for them) and OBLinux's own package repos
  (currently only `oblinux-icon-theme`). This repo does not track or
  vendor either kind's source, only the built `.pkg.tar.zst` output.
- **Trust propagation**: the public half of this repo's signing key
  (`D0514F69650F2B9725E12E26297CB74B36C93A92`) is committed in the
  primary repo at `airootfs/usr/share/pacman/keyrings/oblinux-repo.gpg`
  and imported there at build/live-boot/install time. **The private key
  is never in any repo** — it lives only in the build machine's own GPG
  keyring. See `docs/PACKAGE_SIGNING.md` in the primary repo for the full
  key lifecycle.

## Repository map

```
x86_64/                        The entire served repository — everything
                                pacman actually fetches lives here.
x86_64/*.pkg.tar.zst            Published packages.
x86_64/*.pkg.tar.zst.sig        Detached signature per package (pacman
                                fetches and checks this separately from
                                the database signature).
x86_64/oblinux_repo.db.tar.gz   The repo database (real file) --
                                oblinux_repo.db is a symlink to it,
                                created by repo-add. Both + .sig required.
x86_64/oblinux_repo.files.tar.gz / .files
                                File-list database (used by `pacman -F`)
                                -- same symlink pattern.
x86_64/update_repo.sh           The only script here -- signs unsigned
                                packages, regenerates+signs both database
                                archives. See Architecture below.
.nojekyll                       Tells GitHub Pages not to run Jekyll --
                                required, see Known Pitfalls.
```

**Note on git history**: this repository's git log predates the current
OBLinux rebuild and contains a long tail of unrelated legacy commits
(an old `oblinux-calamares-config` package, `yay-bin`, `oh-my-bash`,
etc.). None of that reflects current practice — the current, active
content is exactly what's in `x86_64/` today. Don't take old commit
messages as guidance for current workflow.

## Architecture and workflow

This repo has no build step of its own — it only signs and indexes
packages built elsewhere:

```bash
cd x86_64/
./update_repo.sh
```

What `update_repo.sh` actually does (read it before assuming — it's
short): removes the old database files, `gpg --detach-sign`s any
`*.pkg.tar.zst` that doesn't already have a valid `.sig` (using
`$OBLINUX_REPO_KEYID`, defaulting to this project's real key ID baked
into the script), then runs `repo-add -s -k <key> -n -R --include-sigs`
to rebuild `oblinux_repo.db.tar.gz` (and `.files.tar.gz`) signed, from
**every** `.pkg.tar.zst` currently present in the directory. This means:
old package versions left in `x86_64/` stay published and indexed — remove
them first if they shouldn't be.

Publishing is just `git add`/`commit`/`push` of `x86_64/` — GitHub Pages
serves whatever's on the default branch directly, no separate deploy
step.

## Authoritative vs. generated files

| Generated by `update_repo.sh` (don't hand-edit) | Source of truth |
|---|---|
| `oblinux_repo.db`, `oblinux_repo.db.tar.gz`, `.sig` | Whatever `.pkg.tar.zst` files are present when the script runs |
| `oblinux_repo.files`, `oblinux_repo.files.tar.gz`, `.sig` | Same |
| `*.pkg.tar.zst.sig` | The corresponding `.pkg.tar.zst` + the signing key |

`*.pkg.tar.zst` files themselves are authoritative *here* (this is their
canonical published location) but are generated artifacts *relative to*
their owning repo (the AUR package, or `oblinux-icon-theme`'s
`PKGBUILD`) — never hand-patch a package file in place; rebuild it from
its real source and republish.

## Common development tasks

- **Publish a new/updated package**: copy the built `.pkg.tar.zst` into
  `x86_64/`, remove any old version of the same package you don't want
  still served, run `./update_repo.sh`, commit and push `x86_64/`.
- **Re-sign after a signing-key change**: delete the stale `.sig` files
  and rerun `update_repo.sh` — it only (re)signs packages lacking a valid
  signature.
- **Verify what's actually published** (more reliable than reading
  `README.md`'s prose list, which can lag — see Known Pitfalls):
  `tar -tzf x86_64/oblinux_repo.db.tar.gz` lists every indexed package.

## Cross-repository change workflow

1. Build the package in its owning location: an AUR clone (`calamares`,
   `paru`, `ckbcomp`) or the relevant OBLinux package repo (e.g.
   `oblinux-icon-theme`).
2. Copy the resulting `.pkg.tar.zst` into this repo's `x86_64/`.
3. Run `x86_64/update_repo.sh` here (needs the OBLinux signing key in the
   calling user's GPG keyring).
4. Commit and push — this *is* the publish step, via GitHub Pages.
5. Only now is the package resolvable by any system pointed at this repo.
   A pending `oblinux` ISO build can proceed; an already-installed system
   picks it up on its next `pacman -Syu`.
6. No changes are ever needed in this repo as a *result* of an `oblinux`
   build — the dependency only flows this direction.

## Validation

- **Script ran successfully**: `update_repo.sh` exits 0 and
  `x86_64/oblinux_repo.db`/`.files` are non-dangling symlinks pointing at
  freshly-timestamped `.tar.gz` files.
- **Signatures valid**: `gpg --verify x86_64/<pkg>.pkg.tar.zst.sig
  x86_64/<pkg>.pkg.tar.zst` (and same for the two database archives).
- **Actually resolvable**: after pushing, `pacman -Sy` on a system with
  `[oblinux_repo]` configured should see the new/updated package with no
  signature errors — this requires the consuming system to already trust
  this repo's public key (`pacman-key --add` + `--lsign-key`, see
  `docs/PACKAGE_SIGNING.md`). A signature failure on a *build machine*
  specifically often means that machine's own local trust step (not this
  repo's config) hasn't been done — see that doc before assuming this
  repo is broken.
- **Full integration** (does an `oblinux` ISO actually build and install
  correctly with the new package): only provable in the primary `oblinux`
  repo's own build/boot/install cycle, not here.

## Important architectural decisions

- **A real GitHub Pages static file store, not a build server** — this
  repo never runs `makepkg`. Keeping "build" and "publish" strictly
  separate means this repo's history stays small and its content is
  always exactly what pacman fetches, nothing more.
- **Signing lives in `update_repo.sh`, not a separate CI step** — no
  GitHub Actions/CI exists here; publishing is a manual, local action by
  whoever holds the signing key. Don't assume a push alone re-signs
  anything.
- **The private signing key is never committed anywhere** — only the
  public key (`oblinux-repo.gpg`, and the same content lives in the
  primary repo's `airootfs/`) is ever checked into git.

## Known pitfalls and lessons learned

- **Symptom**: GitHub Pages build fails outright with a Ruby/Jekyll error
  referencing `oblinux_repo.db`. **Cause**: Jekyll tries to resolve the
  real path of every file including symlinks, and errors if
  `oblinux_repo.db`/`.files` are dangling (pointing at a `.tar.gz` that
  doesn't exist — e.g. right after removing all packages). **Correct
  approach**: `.nojekyll` must stay present so Pages serves the directory
  as-is without a Jekyll build at all; if the symlinks are ever genuinely
  dangling, either remove them (repo intentionally empty) or rerun
  `update_repo.sh` with real packages present.
- **Symptom**: this repo's own `README.md` "Packages currently published"
  list undercounts what's actually indexed (found during this file's own
  creation: it lists 3 packages, `oblinux_repo.db.tar.gz` actually
  contains 4, including `oblinux-icon-theme`). **Cause**: that section is
  prose, updated by hand, and lags real publishes. **Correct approach**:
  treat `tar -tzf x86_64/oblinux_repo.db.tar.gz` as the source of truth
  for what's published, not the README's prose list — and update that
  section when publishing, since it's easy to forget.
- **Symptom**: `pacstrap` fails to resolve an `oblinux_repo` package with
  a signature error, even though it's clearly present in `x86_64/`.
  **Cause**: `pacstrap` checks signatures against the **build machine's
  own** pacman keyring, which is entirely separate from anything in this
  repo or the primary repo's `airootfs/`. **Correct approach**: the build
  machine needs a one-time `pacman-key --add`/`--lsign-key` for this
  repo's public key — see `docs/PACKAGE_SIGNING.md` in the primary repo.
  Don't assume this repo's config is broken; check build-machine trust
  first.

## Development rules

- Read `update_repo.sh` before assuming what a publish step does — it's
  short enough to verify directly rather than guess.
- Never commit a private key, passphrase, or anything from `~/.gnupg` —
  only the public `oblinux-repo.gpg` belongs in a repo, and it's already
  mirrored in the primary repo; don't re-add it here redundantly without
  reason.
- Remove superseded package versions from `x86_64/` when publishing a
  replacement, unless there's a deliberate reason to keep serving both.
- Don't hand-edit `oblinux_repo.db`/`.files` or their `.tar.gz` archives
  — always regenerate via `update_repo.sh`.
- Keep `README.md`'s published-package list in sync when you publish —
  it's the one piece of hand-maintained prose in this repo and it has
  already been found stale once.
- Ignore this repo's pre-rebuild git history as a source of current
  practice (see Repository Map's note).

## Start-of-task workflow

1. Read this file.
2. Check `git status`, and confirm the local clone isn't behind
   `origin` — this repo is a publish target other sessions/machines push
   to directly, and a stale local clone can look like a missing package
   that's actually already published.
3. Check `tar -tzf x86_64/oblinux_repo.db.tar.gz` for what's actually
   currently published, rather than trusting `README.md` alone.
4. Confirm the requested change belongs here (publishing/signing) and not
   in the package's own owning repo (its actual source/build) or the
   primary `oblinux` repo (how it's consumed).
5. Make the smallest complete change; run `update_repo.sh` if packages
   changed.
6. Validate per the section above before considering the change done.
7. State plainly whether the primary `oblinux` repo needs a rebuild to
   pick this up, and whether that's been tested.
8. Summarize what changed and what still needs verification.

## Maintaining this file

Update this file when a change materially affects: what this repository
publishes or how, the signing workflow, trust propagation to consumers,
or a lesson future agents need to avoid repeating (e.g. a new Pages/
Jekyll gotcha, a new class of signature failure). Don't update it for
routine package publishes that don't change the mechanism. Remove stale
content rather than letting it accumulate — this repo's own git history
is a cautionary example of what happens when that doesn't happen.
