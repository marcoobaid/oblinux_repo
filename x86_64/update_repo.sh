#!/bin/bash
# Rebuilds oblinux_repo.db.tar.gz (and .files.tar.gz) from whatever
# .pkg.tar.zst files are present in this directory, signing both the
# packages and the database.
#
# Key: OBLinux Repo Signing Key <repo@oblinux.local>, ed25519, generated
# 2026-08-12. Full generation steps, backup locations, and how trust gets
# baked into the ISO: docs/PACKAGE_SIGNING.md in the `oblinux` repo. The
# private key lives only on the build machine (~/.gnupg) — this script
# assumes it's already present in the calling user's GPG keyring.
set -e

KEYID="${OBLINUX_REPO_KEYID:-D0514F69650F2B9725E12E26297CB74B36C93A92}"

echo "Clean out old db"
echo

rm -f oblinux_repo.db* oblinux_repo.files*

echo "Signing packages (skipping any that already have a valid .sig)"
echo

for pkg in *.pkg.tar.zst; do
    [ -f "$pkg" ] || continue
    sig="$pkg.sig"
    if [ ! -f "$sig" ] || [ "$pkg" -nt "$sig" ]; then
        rm -f "$sig"
        gpg --detach-sign --local-user "$KEYID" "$pkg"
    fi
done

echo
echo "Run repo-add"
echo
repo-add -s -k "$KEYID" -n -R --include-sigs oblinux_repo.db.tar.gz *.pkg.tar.zst
sleep 5

echo "####################################"
echo "Repo Updated!!"
echo "####################################"
