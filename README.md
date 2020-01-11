# oblinux Repo

### Changes to packages

local and dconf have been moved into there indavidual packages for xfce.

gimp, conky and root has been moved into there own packages.



Packages
------


* betterlockscreen-git
------


Instructions
------

edit your `/etc/pacman.conf` and at the bottom of your file add block below.

```
	[oblinux_repo]
	SigLevel = Optional TrustedOnly 
	Server = https://marcoobaid.github.io/$repo/$arch

```
