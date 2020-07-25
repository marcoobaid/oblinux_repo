# OBLinux Repo

### Changes to Packages

local and dconf have been moved into there indavidual packages for xfce.

gimp, conky and root has been moved into there own packages.



Packages
------


* calamares 
* oh-my-bash

------


Instructions
------

Edit your `/etc/pacman.conf` and add the block below at the bottom of your file:

```
	[oblinux_repo]
	SigLevel = Optional TrustedOnly 
	Server = https://marcoobaid.github.io/$repo/$arch

```
