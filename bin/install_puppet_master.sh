#!/bin/sh

apt-get update
apt-get upgrade -y
apt-get install -y git puppet

/etc/puppet/bin/install_modules.sh

puppet apply -vd --parser=future /etc/puppet/manifests/site.pp
puppet agent --enable
puppet agent -tvd
