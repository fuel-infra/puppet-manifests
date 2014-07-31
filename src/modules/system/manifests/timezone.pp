class system::timezone (
  $timezone = 'UTC',
) {
  include virtual::packages

  realize Package['tzdata']

  file { 'timezone' :
    path => '/etc/timezone',
    ensure => 'present',
    content => $timezone,
    mode => '0644',
    owner => 'root',
    group => 'root',
  }
}
