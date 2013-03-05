#firewall

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-firewall.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-firewall)

####Table of Contents

1. [Overview - What is the Firewall module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with Firewall](#setup)
4. [Usage - Configuration and customization options](#usage)
    * [Default rules - Setting up general configurations for all firewalls](#default-rules)
    * [Application-specific rules - Options for configuring and managing firewalls across applications](#application-specific-rules)
    * [Parameters - Parameters available for configuration](#parameters)
5. [Implementation Reference - An under-the-hood peek at what the module is doing](#implementation)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)
    * [Tests - Testing your configuration](#tests)  

##Overview

The Firewall module lets you manage firewall rules with Puppet.

##Module Description

PuppetLabs Firewall introduces the resource 'firewall', which is then used to manage and configure firewall rules from within the Puppet DSL. This module offers support for iptables, ip6tables, and ebtables. 

##Setup

**What Firewall affects:**

* every node running a firewall
* system's firewall settings
* connection settings for managed nodes 
* unmanaged resources (get purged)
* site.pp

**Setup Requirements**

Firewall uses Ruby-based providers, so you must have (pluginsync enabled)[http://docs.puppetlabs.com/guides/plugins_in_modules.html#enabling-pluginsync]. 

**Upgrade Requirements**



###Beginning with Firewall

Since Firewall configures and manages firewall rules via Puppet, you need to provide some initial top-scope configuration to ensure your firewall configurations are ordered properly and you do not lock yourself out of your box or lose configurations.  

Persistence of rules between reboots is handled automatically, although there are known issues with ip6tables on older Debian/Ubuntu and ebtables. 

In your `site.pp` (or some similarly top-scope file), set up a metatype to purge unmanaged firewall resources. This will clear any existing rules and make sure that only rules defined in Puppet exist on the machine

     resources { "firewall":
       purge => true
     }

Next, set up the default parameters for all of the firewall rules you will be establishing later. These defaults will ensure that the pre and post classes (you will be setting up in just a moment) are run in the correct order to avoid locking you out of your box during the first puppet run

    Firewall {
      before  => Class['my_fw::post'],
      require => Class['my_fw::pre'],
    }
    
You also need to declare the 'my_fw::pre' & 'my_fw::post' classes so that
dependencies are satisfied. This can be achieved using an External Node
Classifier or the following:

    class { 'my_fw::pre': }
    class { 'my_fw::post': }

or:**TODO: Is this good?**

    include my_fw::pre, my_fw:post

Now to create the `my_fw::pre` and `my_fw::post` classes. Firewall acts on your running firewall, making immediate changes as the catalog executes. Defining default pre and post rules allows you to avoid locking yourself out of your own boxes when Puppet runs. This approach employs a whitelist setup, so you can define what rules you want and everything else is ignored rather than removed.

The `pre` class should be located in `my_fw/manifests/pre.pp` and should contain any default rules to be applied first

    class my_fw::pre {
      Firewall {
        require => undef,
      }

      # Default firewall rules
      firewall { '000 accept all icmp':
        proto   => 'icmp',
        action  => 'accept',
      }->
      firewall { '001 accept all to lo interface':
        proto   => 'all',
        iniface => 'lo',
        action  => 'accept',
      }->
      firewall { '002 accept related established rules':
        proto   => 'all',
        state   => ['RELATED', 'ESTABLISHED'],
        action  => 'accept',
      }
    }

The rules in `pre` should allow basic networking (such as ICMP and TCP), as well as ensure that existing connections are not closed. 

The `post` class should be located in `my_fw/manifests/post.pp` and include any default rules to be applied last 

    class my_fw::post {
      firewall { '999 drop all':
        proto   => 'all',
        action  => 'drop',
        before  => undef,
      }
    }

To put it all together: the `before` parameter in `Firewall {}` ensures `my_fw::post` is run before any other rules and the the `require` parameter ensures `my_fw::pre` is run after any other rules. So the run order is:

* run the rules in `my_fw::pre`
* run your rules (defined in code)
* run the rules in `my_fw::post`

##Usage

There are two kinds of firewall rules you can use with Firewall: default rules and application-specific rules. Default rules apply to general firewall settings, whereas application-specific rules manage firewall settings of a specific application, node, etc. 

###Default rules

You can place default rules in either `my_fw::pre` or `my_fw::post`, depending on when you would like them to run. Rules placed in the `pre` class will run first, rules in the `post` class, last. 

Default rules employ a numbering system in the resource's title that is used for ordering. When titling your default rules, make sure you prefix the rule with a number

      000 this runs first
      999 this runs last

Depending on the provider, the title of the rule can be stored using the comment feature of the underlying firewall subsystem. Values can match `/^\d+[[:alpha:][:digit:][:punct:][:space:]]+$/`.

####Examples of default rules

Basic accept ICMP request example:

    firewall { "000 accept all icmp requests":
      proto  => "icmp",
      action => "accept",
    }

Drop all:

    firewall { "999 drop all other requests":
      action => "drop",
    }

Source NAT example (perfect for a virtualization host):

    firewall { '100 snat for network foo2':
      chain    => 'POSTROUTING',
      jump     => 'MASQUERADE',
      proto    => 'all',
      outiface => "eth0",
      source   => '10.1.2.0/24',
      table    => 'nat',
    }

Creating a new rule that forwards to a chain, then adding a rule to this chain:

    firewall { '100 forward to MY_CHAIN':
      chain   => 'INPUT',
      jump    => 'MY_CHAIN',
    }
    # The namevar here is in the format chain_name:table:protocol
    firewallchain { 'MY_CHAIN:filter:IPv4':
      ensure  => present,
    }
    firewall { '100 my rule':
      chain   => 'MY_CHAIN',
      action  => 'accept',
      proto   => 'tcp',
      dport   => 5000,
    }

Additional rules for iptables and ip6tables can be found in the examples folder of the module. 

###Application-specific rules

Application-specific rules can live anywhere you declare the firewall resource. It is best to put your firewall rules close to the service that needs it, such as in the module that configures it. 

For example, this instance was taken from [PuppetDB](https://github.com/puppetlabs/puppetlabs-puppetdb/blob/master/manifests/server/firewall.pp#L40-L44)

    firewall { "${http_port} accept - puppetdb":
      port   => $http_port,
      proto  => 'tcp',
      action => 'accept',
    }

You can also apply firewall rules to specific nodes. Usually, you will want to put the firewall rule in another class and apply that class to a node. But you can apply a rule to a node

    node 'foo.bar.com' { 
      firewall { '111 open port 111': 
        dport => 111 } 
      }

###Parameters

The parameters available to any firewall rule are: 

#####`action`

The action to perform on a match. Valid values are 'accept' (the packet is accepted), 'reject' (the packet is rejected with a suitable ICMP response), or 'drop' (the packet is dropped).

If no value is specified it will simply match the rule but perform no action, unless you've provide a provider-specific parameter (such as `jump`). 

#####`burst`

The rate limiting burst value (per second) before limit checks apply. Values can match `/^\d+$/`.  Requires rate_limiting.

#####`chain`

Name of the chain to use. You can provide a user-based chain or use one of the built-ins

  * INPUT (default)
  * FORWARD
  * OUTPUT
  * PREROUTING
  * POSTROUTING

Values can match `/^[a-zA-Z0-9\-_]+$/`. Requires iptables.

#####`destination`
  
An array of destination addresses to match. 

      destination => '192.168.1.0/24'

The destination can also be an IPv6 address if your provider supports it.

#####`dport`

The destination port to match for this filter (if the protocol supports ports). Will accept a single element or an array.

For some firewall providers you can pass a range of ports in the format

      <start_number>-<ending_number>

For example

      1-1024

This would cover ports 1 to 1024.

#####`ensure`

Manages the state of the rule. Defaults to 'present'.

#####`gid`
  
GID or Group-owner matching rule.  Accepts a string argument only, as iptables does not accept multiple GID in a single statement. Requires owner.
 
#####`icmp`

The type of ICMP packet to match when matching packets. Requires icmp_match.

#####`iniface`

Input interface to filter on. Values can match `/^[a-zA-Z0-9\-_]+$/`. Requires interface_match.

#####`jump`

The value for the `iptables --jump` parameter. Normal values are

  * QUEUE
  * RETURN
  * DNAT
  * SNAT
  * LOG
  * MASQUERADE
  * REDIRECT

However, any valid chain name is allowed.

For the values ACCEPT, DROP and REJECT you must use the generic `action` parameter.  This is to enforce the use of generic parameters where possible for maximum cross-platform modeling.

Setting both the `accept` and `jump` parameters will cause an error, as only one of the options should be set.   Requires iptables.

#####`limit`

Rate limiting value for matched packets. The format is: `rate/[/second/|/minute|/hour|/day]`.

Example values are: '50/sec', '40/min', '30/hour', '10/day'."   Requires rate_limiting.

#####`log_level`

Combined with `jump => "LOG"`, specifies the system log level to log to. Requires log_level.

#####`log_prefix`

Combined with `jump => "LOG"`, specifies the log prefix to use when logging.   Requires log_prefix.

#####`outiface`

Output interface to filter on. Values can match `/^[a-zA-Z0-9\-_]+$/`. Requires interface_match.

#####`port`

The destination or source port to match for this filter (if the protocol supports ports). Will accept a single element or an array.

For some firewall providers you can pass a range of ports in the format

      <start_number>-<ending_number>

For example

      1-1024

This would cover ports 1 to 1024.

#####`proto`

The specific protocol to match for the rule. By default this is 'tcp'. Valid values are `tcp`, `udp`, `icmp`, `ipv6-icmp`, `esp`, `ah`, `vrrp`, `igmp`, `ipencap`, `all`.

#####`reject`

Combined with `jump => "REJECT"` allows you to specify a different ICMP response to be sent back to the packet sender. Requires reject_type.

#####`source`

An array of source addresses. 

      source => '192.168.2.0/24'

The source can also be an IPv6 address if your provider supports it.

#####`sport`

The source port to match for this filter (if the protocol supports ports). Will accept a single element or an array.

For some firewall providers you can pass a range of ports in the format

      <start_number>-<ending_number>

For example

      1-1024

This would cover ports 1 to 1024.

#####`state`

Matches a packet based on its state in the firewall stateful inspection table. Values can be

  * INVALID
  * ESTABLISHED
  * NEW
  * RELATED    
  
Requires state_match.

#####`table`

The table to use. Can be

  * nat
  * mangle
  * filter (default)
  * raw
  * rawpost

Requires iptables.

#####`todest`

Use this parameter when using `jump => "DNAT"` in order to specify the new destination address. Requires dnat.

#####`toports`

For DNAT, this is the port that will replace the destination port. Requires dnat.

#####`tosource`

Use this parameter when using `jump => "SNAT"` in order to specify the new source address. Requires snat.

#####`uid`
 
UID or Username-owner matching rule.  Accepts a string argument only, as iptables does not accept multiple UID in a single statement. Requires owner.

###Additional Information

You can access the inline documentation:

    puppet describe firewall

Or

    puppet doc -r type
    (and search for firewall)

##Implementation Reference

Classes:

* [firewall](#class:-firewall)
* [firewall::linux](#class:-firewalllinux)
* [firewall::linux::debian](#class:-firewalllinuxdebian)
* [firewall::linux::redhat](#class:-firewalllinuxredhat)

Providers:

* [firewall](#provider:-firewall)

Types:

* [ip6tables]()**TODO: is this right?**
* [firewall](#type:-firewall)
* [firewallchain](#type:-firewallchain)

Facts:

* [ip6tables_version](#fact:-ip6tablesversion)
* [iptables_persistent_version](#fact:-iptablespersistentversion)
* [iptables_version](#fact:-iptablesversion)




####Class: firewall

 Manages the installation of packages for operating systems that are currently supported by the firewall type.

####Class: firewall::linux

Manifests for managing the required packages and services on supported Linux
operating systems. These will be required for persistence.

####Type: firewall

This type provides the capability to manage firewall rules within
    puppet.

####Type:: firewallchain

This type provides the capability to manage rule chains for firewalls.

####Fact: ip6tables_version

The module provides a Facter fact that can be used to determine what the default version of ip6tables is for your operating system/distribution. 

####Fact: iptables_persistent_version


####Fact: iptables_version

he module provides a Facter fact that can be used to determine what the default version of ip6tables is for your operating system/distribution.    

**So there are native resource types: iptables and ip6tables, as well as corresponding Facter facts for each. I'm not sure how to present that here?**

##Limitations

Please note, we only aim support for the following distributions and versions

* Redhat 5.8 or greater
* Debian 6.0 or greater
* Ubuntu 11.04 or greater

If you want a new distribution supported feel free to raise a ticket and we'll
consider it. If you want an older revision supported we'll also consider it,
but don't get insulted if we reject it. Specifically, we will not consider
Redhat 4.x support - its just too old.

Also, as this is a 0.x release the API is still in flux and may change. Make sure
you read the release notes before upgrading.

Bugs can be reported using Github Issues:

<http://github.com/puppetlabs/puppetlabs-firewall/issues>

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide [on the Puppet Labs wiki.](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing)

For this particular module, please also read CONTRIBUTING.md before contributing.

Currently we support:

* iptables
* ip6tables
* ebtables (chains only)

But plans are to support lots of other firewall implementations:

* FreeBSD (ipf)
* Mac OS X (ipfw)
* OpenBSD (pf)
* Cisco (ASA and basic access lists)

If you have knowledge in these technologies, know how to code, and wish to contribute to this project, we would welcome the help.

###Testing

Make sure you have:

    rake

Install the necessary gems:

    gem install rspec

And run the tests from the root of the source code:

    rake test
