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

# apply list of patches provided by command line
# example: ./install_puppet_patches.sh refs/changes/34/20134/2 ...
cd "${PUPPET_ETC_DIR}"
FETCH_URL=$($GIT remote show origin | awk '/Fetch URL/ { print $3 }')
for refspec in "$@"
do
  ${GIT} fetch ${FETCH_URL} ${refspec} && git cherry-pick FETCH_HEAD
done
