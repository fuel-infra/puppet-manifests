node 'jenkins-slave' {
    import 'manifests/dpkg.pp'
    import 'manifests/packages.pp'
    import 'manifests/applications/*.pp'
}

node 'mc2n7-srt.srt.mirantis.net' inherits 'jenkins-slave' {}

