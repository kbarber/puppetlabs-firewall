class epel {
  $rel = split($operatingsystemrelease, '[.]')
  file { '/etc/yum.repos.d/epel.repo':
    ensure => file,
    source => "puppet:///modules/${module_name}/epel-${rel[0]}.repo",
  }
}
