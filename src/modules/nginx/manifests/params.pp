class nginx::params {
  if $external_host {
    $autoindex = 'off'
  } else {
    $autoindex = 'on'
  }

  $server_name = $::fqdn

  $packages = [
    'nginx',
    'nginx-common',
    'nginx-full',
  ]

  $service = 'nginx'
}
