#!/bin/bash

echo "Clean out old db"
echo

rm oblinux_repo*

echo
echo "Run repo-add"
echo 

repo-add oblinux_repo.db.tar.gz *.pkg.tar.zst

echo "####################################"
echo "Repo Updated!!"
echo "####################################"
