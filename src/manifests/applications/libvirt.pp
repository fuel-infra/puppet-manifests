service { "libvirt-bin":
    ensure  => "running",
    enable  => "true",
    require => Package["libvirt-bin"],
}

file { "libvirtd.conf":
    name => "/etc/libvirt/libvirtd.conf",
    notify => Service['libvirt-bin'],
    ensure => present,
        owner => root,
        group => $admingroup,
        mode  => 644,
    content => template("libvirt/libvirtd.conf.erb"),
    require => Package['libvirt-bin']
}

