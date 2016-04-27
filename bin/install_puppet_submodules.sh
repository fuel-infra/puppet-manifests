#!/bin/bash

set -xe

PUPPET_ETC_DIR="/etc/puppet"
GIT="/usr/bin/git"

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

# install/update submodules
cd "${PUPPET_ETC_DIR}"
${GIT} submodule init
${GIT} submodule sync
${GIT} submodule update
