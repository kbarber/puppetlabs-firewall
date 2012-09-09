Running Acceptance Tests Using Vagrant
======================================

This section will describe the setup required to get acceptance testing
machines running using Vagrant and how to run the tests against them.

Get the images running
----------------------

This setup walks you through getting the images that we provide working in
Vagrant. If you wish to build your own images from scratch, consult the 
document 'vagrant_image_maintenance.markdown'.

### Prerequisites

My environment before I started:

*   Mac OS X 11.8.1
*   VirtualBox 4.1.22
*   git 1.7.11.3
*   rvm 1.14.10
    - ruby-1.8.7

### Grab the code

Change into your usual development directory, optionally creating one first:

    mkdir ~/Development
    cd ~/Development

Grab the firewall code:

    git clone git://github.com/puppetlabs/puppetlabs-firewall.git

### Bring up images

Enter 'vagrant' directory and use bundler to grab gems:

    cd puppetlabs-firewall/acceptance/vagrant
    bundle install

Now use vagrant to fire up the machines:

    vagrant up

At this point, if you don't already have our images they will be downloaded
from the internet and registered to Vagrant for you.

Prepare git
-----------

Run a git daemon on your own box if you like, this allows you to commit
locally and test before pushing up to github:

    git daemon --detach --export-all --base-path=~/Development

Running systest
---------------

Sample command to run:

    FW_HOME=~/Development/puppetlabs-firewall
    ./systest.rb \
      -c $FW_HOME/acceptance/vagrant/vagrant-systest-nodes.cfg \
      --type git \
      -p 2.7.x -f 1.6.x \
      --yagr git://10.0.2.2/puppetlabs-firewall \
      --helper $FW_HOME/acceptance/helper.rb \
      -t $FW_HOME/acceptance/tests

Running Acceptance Tests using other Virtual Solutions
======================================================

You can consult the [puppet-acceptance][1] documentation. It contains helpers
for at VMware and EC2.

Writing Acceptance Tests
========================

puppet-acceptance
-----------------

All tests are written using the [puppet-acceptance][1]
DSL, which is rspec or Test::Unit like in concept but is more aligned towards
system tests.

Tests are places inside the acceptance/tests directory in the relevant section.

The system accepts a number of switches as documented, and it also takes a
configuration file with general setup, and lists of hosts to include in its
tests. If multiple hosts are configured your tests can be written in a way
to test on all these systems.

DSL Helpers
-----------

Some helpers have been provided to wrap common functions when testing iptables.
Its best to look at the existing tests for examples to learn how to use these
for common cases.

If you like, the helpers are documented in acceptance/helper.rb. If you find
yourself repeating a task a lot, consider adding a method to the helper so
others can use it as well.

Reference
=========

  [1]: https://github.com/puppetlabs/puppet-acceptance "Puppet Acceptance README"

