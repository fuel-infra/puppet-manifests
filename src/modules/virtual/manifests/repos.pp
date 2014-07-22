class virtual::repos {

  define repository(
    $location,
    $release = $::lsbdistcodename,
    $repos,
    $key,
    $key_server = 'keyserver.ubuntu.com',
    $include_src = false) {

    @apt::key { $title :
      key => $key,
      key_server => $key_server,
    }

    @apt::source { $title :
      location => $location,
      release => $release,
      repos => $repos,
      include_src => $include_src,
    }

    realize Apt::Key[$title]
    realize Apt::Source[$title]

    Apt::Key[$title]->
      Apt::Source[$title]
  }

  class { 'apt':
    always_apt_update => true,
    disable_keys => false,
    purge_sources_list => true,
    purge_sources_list_d => true,
    purge_preferences_d => true,
    update_timeout => 300,
  }

  if $external_host {
    # External mirror
    $mirror = 'http://archive.ubuntu.com/ubuntu/'
  } else {
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
  }

  if $::fqdn =~ /(\.mirantis\.com|fuel-infra\.org)$/ or $external_host {
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

  @repository { 'mirror':
    location => $mirror,
    release => $::lsbdistcodename,
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
    include_src => false,
  }

  @repository { 'mirror-updates':
    location => $mirror,
    release => "${::lsbdistcodename}-updates",
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
    include_src => false,
  }

  @repository { 'security':
    location => $mirror,
    release => "${::lsbdistcodename}-security",
    key => '437D05B5 C0B21F32',
    repos => 'main restricted universe multiverse',
  }

  @repository { 'devops':
    location => $devops,
    release => '/',
    key => 'C1EC35C7D5A05778',
    key_server => 'keyserver.ubuntu.com',
    repos => '',
    include_src => false,
  }

  @repository { 'docker':
    location => $docker,
    release => 'docker',
    key => 'D8576A8BA88D21E9',
    key_server => 'keyserver.ubuntu.com',
    repos => 'main',
    include_src => false,
  }

  @repository { 'jenkins':
    location => $jenkins,
    release => 'binary/',
    key => 'D50582E6 10AF40FE',
    key_server => 'keyserver.ubuntu.com',
    repos => '',
    include_src => false,
  }

  # FIXME: https://bugs.launchpad.net/fuel/+bug/1342798
  @repository { 'puppetlabs' :
    location => 'http://apt.puppetlabs.com',
    release => 'trusty',
    key => '4BD6EC30',
    key_server => 'keyserver.ubuntu.com',
    repos => 'main',
    include_src => false,
  }

  @repository { 'puppetlabs-deps' :
    location => 'http://apt.puppetlabs.com',
    release => 'trusty',
    key => '4BD6EC30',
    key_server => 'keyserver.ubuntu.com',
    repos => 'dependencies',
    include_src => false,
  }
  # /FIXME
}
