class systest {
  host { 'puppet':
    ip => '10.50.60.2',
  }
  host { 'master.vm':
    ip => '10.50.60.2',
  }
  host { 'centos-58-64bit.vm':
    ip => '10.50.60.3',
  }

  service { 'iptables':
    ensure => stopped,
    enable => false,
  }

  class { 'epel':
    stage => 'pre',
  }

  package { 'git':
    ensure => installed,
  }

  file { '/root/.ssh':
    owner => 'root',
    group => 'root',
    ensure => directory,
    mode => 0700,
  }

  file { '/root/.ssh/authorized_keys':
    owner => 'root',
    group => 'root',
    mode => 0600,
    source => "puppet:///modules/${module_name}/systest_key_rsa.pub",
  }
}
