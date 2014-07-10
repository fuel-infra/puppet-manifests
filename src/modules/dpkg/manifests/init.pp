class dpkg {
  include virtual::repos

  realize Virtual::Repos::Repository['mirror']
  realize Virtual::Repos::Repository['mirror-updates']
  realize Virtual::Repos::Repository['security']
  realize Virtual::Repos::Repository['devops']
}
