class systest {
  case $operatingsystem {
    'debian': {
      class { 'systest::debian': }
    }
    'ubuntu': { 
      class { 'systest::ubuntu': }
    }
    'centos': {
      class { 'systest::centos': }
    }
    default: {
      fail("Operating system not supported")
    }
  }

  host { 'puppet':
    ip => '10.50.60.2',
  }
  host { 'master.vm':
    ip => '10.50.60.2',
  }
  host { 'centos-58-64bit.vm':
    ip => '10.50.60.3',
  }
  host { 'debian-605-64bit.vm':
    ip => '10.50.60.4',
  }
  host { 'ubuntu-1104-64bit.vm':
    ip => '10.50.60.5',
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
