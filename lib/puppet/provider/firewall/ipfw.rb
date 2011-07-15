require 'puppet/provider/firewall'

Puppet::Type.type(:firewall).provide :ipfw, :parent => Puppet::Provider::Firewall do
  include Puppet::Util::Firewall
  
  @doc = "IPFW type provider"

  commands :ipfw => '/sbin/ipfw'

  defaultfor :operatingsystem => [:darwin]
  confine :operatingsystem => [:darwin]

  def insert
    debug 'Inserting rule %s' % resource[:name]
  end

  def update
    debug 'Updating rule %s' % resource[:name]
  end

  def delete
    debug 'Deleting rule %s' % resource[:name]
  end

  def exists?
    properties[:ensure] != :absent
  end

  # Flush the property hash once done.
  def flush
    debug("[flush]")
    if @property_hash.delete(:needs_change)
      notice("Properties changed - updating rule")
      update
    end
    @property_hash.clear
  end
  
  def self.instances
    debug "[instances]"

    # Our rules hash that will be ultimately returned once populated
    rules = []

    # Grab list of rules and iterate
    ipfw_list = ipfw("list")
    ipfw_list.each do |line|
      # Convert rule lines to hash
      hash = rule_to_hash(line)

      # Populate missing data
      hash[:provider] = self.name.to_s

      # Create new Type from hash and insert into rules hash
      rules << new(hash)
    end

    # Return our resulting rules
    rules
  end

  # Convert a rule to a hash
  def self.rule_to_hash(line)
    hash = {}
    
    # Grok rulenumber
    line =~ /^(\d+)\s+(\w+)\s+/
    hash[:rulenum] = $1
    hash[:jump] = $2

    # Grok from and to
    line =~ /from\s+([\w\d\.:]+)\s+to\s+([\w\d\.:]+)\s*/
    hash[:source] = $1
    hash[:destination] = $2

    # Grok comment
    line =~ /\/\/ (.+)$/
    hash[:comment] = $1

    # Name
    hash[:name] = hash[:rulenum] 
    if hash[:comment] then
      hash[:name] += " " + hash[:comment]
    end

    # Return hash
    hash
  end

  def insert_args
    args = []
    args
  end

  def update_args
    args = []
    args
  end

  def general_args
    debug "Current resource: %s" % resource.class
    args = []
    args
  end

  def insert_order
    debug("[insert_order]")
  end

  ##############
  # Properties #
  ##############

  def proto
  end

  def proto=
  end

  def jump
    # TODO: pulled this from method_missing
    if @property_hash[:jump] then
      return @property_hash[:jump]
    else
      return nil
    end
  end

  def jump=
  end

  def source
    # TODO: pulled this from method_missing
    if @property_hash[:source] then
      return @property_hash[:source]
    else
      return nil
    end
  end

  def source=
  end

  def destination
    # TODO: pulled this from method_missing
    if @property_hash[:destination] then
      return @property_hash[:destination]
    else
      return nil
    end
  end

  def destination=
  end

  def sport
  end

  def sport=
  end

  def dport
  end

  def dport=
  end

  def iniface
  end

  def iniface=
  end

  def outiface
  end

  def outiface=
  end
end
