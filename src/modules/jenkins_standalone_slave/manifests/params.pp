class jenkins_standalone_slave::params {
  $packages = [
    'openjdk-7-jre'
  ]

  $users = {
    'jenkins' => {
      name => 'jenkins',
      shell => '/bin/sh',
      home => '/home/jenkins',
      managehome => true,
      system => true,
      comment => 'Jenkins',
    }
  }

  $jenkins_keys = {
    'jenkins@mc0n1-srt' => {
      type => 'ssh-rsa',
      key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC8W2SJaXlZAUje/IMWW1dzcsdPQZy38zCWfoGQZlLs6F8YTTYhIblONNNx2WDUrb/kFHcrQCyW5BsW62i98oqaDWEb73/NzgaWEbEz7EING7nkbC1+pt7caxTqR/Z+DThU57FH9Zavpt2+4h0nYOht+zawpasTLZI5zab5g4YxwP83m70R/5FI9hNDBau06V4Id8y/6gyxhHiz5eHUw7juvstLlgi2st6hrgXddFduGsvk5n0UH9nnPxf6fjOltv6i6UnzItxoyMOEYchhjDt/6be9+YVnM/Pgl29HsO5/flQlbeje8+qIjKv6elDvRITgN0OoAjYPA40rzaUCse1P',
    },
  }
}
