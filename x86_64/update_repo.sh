#!/bin/bash

echo "Clean out old db"
echo

rm oblinux_repo*

echo
echo "Run repo-add"
echo 
#repo-add -s -n -R oblinux_repo.db.tar.gz *.pkg.tar.zst
repo-add -n -R oblinux_repo.db.tar.gz *.pkg.tar.zst
sleep 5

echo "####################################"
echo "Repo Updated!!"
echo "####################################"
