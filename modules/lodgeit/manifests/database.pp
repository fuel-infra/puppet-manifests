# Class lodgeit::database
#
# This class deploys MySQL server instance for lodgeit application.
#
class lodgeit::database {
  include ::mysql::server
  include ::mysql::client
  include ::mysql::server::account_security
}
