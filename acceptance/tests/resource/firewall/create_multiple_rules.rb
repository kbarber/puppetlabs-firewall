test_name 'Create multiple rules and make sure iptables reflects them'

iptables_setup

agents.each do |host|
  apply_manifest_on host, <<-EOS
firewall { '200 accept some stuff':
  ensure      => 'present',
  action      => 'accept',
  chain       => 'INPUT',
  proto       => 'udp',
  source      => '3.3.3.3/32',
  destination => '2.2.2.2/32',
  table       => 'filter',
}
firewall { '100 accept some stuff':
  ensure      => 'present',
  action      => 'accept',
  chain       => 'INPUT',
  proto       => 'tcp',
  source      => '1.1.1.1/32',
  destination => '2.2.2.2/32',
  table       => 'filter',
}
  EOS
  # Rule matcher input
  rules = if host['platform'].match /(el-5)/
    {
      'filter' => Regexp.quote(<<-EOS)
-A INPUT -s 1.1.1.1 -d 2.2.2.2 -p tcp -m comment --comment "100 accept some stuff" -j ACCEPT 
-A INPUT -s 3.3.3.3 -d 2.2.2.2 -p udp -m comment --comment "200 accept some stuff" -j ACCEPT 
    EOS
    }
  else
    {
      'filter' => Regexp.quote(<<-EOS)
-A INPUT -s 1.1.1.1/32 -d 2.2.2.2/32 -p tcp -m comment --comment "100 accept some stuff" -j ACCEPT 
-A INPUT -s 3.3.3.3/32 -d 2.2.2.2/32 -p udp -m comment --comment "200 accept some stuff" -j ACCEPT 
    EOS
    }
  end

  assert_rules_on host, rules
end
