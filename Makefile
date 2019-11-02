VERSION=0.15

CHROOT_VERSION=0.10

TOOLS = artools
PREFIX ?= /usr
SYSCONFDIR = /etc
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib
DATADIR = $(PREFIX)/share
CPIODIR = $(SYSCONFDIR)/initcpio

BASE_CONF = \
	data/conf/artools-base.conf

BASE_BIN = \
	bin/base/signfile \
	bin/base/chroot-run \
	bin/base/mkchroot \
	bin/base/basestrap \
	bin/base/artools-chroot \
	bin/base/fstabgen

BASE_LIBS = \
	$(wildcard lib/base/*.sh)

BASE_UTIL = lib/util-base.sh

BASE_DATA = \
	$(wildcard data/base/pacman*.conf)

PKG_CONF = \
	data/conf/artools-pkg.conf

PKG_BIN = \
	bin/pkg/buildpkg \
	bin/pkg/deploypkg \
	bin/pkg/commitpkg \
	bin/pkg/comparepkg \
	bin/pkg/mkchrootpkg \
	bin/pkg/pkg2yaml \
	bin/pkg/buildtree \
	bin/pkg/lddd \
	bin/pkg/links-add \
	bin/pkg/checkpkg \
	bin/pkg/finddeps \
	bin/pkg/find-libdeps \
	bin/pkg/batchpkg

LN_COMMITPKG = \
	extrapkg \
	corepkg \
	testingpkg \
	stagingpkg \
	communitypkg \
	community-testingpkg \
	community-stagingpkg \
	multilibpkg \
	multilib-testingpkg \
	multilib-stagingpkg \
	kde-unstablepkg \
	gnome-unstablepkg

LN_BUILDPKG = \
	buildpkg-system \
	buildpkg-world \
	buildpkg-gremlins \
	buildpkg-goblins \
	buildpkg-galaxy \
	buildpkg-galaxy-gremlins \
	buildpkg-galaxy-goblins \
	buildpkg-lib32 \
	buildpkg-lib32-gremlins \
	buildpkg-lib32-goblins \
	buildpkg-kde-wobble \
	buildpkg-gnome-wobble

LN_DEPLOYPKG = \
	deploypkg-system \
	deploypkg-world \
	deploypkg-gremlins \
	deploypkg-goblins \
	deploypkg-galaxy \
	deploypkg-galaxy-gremlins \
	deploypkg-galaxy-goblins \
	deploypkg-lib32 \
	deploypkg-lib32-gremlins \
	deploypkg-lib32-goblins \
	deploypkg-kde-wobble \
	deploypkg-gnome-wobble

PKG_LIBS = \
	$(wildcard lib/pkg/*)

PKG_UTIL = lib/util-pkg.sh

PKG_DATA = \
	data/pkg/makepkg.conf

PATCHES = \
	$(wildcard data/patches/*.patch)

ISO_CONF = \
	data/conf/artools-iso.conf

ISO_BIN = \
	bin/iso/buildiso \
	bin/iso/deployiso

LN_BUILDISO = \
	buildiso-gremlins \
	buildiso-goblins

ISO_LIBS = \
	$(wildcard lib/iso/*.sh)

ISO_UTIL = lib/util-iso.sh

ISO_DATA = \
	data/iso/mkinitcpio.conf

DIRMODE = -dm0755
FILEMODE = -m0644
MODE =  -m0755
LN = ln -sf
RM = rm -f
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

BIN = $(BASE_BIN) $(PKG_BIN) $(ISO_BIN)
UTIL = $(BASE_UTIL) $(PKG_UTIL) $(ISO_UTIL)

all: $(BIN) $(UTIL)

EDIT_UTIL = sed -e "s|@datadir[@]|$(DATADIR)|g" \
	-e "s|@sysconfdir[@]|$(SYSCONFDIR)|g" \
	-e "s|@libdir[@]|$(LIBDIR)|g" \
	-e "s|@chroot_version@|$(CHROOT_VERSION)|"

EDIT_BIN = sed -e "s|@libdir[@]|$(LIBDIR)|g"

$(UTIL): %: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT_UTIL) >$@
	@$(CHMODAW) "$@"

$(BIN): %: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT_BIN) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"

clean:
	$(RM) $(BIN) $(UTIL)

install_base:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(BASE_CONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BASE_BIN) $(DESTDIR)$(BINDIR)

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)/base
	install $(FILEMODE) $(BASE_UTIL) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(BASE_LIBS) $(DESTDIR)$(LIBDIR)/$(TOOLS)/base

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(BASE_DATA) $(DESTDIR)$(DATADIR)/$(TOOLS)

install_pkg:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(PKG_CONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(PKG_BIN) $(DESTDIR)$(BINDIR)

	$(LN) find-libdeps $(DESTDIR)$(BINDIR)/find-libprovides

	$(LN) links-add $(DESTDIR)$(BINDIR)/links-remove

	for l in $(LN_COMMITPKG); do $(LN) commitpkg $(DESTDIR)$(BINDIR)/$$l; done
	for l in $(LN_BUILDPKG); do $(LN) buildpkg $(DESTDIR)$(BINDIR)/$$l; done
	for l in $(LN_DEPLOYPKG); do $(LN) deploypkg $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)/pkg
	install $(FILEMODE) $(PKG_UTIL) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(PKG_LIBS) $(DESTDIR)$(LIBDIR)/$(TOOLS)/pkg

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(PKG_DATA) $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
	install $(FILEMODE) $(PATCHES) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches

install_cpio:
	+make CPIODIR=$(CPIODIR) DESTDIR=$(DESTDIR) -C initcpio install

install_iso: install_cpio
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(ISO_CONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(ISO_BIN) $(DESTDIR)$(BINDIR)

	for l in $(LN_BUILDISO); do $(LN) buildiso $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)/iso
	install $(FILEMODE) $(ISO_UTIL) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(ISO_LIBS) $(DESTDIR)$(LIBDIR)/$(TOOLS)/iso

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(ISO_DATA) $(DESTDIR)$(DATADIR)/$(TOOLS)

install: install_base install_pkg install_iso

.PHONY: all clean install install_base install_pkg install_iso
