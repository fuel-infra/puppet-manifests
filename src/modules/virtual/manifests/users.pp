class virtual::users {
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
}
