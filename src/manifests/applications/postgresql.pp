service { "postgresql":
    ensure  => "running",
    enable  => "true",
    require => Package["postgresql-9.1"],
}

file { "pg_hba.conf":
    name => "/etc/postgresql/9.1/main/pg_hba.conf",
    notify => Service['postgresql'],
    ensure => present,
        owner => root,
        group => $admingroup,
        mode  => 644,
    content => template("postgresql/pg_hba.conf.erb"),
    require => Package['postgresql-9.1']
}

