# Class: virtual::users
#
class virtual::users {
  $system = hiera_hash('system')

  @user { 'gerrit':
    ensure     => 'present',
    name       => 'gerrit',
    shell      => '/bin/false',
    home       => '/var/lib/gerrit',
    managehome => true,
    comment    => 'Gerrit',
  }

  @user { 'root' :
    ensure   => 'present',
    shell    => '/bin/bash',
    password => $system['root_password_hash'],
  }
}
