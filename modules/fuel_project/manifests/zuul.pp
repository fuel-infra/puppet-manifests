# Class: fuel_project::zuul
#
# This class deploys Zuul Zabbix items and configures automatic update of Zuul layout.
#
# Parameters:
#   [*jenkins_job*] - Name of Jenkins project that prepares configs.
#   [*jenkins_url*] - URL of Jenkins instance where to get updated configs.
#   [*zuul_layout* ] - Path to Zuul layout file.
#   [*update_cronjob_name*] - Name of cron job updating zuul layout.
#   [*update_cronjob_params*] - Hash containing parameters of cron job.
#
class fuel_project::zuul (
  $jenkins_job = 'zuul-maintainer',
  $jenkins_url = 'http://jenkins.server.name/',
  $update_cronjob_name = 'update_zuul_layout',
  $update_cronjob_params = {},
  $zuul_layout = $::zuul::layout,
){
  ensure_resource('class', 'zabbix::agent')
  ensure_packages('config-zabbix-agent-zuul-item')


  file { '/usr/local/bin/zuul_apply_layout.sh':
    mode    => '0755',
    content => template('fuel_project/zuul/zuul_apply_layout.sh.erb'),
  }

  create_resources('cron', { "${update_cronjob_name}" => $update_cronjob_params }, {
    ensure  => 'absent',
    command => '/usr/bin/flock -xn /var/lock/update_zuul_layout.lock /usr/local/bin/zuul_apply_layout.sh 2>&1 | logger -t update-zuul-layout',
    user    => 'zuul',
    minute  => '*/30',
  })

}
