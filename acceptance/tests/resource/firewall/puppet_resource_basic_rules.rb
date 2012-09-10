test_name 'Test puppet resource firewall command with real rules'

iptables_setup

agents.each do |host|
  on host, <<-EOS
iptables -t filter -A INPUT -p tcp -s 1.1.1.1 -d 2.2.2.2 -j ACCEPT
  EOS
  on host, puppet('resource firewall') do
    hash = if host['platform'].match /(el-5)/
      '2fe04d0e5d47207166944df84cb70850'
    else
      'c0595bf3760d4dcb41773d27b5827b5c'
    end
    assert_output <<-EOS
firewall { '9999 #{hash}':
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
