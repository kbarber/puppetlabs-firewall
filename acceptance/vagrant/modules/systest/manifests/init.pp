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
