artools
=============

#### Make flags


* PREFIX=/usr
* SYSCONFDIR=/etc

#### Dependencies

##### Buildtime:

* make
* git
* m4

##### Runtime:

- base:
  * openssh
  * rsync
  * haveged
  * os-prober
  * gnupg
  * pacman

- pkg:
  * namcap
  * git-subrepo
  * jq

- iso:
  * dosfstools
  * libisoburn
  * squashfs-tools
  * mkinitcpio
  * grub

#### Configuration

artools-{base,pkg,iso}.conf are the configuration files for artools.
By default, the config files are installed in

```bash
/etc/artools/artools-{base,pkg,iso}.conf
```

A user artools-{base,pkg,iso}.conf can be placed in

```bash
$HOME/.config/artools/artools-{base,pkg,iso}.conf
```

If the userconfig is present, artools will load the userconfig values, however, if variables have been set in the systemwide

These values take precedence over the userconfig.
Best practise is to leave systemwide file untouched.
By default it is commented and shows just initialization values done in code.

Tools configuration is done in artools-{base,pkg,iso}.conf or by args.
Specifying args will override artools-{base,pkg,iso}.conf settings.

Both, pacman.conf and makepkg.conf for chroots are loaded from

```bash
usr/share/artools/{makepkg,pacman-*}.conf
```

and can be overridden dropping them in

```bash
$HOME/.config/artools/
```
