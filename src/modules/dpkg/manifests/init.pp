class dpkg {
  include dpkg::params

  $additional_repos = $dpkg::params::additional_repos
  $mirror = $dpkg::params::mirror
  $repo_list = $dpkg::params::repo_list

  file { $repo_list :
    path => $repo_list,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('dpkg/sources.list.erb'),
  }

  file { 'gpg-key-qa' :
    path => '/tmp/qa-ubuntu.key',
    owner => 'root',
    group => 'root',
    mode => '0400',
    source => 'puppet:///modules/dpkg/qa-ubuntu.key',
  }

  file { 'gpg-key-docker' :
    path => '/tmp/docker.key',
    owner => 'root',
    group => 'root',
    mode => '0400',
    source => 'puppet:///modules/dpkg/docker.key',
  }

  exec { 'gpg-add-qa' :
    command => 'cat /tmp/qa-ubuntu.key | apt-key add -',
    logoutput => 'on_failure'
  }

  exec { 'gpg-add-docker' :
    command => 'cat /tmp/docker.key | apt-key add -',
    logoutput => 'on_failure'
  }

  exec { 'apt-update' :
    command => '/usr/bin/apt-get update',
    logoutput => 'on_failure',
  }

  File['gpg-key-qa']->
    File['gpg-key-docker']->
    Exec['gpg-add-qa']->
    Exec['gpg-add-docker']->
    File[$repo_list]->
    Exec['apt-update']
}
