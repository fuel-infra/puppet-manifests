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

  @user { 'root' :
    ensure => 'present',
    shell => '/bin/bash',
    password => '$6$v0NMomQ1$VSGZjvlRebtDHSoRdSGWh2tDPSu.i7eV6tfWeLY1Zf6YPREMmtobthI.ff9iHxf.AJLhVI6qZtwp472OiZqWv/',
  }
}
