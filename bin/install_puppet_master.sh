#!/bin/sh

set -xe

apt-get update
apt-get upgrade -y
apt-get install -y git puppet

/etc/puppet/bin/install_modules.sh

FACTER_PUPPET_APPLY=true puppet apply -vd /etc/puppet/manifests/site.pp
puppet agent --enable
puppet agent -vd --no-daemonize --onetime
