# Define: puppet::facter
#
# This class deploys facter settings.
#
# Parameters:
#   [*custom_facts*] - defines the list of facts which are deployed on host
#
define puppet::facter (
  $custom_facts,
) {
  ensure_packages(['bash'])

  file { '/etc/facter' :
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/facter/facts.d' :
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/facter'],
  }

  file { "/etc/facter/facts.d/${title}.sh" :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('puppet/facts.sh.erb'),
    require => File['/etc/facter/facts.d'],
  }
}
