class dpkg {
  include dpkg::params

  $gpg_key_cmd = $dpkg::params::gpg_key_cmd
  $init_command = $dpkg::params::init_command

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
    Exec[$init_command]
}

