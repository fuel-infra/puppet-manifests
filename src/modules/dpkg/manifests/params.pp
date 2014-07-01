class dpkg::params {
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

  if $::fqdn =~ /\.mirantis\.com$/ {
    $additional_repos = [ 'deb http://fuel-repository.mirantis.com/devops/ubuntu/ /' ]
  } else {
    $additional_repos = [ 'deb http://osci-obs.vm.mirantis.net:82/qa-ubuntu/ubuntu/ /' ]
  }

  $repo_list = '/etc/apt/sources.list'
}
