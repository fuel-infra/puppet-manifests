#!/bin/sh

set -xe

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y git puppet apt-transport-https

/etc/puppet/bin/install_modules.sh

expect_hiera=$(puppet apply -vd --genconfig | awk '/ hiera_config / {print $3}')
if [ ! -f ${expect_hiera} ]; then
    echo "File ${expect_hiera} not found!"
    if [ ! -f /etc/hiera.yaml ]; then
        ln -s /etc/puppet/hiera/hiera-stub.yaml ${expect_hiera}
    else
        echo "Found default /etc/hiera.yaml"
        ln -s /etc/hiera.yaml  ${expect_hiera}
    fi
fi

FACTER_PUPPET_APPLY=true FACTER_ROLE=puppetmaster puppet apply -vd /etc/puppet/manifests/site.pp
puppet agent --enable
puppet agent -vd --no-daemonize --onetime
