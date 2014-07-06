class jenkins::params {
  $slave_packages = [
    'openjdk-7-jre'
  ]

  $jenkins_keys = {
    'jenkins@mc0n1-srt' => {
      type => 'ssh-rsa',
      key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC8W2SJaXlZAUje/IMWW1dzcsdPQZy38zCWfoGQZlLs6F8YTTYhIblONNNx2WDUrb/kFHcrQCyW5BsW62i98oqaDWEb73/NzgaWEbEz7EING7nkbC1+pt7caxTqR/Z+DThU57FH9Zavpt2+4h0nYOht+zawpasTLZI5zab5g4YxwP83m70R/5FI9hNDBau06V4Id8y/6gyxhHiz5eHUw7juvstLlgi2st6hrgXddFduGsvk5n0UH9nnPxf6fjOltv6i6UnzItxoyMOEYchhjDt/6be9+YVnM/Pgl29HsO5/flQlbeje8+qIjKv6elDvRITgN0OoAjYPA40rzaUCse1P'
    },
  }

  $swarm_packages = [
    'jenkins-swarm-slave'
  ]

  $service = 'jenkins-swarm-slave'

  $jenkins_master = $::jenkins_master
  $jenkins_user = $::jenkins_user
  $jenkins_password = $::jenkins_password

  if($::jenkins_labels) {
    $labels = $::jenkins_labels
  } else {
    $labels = "swarm systest ${::operatingsystem}_${::operatingsystemrelease}"
  }
}
