class dpkg {
  include dpkg::params

  $gpg_key_cmd = $dpkg::params::gpg_key_cmd
  $init_command = $dpkg::params::init_command
  $internal_mirror = $dpkg::params::internal_mirror
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
    logoutput => 'on_failure'
  }

  exec { $init_command :
    command => $init_command,
    logoutput => 'on_failure',
  }

  Exec[$gpg_key_cmd]->
    File[$repo_list]->
    Exec[$init_command]
}
