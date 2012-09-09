class hosts {
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
  host { 'centos-63-64bit.vm':
    ip => '10.50.60.6',
  }
}
