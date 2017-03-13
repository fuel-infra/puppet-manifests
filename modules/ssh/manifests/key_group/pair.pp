# Definition ssh::key_group::pair
#
# Definition of single SSH key and system users array pair.
#
define ssh::key_group::pair (
  $key,
  $type,
  $users,
) {
  # prepare hash for atomic elements mapping
  $_pairs = $users.reduce({}) |$cumulate, $user| {
    $_tmp = merge($cumulate, {"${name}-${user}" => {user => $user} })
    $_tmp
  }
  # create atomic parts
  create_resources(ssh::key_group::atom,
    $_pairs, {
      type => $type,
      key => $key,
    }
  )
}
