class dpkg {
  include virtual::repos

  realize Apt::Source['mirror']
  realize Apt::Source['mirror-updates']
  realize Apt::Source['security']
  realize Apt::Source['devops']
}
