# Class: fuel_project::apps::bacula
#
class fuel_project::apps::bacula {
  class { '::bacula::client' :}
}
