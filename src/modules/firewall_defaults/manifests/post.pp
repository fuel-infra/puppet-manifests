class firewall_defaults::post {
  if $external_host {
    firewall { '999 drop all':
      proto   => 'all',
      action  => 'drop',
      before  => undef,
    }
  }
}
