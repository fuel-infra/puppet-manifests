# Class: obs_server::repo
#
# This class adds Zypper repository for OBS.
#
# Parameters:
#   [*repo_url*] - repository URL
#   [*repo_name*] - repository Name
#
class obs_server::repo (
  $repo_url = '',
  $repo_name = '',
){

require zypprepo

zypprepo { 'OBS_repo':
  baseurl      => $repo_url,
  enabled      => 1,
  autorefresh  => 1,
  name         => $repo_name,
  gpgcheck     => 1,
  priority     => 98,
  keeppackages => 1,
  type         => 'rpm-md',
  notify       => Exec['repo_update'],
}

exec {'repo_update':
  command => '/usr/bin/zypper --gpg-auto-import-keys refresh',
  user    => root,
}

}
