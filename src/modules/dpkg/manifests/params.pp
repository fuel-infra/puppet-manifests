class dpkg::params {
  $gpg_key_cmd = 'cat /etc/puppet/modules/dpkg/files/qa-ubuntu.key | apt-key add -'

  $init_command = 'apt-get update'

  if $::fqdn =~ /msk\.mirantis\.net$/ {
    # Moscow internal mirror
    $mirror = 'mirrors.msk.mirantis.net'
  }
  elsif $::fqdn =~ /srt\.mirantis\.net$/ {
    # Saratov internal mirror
    $mirror = 'mirrors.srt.mirantis.net'
  }
  elsif $::fqdn =~ /\.vm\.mirantis\.net$/ {
    # VMs, I home they're in Moscow ;)
    $mirror = 'mirrors.msk.mirantis.net'
  } else {
    # All other servers
    $mirror = 'archive.ubuntu.com'
  }

  $repo_list = '/etc/apt/sources.list'
}

