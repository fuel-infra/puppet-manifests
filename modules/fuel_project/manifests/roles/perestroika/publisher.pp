# Class: fuel_project::roles::perestroika::publisher
#
# This role deploys Jenkins slave host for publishing of packages.
# See hiera file for list and params of used classes.
#
# Parameters:
#   [*gpg_content_priv*] - GPG private key contents
#   [*gpg_content_pub*] - GPG public key contents
#   [*gpg_id_priv*] - GPG private key ID
#   [*gpg_id_pub*] - GPG public key ID
#   [*gpg_pub_key_owner*] - owner of GPG public key file
#   [*gpg_priv_key_owner*] - owner of GPG private key file
#   [*packages*] - packages required to publish
#

class fuel_project::roles::perestroika::publisher (
  $gpg_content_priv,
  $gpg_content_pub,
  $gpg_id_priv,
  $gpg_id_pub,
  $gpg_pub_key_owner  = 'jenkins',
  $gpg_priv_key_owner = 'jenkins',
  $packages = [
    'createrepo',
    'devscripts',
    'expect',
    'python-lxml',
    'reprepro',
    'rpm',
    'yum-utils',
  ],
) {

  ensure_packages($packages)

  if( ! defined(Class['::fuel_project::jenkins::slave'])) {
    class { '::fuel_project::jenkins::slave' : }
  }

  class { '::gnupg' : }

  gnupg_key { 'perestroika_gpg_public':
    ensure      => 'present',
    key_id      => $gpg_id_pub,
    user        => $gpg_pub_key_owner,
    key_content => $gpg_content_pub,
    key_type    => public,
    require     => [
      User['jenkins'],
      Class['::fuel_project::jenkins::slave'],
    ],
  }

  gnupg_key { 'perestroika_gpg_private':
    ensure      => 'present',
    key_id      => $gpg_id_priv,
    user        => $gpg_priv_key_owner,
    key_content => $gpg_content_priv,
    key_type    => private,
    require     => [
      User['jenkins'],
      Class['::fuel_project::jenkins::slave'],
    ],
  }
}