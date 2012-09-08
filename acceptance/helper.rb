# Do the setup for the iptables tasks.
# @example Place near top of your test
#   iptables_setup
def iptables_setup
  # Call teardown to clear the slate first
  iptables_teardown

  # Here we setup the module, by copying it from the path where systest would
  # have git-cloned it on the master.
  apply_manifest_on master, <<-EOS
file { '/etc/puppet/modules':
  ensure  => directory,
  purge   => true,
  recurse => true,
}

file { '/etc/puppet/modules/firewall':
  ensure  => directory,
  source  => '/opt/puppet-git-repos/puppetlabs-firewall',
  purge   => true,
  recurse => true,
}
  EOS

  # Establish some cleanup here. This gets executed even if we break systest.
  teardown { iptables_teardown }
end

# Cleanup from iptables testing.
#
# Here we remove the modules directory on the master and flush rules on the
# agents.
#
# Calling this directly shouldn't be required, it should be setup as a teardown
# task.
#
# @api private
def iptables_teardown
  on master, 'rm -rf /etc/puppet/modules'
  agents.each do |host|
    iptables_flush_rules(host)
  end
end

# Accepts a rules hash and checks to make sure that iptables-save matches it
#
# @param rules [Hash <String, Regexp>] hash of table name -> regexp to match 
#   in rules area. The regexp should be a multiline one (/m) as the results
#   will be multiline.
# @param iptsave [String] the results of iptables-save
# @example Match a single rule in filter
#   assert_rule({'filter' => /-s 1.1.1.1/m})
def assert_rules(rules, iptsave)
  table_hash = iptables_rules_to_hash(iptsave)
  rules.each do |table, match|
    assert_match table_hash[table], iptsave
  end
end

# Get rule sets and return a very basic hash keyed from table, so we can
# perform our matches on it.
#
# @param iptsave [String] the results of iptables-save
# @return [Hash <String, Array>] Returns a hash, they key representing the
#  table and the value being an array of rules for that table.
# @api private
def iptables_rules_to_hash(iptsave)
  ipt_hash = {}
  table = nil
  iptsave.each_line do |line|
    case line
    when /\A\*(\w+)/
      table = $1
    when /\A(\-A.+)/
      ipt_hash[table] ||= []
      ipt_hash[table] << $1.strip
    end
  end
end

# Run 'assert_rules' on a specific host
#
# @params host [String] host to run the command on
# @params Hash [Hash] Rules hash
def assert_rules_on(host, rules)
  on host, 'iptables-save' do
    assert_rules rules, stdout
  end
end

# Restore iptables to defaults.
#
# @params host [String] host to run the command on
def iptables_flush_rules(host)
  on host, 'iptables -t filter -F'
  on host, 'iptables -t nat -F'
  on host, 'iptables -t mangle -F'
  on host, 'iptables -t raw -F'
end
