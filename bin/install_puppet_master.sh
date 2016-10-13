#!/bin/bash

set -xe

export DEBIAN_FRONTEND="noninteractive"
export PUPPET_ETC_DIR="/etc/puppet"
export HIERA_VAR_DIR="/var/lib/hiera"

# check if running it as root
if [[ "$(id -u)" != "0" ]]; then
  echo "Error. This script must be run as root"
  exit 1
fi

# check if puppet etc dir exists
if [[ ! -d "${PUPPET_ETC_DIR}" ]]; then
  echo "Error. Could not find Puppet etc directory!"
  exit 1
fi

# check if hiera var dir exits
if [[ -d "${HIERA_VAR_DIR}" ]]; then
  echo "Error. Hiera var dir already exists!"
  exit 1
fi

apt-get update
apt-get install -y puppet apt-transport-https

mkdir -p ${HIERA_VAR_DIR}
cp -ar ${PUPPET_ETC_DIR}/hiera/{distros,nodes,locations,roles} ${HIERA_VAR_DIR}/
cp -ar ${PUPPET_ETC_DIR}/hiera/common-example.yaml ${HIERA_VAR_DIR}/common.yaml

EXPECT_HIERA="$(puppet apply -vd --genconfig | awk '/ hiera_config / {print $3}')"
if [[ ! -f "${EXPECT_HIERA}" ]]; then
  echo "File ${EXPECT_HIERA} not found! Copying from hiera-stub.yaml example..."
  cp ${PUPPET_ETC_DIR}/hiera/hiera-stub.yaml "${EXPECT_HIERA}"
fi

FACTER_PUPPET_APPLY="true" FACTER_ROLE="puppetmaster" puppet apply -vd ${PUPPET_ETC_DIR}/manifests/site.pp

puppet agent --enable
puppet agent -vd --no-daemonize --onetime
