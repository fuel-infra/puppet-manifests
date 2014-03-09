service { "jenkins-swarm-slave":
    ensure  => "running",
    enable  => "true",
    require => Package["jenkins-swarm-slave"],
}

file { "jenkins-swarm-slave":
    name => "/etc/default/jenkins-swarm-slave",
    notify => Service['jenkins-swarm-slave'],
    ensure => present,
        owner => root,
        group => $admingroup,
        mode  => 644,
    content => template("jenkins-swarm-slave/jenkins-swarm-slave.erb"),
    require => Package['jenkins-swarm-slave']
}

