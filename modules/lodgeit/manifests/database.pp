# Class lodgeit::database
#
class lodgeit::database {
  include ::mysql::server
  include ::mysql::client
  include ::mysql::server::account_security
}
