class dpkg::params {
  $gpg_key_cmd = 'cat /etc/puppet/modules/dpkg/files/qa-ubuntu.key | apt-key add -'
  $init_command = 'apt-get update'
}
