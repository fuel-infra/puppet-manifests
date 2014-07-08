class virtual::repos {

 class { 'apt':
    always_apt_update => true,
    disable_keys => false,
    purge_sources_list => true,
    purge_sources_list_d => true,
    purge_preferences_d => true,
    update_timeout => 300,
  }

  if $::fqdn =~ /msk\.mirantis\.net$/ {
    # Moscow internal mirror
    $mirror = 'http://mirrors.msk.mirantis.net/ubuntu/'
  }
  elsif $::fqdn =~ /srt\.mirantis\.net$/ {
    # Saratov internal mirror
    $mirror = 'http://mirrors.srt.mirantis.net/ubuntu/'
  }
  elsif $::fqdn =~ /\.vm\.mirantis\.net$/ {
    # VMs, I hope they're in Moscow ;)
    $mirror = 'http://mirrors.msk.mirantis.net/ubuntu/'
  } else {
    # All other servers
    $mirror = 'http://archive.ubuntu.com/ubuntu/'
  }

  if $::fqdn =~ /(\.mirantis\.com|fuel-infra\.org)$/ {
    $devops = 'http://fuel-repository.mirantis.com/devops/ubuntu/'

    # FIXME https://bugs.launchpad.net/fuel/+bug/1339162
    $docker = 'https://get.docker.io/ubuntu'
    $jenkins = 'http://pkg.jenkins-ci.org/debian-stable/'
    # /FIXME
  } else {
    $devops = 'http://osci-obs.vm.mirantis.net:82/qa-ubuntu/ubuntu/'
    $docker = 'http://mirrors-local-msk.msk.mirantis.net/docker/'
    $jenkins = 'http://mirrors-local-msk.msk.mirantis.net/jenkins/debian-stable/'
  }

  @apt::source { 'mirror':
    location => $mirror,
    release => $::lsbdistcodename,
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
    include_src => false,
  }

  @apt::source { 'mirror-updates':
    location => $mirror,
    release => "${::lsbdistcodename}-updates",
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
    include_src => false,
  }

  @apt::source { 'security':
    location => 'http://security.ubuntu.com/ubuntu/',
    release => "${::lsbdistcodename}-security",
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
  }

  @apt::source { 'devops':
    location => $devops,
    release => '/',
    key => 'C1EC35C7D5A05778',
    key_server => 'keyserver.ubuntu.com',
    repos => '',
    include_src => false,
  }

  @apt::source { 'docker':
    location => $docker,
    release => 'docker',
    key => 'D8576A8BA88D21E9',
    key_server => 'keyserver.ubuntu.com',
    repos => 'main',
    include_src => false,
  }

  @apt::source { 'jenkins':
    location => $jenkins,
    release => 'binary/',
    key => 'D50582E6 10AF40FE',
    key_server => 'keyserver.ubuntu.com',
    repos => '',
    include_src => false,
  }
}
