install:
	install -d							$(DESTDIR)/etc/puppet
	cp    $(CURDIR)/modules/puppet/templates/puppet.conf.erb $(DESTDIR)/etc/puppet/puppet.conf
	cp -r $(CURDIR)/manifests			$(DESTDIR)/etc/puppet/
	cp -r $(CURDIR)/modules				$(DESTDIR)/etc/puppet/
