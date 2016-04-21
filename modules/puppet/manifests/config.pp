# Class: puppet::config
#
# Puppet config reading class.
#
# Parameters are described in 'params.pp' file.
#
define puppet::config (
  $archive_file_server   = undef,
  $archive_files         = undef,
  $classfile             = undef,
  $config                = undef,
  $config_template       = undef,
  $environment           = undef,
  $factpath              = undef,
  $graph                 = undef,
  $localconfig           = undef,
  $logdir                = undef,
  $modulepath            = undef,
  $package               = undef,
  $parser                = undef,
  $pluginsync            = undef,
  $report                = undef,
  $rundir                = undef,
  $server                = undef,
  $service               = undef,
  $ssldir                = undef,
  $vardir                = undef,
) {
  # FIXME {
  # Legacy cleanup:
  # - /etc/puppet/puppet.conf.d/agent-config.conf
  # - /etc/puppet/puppet.conf.d/master-config.conf
  # - /etc/puppet/puppet.conf.d/
  if(!defined(File['/etc/puppet/puppet.conf.d/agent-config.conf'])) {
    file { '/etc/puppet/puppet.conf.d/agent-config.conf' :
      ensure => 'absent',
      force  => true,
    }
  }
  if(!defined(File['/etc/puppet/puppet.conf.d/master-config.conf'])) {
    file { '/etc/puppet/puppet.conf.d/master-config.conf' :
      ensure => 'absent',
      force  => true,
    }
  }
  if(!defined(File['/etc/puppet/puppet.conf.d'])) {
    file { '/etc/puppet/puppet.conf.d' :
      ensure => 'absent',
      force  => true,
    }
  }
  # } FIXME

  if(!defined(Concat[$config])) {
    concat { $config :
      ensure         => 'present',
      owner          => 'puppet',
      group          => 'puppet',
      mode           => '0644',
      order          => 'alpha',
      ensure_newline => true,
      warn           => true,
    }
  }

  concat::fragment { $title :
    target  => $config,
    content => template($config_template),
  }
}
