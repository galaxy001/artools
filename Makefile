VERSION=0.24

TOOLS = artools
PREFIX ?= /usr
SYSCONFDIR = /etc
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share

BASE_CONF = \
	data/conf/artools-base.conf

BASE_BIN = \
	bin/base/chroot-run \
	bin/base/mkchroot \
	bin/base/basestrap \
	bin/base/artix-chroot \
	bin/base/fstabgen

BASE_DATA = \
	$(wildcard data/pacman/pacman*.conf)

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
	bin/pkg/batchpkg \
	bin/pkg/signpkg \
	bin/pkg/checkrepo \
	bin/pkg/gitearepo

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
	gnome-unstablepkg \
	rebuildpkg

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

PKG_DATA = \
	data/pacman/makepkg.conf \
	data/valid-names.conf

PATCHES = \
	$(wildcard data/patches/*.patch)

ISO_CONF = \
	data/conf/artools-iso.conf

ISO_BIN = \
	bin/iso/buildiso

LN_BUILDISO = \
	buildiso-gremlins \
	buildiso-goblins

DIRMODE = -dm0755
FILEMODE = -m0644
MODE =  -m0755
LN = ln -sf
RM = rm -f
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

BIN = $(BASE_BIN) $(PKG_BIN) $(ISO_BIN)

all: $(BIN)

EDIT = sed -e "s|@datadir[@]|$(DATADIR)|g" \
	-e "s|@sysconfdir[@]|$(SYSCONFDIR)|g"

%: %.in Makefile lib/util-base.sh
	@echo "GEN $@"
	@$(RM) "$@"
	@{ echo -n 'm4_changequote([[[,]]])'; cat $@.in; } | $(M4) | $(EDIT) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"
	@bash -O extglob -n "$@"

clean:
	$(RM) $(BIN)

install_base:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(BASE_CONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BASE_BIN) $(DESTDIR)$(BINDIR)

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

	$(LN) artix-chroot $(DESTDIR)$(BINDIR)/artools-chroot

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(PKG_DATA) $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
	install $(FILEMODE) $(PATCHES) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches

install_iso:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(ISO_CONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(ISO_BIN) $(DESTDIR)$(BINDIR)

	for l in $(LN_BUILDISO); do $(LN) buildiso $(DESTDIR)$(BINDIR)/$$l; done

install: install_base install_pkg install_iso

.PHONY: all clean install install_base install_pkg install_iso
