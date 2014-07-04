class virtual::repos {

 class { 'apt':
    always_apt_update => true,
    purge_sources_list => true,
  }

  @apt::source { 'jenkins':
    location => 'http://mirrors-local-msk.msk.mirantis.net/jenkins/debian-stable/',
    release => 'binary/',
    key => 'D50582E6',
    key_source => 'http://mirrors-local-msk.msk.mirantis.net/jenkins/debian-stable/Release.key',
    repos => '',
    include_src => false,
  }

  @apt::source { 'docker':
    location => 'http://mirrors-local-msk.msk.mirantis.net/docker',
    release => 'docker',
    key => 'A88D21E9',
    key_source => 'http://mirrors-local-msk.msk.mirantis.net/docker/DOCKER-GPG-KEY',
    repos => 'main',
    include_src => false,
  }
}
