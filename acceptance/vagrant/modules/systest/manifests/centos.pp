class systest::centos {
  service { 'iptables':
    ensure => stopped,
    enable => false,
  }

  class { 'epel':
    stage => 'pre',
  }
}
