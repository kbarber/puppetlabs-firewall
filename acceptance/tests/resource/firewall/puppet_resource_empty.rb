test_name 'puppet resource should return empty when no rules'

iptables_setup

agents.each do |host|
  step 'run puppet firewall resource and assert it returns nothing' do
    on host, puppet('resource firewall') do
      assert_output "\n"
    end
  end
end
