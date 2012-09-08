test_name 'test puppet resource firewall command with real rules'

iptables_setup

agents.each do |host|
  # Clear the rules, for this set of tests - we start with a blank slate.
  step 'clear all rules on agent manually' do
    iptables_flush_rules(host)
  end

  step 'insert some basic rules and make sure puppet resource returns the ' +
    'right thing'
  on host, <<-EOS
iptables -t filter -A INPUT -p tcp -s 1.1.1.1 -d 2.2.2.2 -j ACCEPT
  EOS
  on host, puppet('resource firewall') do
    assert_output <<-EOS
firewall { '9999 2fe04d0e5d47207166944df84cb70850':
  ensure      => 'present',
  action      => 'accept',
  chain       => 'INPUT',
  destination => '2.2.2.2/32',
  proto       => 'tcp',
  source      => '1.1.1.1/32',
  table       => 'filter',
}
    EOS
  end
end
