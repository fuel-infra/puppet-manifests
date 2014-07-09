class virtual::users {
  $system = hiera_hash('system')

  @user { 'gerrit':
    ensure => 'present',
    name => 'gerrit',
    shell => '/bin/false',
    home => '/var/lib/gerrit',
    managehome => true,
    comment => 'Gerrit',
  }

  @user { 'jenkins' :
    ensure => 'present',
    name => 'jenkins',
    shell => '/bin/bash',
    home => '/home/jenkins',
    managehome => true,
    system => true,
    comment => 'Jenkins',
    groups => 'www-data',
  }

  @user { 'root' :
    ensure => 'present',
    shell => '/bin/bash',
    password => $system['root_password_hash'],
  }
}
