class dpkg {
  include dpkg::params

  $gpg_key_cmd = $dpkg::params::gpg_key_cmd
  $init_command = $dpkg::params::init_command
  $mirror = $dpkg::params::mirror
  $repo_list = $dpkg::params::repo_list

  file { $repo_list :
    path => $repo_list,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('dpkg/sources.list.erb'),
  }

  exec { $gpg_key_cmd :
    command => $gpg_key_cmd,
    provider => 'shell',
    user => 'root',
    cwd => '/tmp',
    logoutput => 'on_failure'
  }

  exec { $init_command :
    command => $init_command,
    provider => 'shell',
    user => 'root',
    cwd => '/tmp',
    logoutput => 'on_failure',
  }

  Exec[$gpg_key_cmd]->
    File[$repo_list]->
    Exec[$init_command]
}

