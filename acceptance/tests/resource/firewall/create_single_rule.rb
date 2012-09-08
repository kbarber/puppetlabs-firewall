test_name 'create single rule'

iptables_setup

agents.each do |host|
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
end
