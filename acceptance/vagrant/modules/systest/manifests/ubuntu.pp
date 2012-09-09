class systest::ubuntu {
  package { ['ruby1.8', 'ruby-full']:
    ensure => installed,
  }
}
