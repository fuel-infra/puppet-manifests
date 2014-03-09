file { "allow-unauthenticated.conf":
    name => "/etc/apt/apt.conf.d/allow-unauthenticated.conf",
    ensure => present,
        owner => root,
        group => $admingroup,
        mode  => 644,
    content => template("dpkg/allow-unauthenticated.conf.erb"),
}

