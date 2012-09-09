class epel {
  file { '/etc/yum.repos.d/epel.repo':
    ensure => file,
    source => "puppet:///modules/${module_name}/epel.repo",
  }
}
