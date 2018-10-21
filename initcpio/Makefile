DIRMODE = -dm0755
MODE =  -m0755

CPIOHOOKS = \
	$(wildcard hooks/*)

CPIOINST = \
	$(wildcard install/*)

SCRIPT = \
	$(wildcard script/*)

install_initcpio:
	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/hooks
	install $(MODE) $(CPIOHOOKS) $(DESTDIR)$(CPIODIR)/hooks

	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(CPIOINST) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(SCRIPT) $(DESTDIR)$(CPIODIR)

install: install_initcpio

.PHONY: install
