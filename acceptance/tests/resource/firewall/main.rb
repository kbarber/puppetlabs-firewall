test_name 'main tests'

iptables_setup

agents.each do |host|
  # Clear the rules, for this set of tests - we start with a blank slate.
  step 'clear all rules on agent manually' do
    iptables_flush_rules(host)
  end

=begin
  step 'a rule that breaks'
  on host, <<-EOS
iptables -t filter -A INPUT -p udp --sport 1000 -s 224.0.0.251 -j ACCEPT -m comment --comment '999 broken'
  EOS
  on host, puppet('resource firewall') do
    assert_output <<-EOS
firewall { '999 broken'
  ensure      => 'present',
  action      => 'accept',
  chain       => 'INPUT',
  proto       => 'udp',
  source      => '224.0.0.251/32',
  sport       => '1000',
  table       => 'filter',
}
    EOS
  end
=end

  iptables_flush_rules(host)

  step 'create some rules with firewall resource and make sure that table looks correct'
  apply_manifest_on host, <<-EOS
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
  on host, 'iptables-save -t filter' do
    rules = if host['platform'].match /(el-5)/
      assert_match '-A INPUT -s 1.1.1.1 -d 2.2.2.2 -p tcp -m comment --comment "100 accept some stuff"', stdout
    else
      assert_match '-A INPUT -s 1.1.1.1/32 -d 2.2.2.2/32 -p tcp -m comment --comment "100 accept some stuff"', stdout
    end
  end

  iptables_flush_rules(host)

  step 'create multiple rules'
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
