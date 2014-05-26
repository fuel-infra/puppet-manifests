install:
	install -d							$(DESTDIR)/usr/share/config-puppet-manifests
	cp    $(CURDIR)/modules/puppet/templates/puppet.conf.erb $(DESTDIR)/usr/share/config-puppet-manifests/puppet.conf
	cp -r $(CURDIR)/manifests			$(DESTDIR)/usr/share/config-puppet-manifests/
	cp -r $(CURDIR)/modules				$(DESTDIR)/usr/share/config-puppet-manifests/
