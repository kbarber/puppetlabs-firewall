test_name 'broken rule'

# This picks up a real bug, that needs fixing

iptables_setup

agents.each do |host|
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
end
