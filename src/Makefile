install:
	install -d							$(DESTDIR)/etc/puppet
	cp -r $(CURDIR)/manifests			$(DESTDIR)/etc/puppet/
	cp -r $(CURDIR)/templates			$(DESTDIR)/etc/puppet/
	install -m644 $(CURDIR)/site.pp		$(DESTDIR)/etc/puppet/
