$packages = ["curl",
"git",
"jenkins-swarm-slave",
"libvirt-bin",
"openssh-server",
"postgresql-9.1",
"postgresql-server-dev-9.1",
"python-anyjson",
"python-dev",
"python-devops",
"python-glanceclient",
"python-ipaddr",
"python-keystoneclient",
"python-libvirt",
"python-novaclient",
"python-paramiko",
"python-proboscis",
"python-seed-cleaner",
"python-seed-client",
"python-virtualenv",
"python-xmlbuilder",
"qemu-kvm",
"vim",
"zabbix-agent"]

package {'logrotate':
    ensure => '3.7.8-6ubuntu5',
    require => File['/etc/apt/apt.conf.d/allow-unauthenticated.conf']}

package {$packages:
    ensure => "installed",
    require => File['/etc/apt/apt.conf.d/allow-unauthenticated.conf']}

