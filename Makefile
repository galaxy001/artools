VERSION=0.11

CHROOT_VERSION=0.9

TOOLS = artools
PREFIX ?= /usr/local
SYSCONFDIR = /etc
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib
DATADIR = $(PREFIX)/share
CPIODIR = $(SYSCONFDIR)/initcpio

SYSCONF = \
	data/artools.conf

BIN_BASE = \
	bin/mkchroot \
	bin/basestrap \
	bin/artools-chroot \
	bin/fstabgen \
	bin/signfile \
	bin/chroot-run

LIBS_BASE = \
	lib/util.sh \
	lib/util-msg.sh \
	lib/util-mount.sh \
	lib/util-chroot.sh \
	lib/util-fstab.sh

SHARED_BASE = \
	$(wildcard data/pacman*.conf)

BIN_PKG = \
	bin/checkpkg \
	bin/lddd \
	bin/finddeps \
	bin/find-libdeps \
	bin/mkchrootpkg \
	bin/buildpkg \
	bin/buildtree \
	bin/deploypkg \
	bin/commitpkg \
	bin/pkg2yaml

LIBS_PKG = \
	$(wildcard lib/util-pkg*.sh)

SHARED_PKG = \
	data/makepkg.conf

PATCHES = \
	$(wildcard data/patches/*.patch)

COMMITPKG_SYMS = \
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

BUILDPKG_SYMS = \
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

DEPLOYPKG_SYMS = \
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

BIN_ISO = \
	bin/buildiso \
	bin/deployiso

BUILDISO_SYMS = \
	buildiso-gremlins \
	buildiso-goblins

LIBS_ISO = \
	$(wildcard lib/util-iso*.sh)

SHARED_ISO = \
	data/mkinitcpio.conf

DIRMODE = -dm0755
FILEMODE = -m0644
MODE =  -m0755

LN = ln -sf
RM = rm -f
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

all: $(BIN_BASE) $(BIN_PKG) $(BIN_ISO)

EDIT = sed -e "s|@datadir[@]|$(DATADIR)/$(TOOLS)|g" \
	-e "s|@sysconfdir[@]|$(SYSCONFDIR)/$(TOOLS)|g" \
	-e "s|@libdir[@]|$(LIBDIR)/$(TOOLS)|g" \
	-e "s|@version@|$(VERSION)|" \
	-e "s|@chroot_version@|$(CHROOT_VERSION)|"

%: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"

clean:
	$(RM) $(BIN_BASE) $(BIN_PKG) $(BIN_ISO)

install_base:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(SYSCONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_BASE) $(DESTDIR)$(BINDIR)

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_BASE) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_BASE) $(DESTDIR)$(DATADIR)/$(TOOLS)

install_pkg:
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_PKG) $(DESTDIR)$(BINDIR)

	$(LN) find-libdeps $(DESTDIR)$(BINDIR)/find-libprovides

	for l in $(COMMITPKG_SYMS); do $(LN) commitpkg $(DESTDIR)$(BINDIR)/$$l; done
	for l in $(BUILDPKG_SYMS); do $(LN) buildpkg $(DESTDIR)$(BINDIR)/$$l; done
	for l in $(DEPLOYPKG_SYMS); do $(LN) deploypkg $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_PKG) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_PKG) $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
	install $(FILEMODE) $(PATCHES) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
install_cpio:
	+make CPIODIR=$(CPIODIR) DESTDIR=$(DESTDIR) -C initcpio install

install_iso: install_cpio
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_ISO) $(DESTDIR)$(BINDIR)

	for l in $(BUILDISO_SYMS); do $(LN) buildiso $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_ISO) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_ISO) $(DESTDIR)$(DATADIR)/$(TOOLS)

install: install_base install_pkg install_iso

.PHONY: all clean install
